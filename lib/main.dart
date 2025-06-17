import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'firebase_options.dart'; // Dihapus, tidak diperlukan untuk Android saja
import 'mqtt_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inisialisasi tanpa options untuk Android/iOS
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Panggil initializeApp tanpa options.
  // Ini akan secara otomatis menggunakan file google-services.json di Android.
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
          primarySwatch: Colors.deepOrange,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          // FIX: Menggunakan CardThemeData, bukan CardTheme
          cardTheme: const CardThemeData( 
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          textTheme: const TextTheme(
            headlineSmall:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            titleLarge: TextStyle(fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(fontSize: 16),
          ),
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
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    final mqttService = Provider.of<MQTTService>(context, listen: false);
    mqttService.connect();
  }

  void _setupNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print("====================================================");
    print("FCM Token: $fcmToken");
    print("====================================================");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted && message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${message.notification?.title}\n${message.notification?.body}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANAM Fire Detector'),
        backgroundColor: Colors.red,
      ),
      body: Consumer<MQTTService>(
        builder: (context, mqtt, child) {
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: <Widget>[
              _buildStatusCard(mqtt),
              _buildSensorCard('Sensor Asap & Gas (MQ-2)', mqtt.mq2Value, 'ppm'),
              _buildSensorCard(
                  'Sensor Kualitas Udara (MQ-135)', mqtt.mq135Value, 'ppm'),
              _buildInfoCard(mqtt),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(MQTTService mqtt) {
    bool isDanger = mqtt.status.contains("BAHAYA") ||
        mqtt.status.contains("ASAP") ||
        mqtt.status.contains("GAS");
    Color statusColor = isDanger ? Colors.redAccent : Colors.green;
    IconData statusIcon =
        isDanger ? Icons.local_fire_department : Icons.check_circle;

    return Card(
      color: statusColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Status Ruangan: ${mqtt.currentRoom}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Icon(statusIcon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              mqtt.status,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, double value, String unit) {
    return Card(
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        trailing: Text(
          '${value.toStringAsFixed(2)} $unit',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
        ),
      ),
    );
  }

  Widget _buildInfoCard(MQTTService mqtt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Monitoring',
                style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            _infoRow('Status Koneksi MQTT:',
                mqtt.isConnected ? 'Terhubung' : 'Terputus',
                mqtt.isConnected ? Colors.green : Colors.grey),
            _infoRow('Mode Sampling:', mqtt.samplingMode),
            if (mqtt.samplingMode == 'ADAPTIVE')
              _infoRow('Adaptive Count:', mqtt.adaptiveCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
