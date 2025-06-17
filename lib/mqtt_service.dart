import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService with ChangeNotifier {
  MqttServerClient? _client;
  bool _isConnected = false;

  // Variabel baru untuk menampung data dari JSON
  String _currentRoom = "Menunggu Data...";
  double _mq2Value = 0.0;
  double _mq135Value = 0.0;
  String _status = "Menunggu Data...";
  String _samplingMode = "-";
  int _adaptiveCount = 0;

  // Getters untuk UI
  bool get isConnected => _isConnected;
  String get currentRoom => _currentRoom;
  double get mq2Value => _mq2Value;
  double get mq135Value => _mq135Value;
  String get status => _status;
  String get samplingMode => _samplingMode;
  int get adaptiveCount => _adaptiveCount;


  void connect() async {
    // Kredensial dari kode ESP32 Anda
    _client = MqttServerClient('fbd1ae6f7fe343968715863d134cedbc.s1.eu.hivemq.cloud', 'flutter-anam-app-${DateTime.now().millisecondsSinceEpoch}');
    _client!.port = 8883;
    _client!.secure = true;
    _client!.logging(on: true);
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;
    
    // [FIX] Menggunakan metode yang benar untuk mengabaikan error sertifikat
    _client!.onBadCertificate = (dynamic certificate) => true;


    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter-anam-app-${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    // Username & Password dari kode ESP32 Anda
    connMessage.authenticateAs('michaeldimas28', 'Mike.285');
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print('Exception: $e');
      _disconnect();
    }

    // Listener untuk pesan masuk
    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      
      print('Received JSON: $payload');

      // Parsing data JSON
      try {
        final jsonData = jsonDecode(payload) as Map<String, dynamic>;
        _currentRoom = jsonData['room'] ?? 'N/A';
        _mq2Value = (jsonData['mq2_avg'] as num?)?.toDouble() ?? 0.0;
        _mq135Value = (jsonData['mq135_avg'] as num?)?.toDouble() ?? 0.0;
        _status = jsonData['status'] ?? 'N/A';
        _samplingMode = jsonData['sampling_mode'] ?? '-';
        _adaptiveCount = (jsonData['adaptive_count'] as num?)?.toInt() ?? 0;

        // Cek status untuk notifikasi
        _checkFireHazard(_status);

        notifyListeners(); // Memberi tahu UI untuk update
      } catch(e) {
        print("Gagal parsing JSON: $e");
      }
    });
  }

  void _onConnected() {
    _isConnected = true;
    print('Connected to MQTT Broker!');
    // Langganan ke topik yang sama dengan yang di-publish oleh ESP32
    _client!.subscribe('iot/robot/sensordata', MqttQos.atLeastOnce);
    notifyListeners();
  }

  void _onDisconnected() {
    _isConnected = false;
    print('Disconnected from MQTT Broker');
    notifyListeners();
  }
  
  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void _disconnect() {
    _client?.disconnect();
    _onDisconnected();
  }

  void _checkFireHazard(String status) {
    // Logika notifikasi sekarang berdasarkan status dari ESP32
    // Ini lebih andal karena keputusan dibuat di perangkat keras
    if (status.contains("BAHAYA") || status.contains("ASAP") || status.contains("GAS")) {
      print('FIRE HAZARD DETECTED! Status from ESP32: $status');
      // Di sinilah backend Anda akan dipicu untuk mengirim notifikasi FCM.
      // Untuk sekarang, kita hanya akan mencetak ke log.
    }
  }
}
