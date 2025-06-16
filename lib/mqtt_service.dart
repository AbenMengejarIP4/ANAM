// lib/mqtt_service.dart
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService with ChangeNotifier {
  MqttServerClient? _client;
  double _mq135Value = 0.0;
  double _mq2Value = 0.0;
  bool _isConnected = false;

  // Getters untuk UI
  double get mq135Value => _mq135Value;
  double get mq2Value => _mq2Value;
  bool get isConnected => _isConnected;

  void connect() async {
    // Ganti dengan detail broker HiveMQ Anda
    _client = MqttServerClient('your_broker_address.s1.eu.hivemq.cloud', 'your_unique_client_id');
    _client!.port = 8883; // Gunakan 8883 untuk koneksi aman (TLS)
    _client!.secure = true;
    _client!.logging(on: true);
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.pongCallback = _pong;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('your_unique_client_id')
        .startClean() // Sesi bersih
        .withWillQos(MqttQos.atLeastOnce);
    
    // Ganti dengan username dan password HiveMQ Anda
    connMessage.authenticateAs('your_username', 'your_password');
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      print('Exception: $e');
      _disconnect();
    }

    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      
      print('Received message: $payload from topic: ${c[0].topic}');

      // Asumsikan topik Anda adalah 'sensors/mq135' dan 'sensors/mq2'
      // dan payload-nya adalah nilai numerik.
      if (c[0].topic == 'sensors/mq135') {
        _mq135Value = double.tryParse(payload) ?? 0.0;
      } else if (c[0].topic == 'sensors/mq2') {
        _mq2Value = double.tryParse(payload) ?? 0.0;
        // Cek ambang batas untuk notifikasi
        _checkFireHazard(_mq2Value);
      }
      
      notifyListeners(); // Memberi tahu UI untuk update
    });
  }

  void _onConnected() {
    _isConnected = true;
    print('Connected to MQTT Broker!');
    // Langganan ke topik sensor Anda
    _client!.subscribe('sensors/mq135', MqttQos.atLeastOnce);
    _client!.subscribe('sensors/mq2', MqttQos.atLeastOnce);
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

  void _checkFireHazard(double mq2Value) {
    // Tentukan ambang batas bahaya kebakaran Anda di sini
    const fireThreshold = 300.0; 
    if (mq2Value > fireThreshold) {
      print('FIRE HAZARD DETECTED! MQ-2 value: $mq2Value');
      // Di sini kita akan memicu logika pengiriman notifikasi
      // (Lihat Bagian 2)
    }
  }
}