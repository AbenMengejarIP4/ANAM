// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Anda perlu menambahkan paket provider
import 'mqtt_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MQTTService(),
      child: MaterialApp(
        title: 'ANAM Fire Detector',
        theme: ThemeData(
          primarySwatch: Colors.red,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Memulai koneksi MQTT saat widget dimuat
    final mqttService = Provider.of<MQTTService>(context, listen: false);
    mqttService.connect();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk secara otomatis membangun kembali UI saat data berubah
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANAM Fire Detector'),
      ),
      body: Consumer<MQTTService>(
        builder: (context, mqttService, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Status Koneksi:',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  mqttService.isConnected ? 'Terhubung' : 'Terputus',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: mqttService.isConnected ? Colors.green : Colors.red,
                      ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Nilai Sensor Kualitas Udara (MQ-135):',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${mqttService.mq135Value.toStringAsFixed(2)} ppm',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 20),
                Text(
                  'Nilai Sensor Asap/Gas (MQ-2):',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${mqttService.mq2Value.toStringAsFixed(2)} ppm',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}