import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/alarm_service.dart';
import 'core/services/supabase_service.dart';
import 'features/alarm/screens/alarm_ring_screen.dart';
import 'features/alarm/screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Portrait agar stabil saat mata terbuka & kamera
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inisialisasi Layanan Alarm & Supabase
  await AlarmService.initialize();
  await SupabaseService.initialize();

  runApp(const AlarmEkstremApp());
}

class AlarmEkstremApp extends StatefulWidget {
  const AlarmEkstremApp({super.key});

  @override
  State<AlarmEkstremApp> createState() => _AlarmEkstremAppState();
}

class _AlarmEkstremAppState extends State<AlarmEkstremApp> {
  @override
  void initState() {
    super.initState();
    _listenToAlarmRinging();
  }

  void _listenToAlarmRinging() {
    // Dengarkan event ketika alarm mulai berdering (Full-Screen Intent)
    Alarm.ringStream.stream.listen((AlarmSettings alarmSettings) {
      debugPrint('Alarm dengan ID ${alarmSettings.id} mulai berdering!');
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(scheduledTime: alarmSettings.dateTime),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Alarm Ekstrem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1126),
        primaryColor: Colors.amber,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Color(0xFF1E2238),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
