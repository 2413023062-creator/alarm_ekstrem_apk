import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AlarmService {
  static const int defaultAlarmId = 42;

  /// Inisialisasi plugin alarm
  static Future<void> initialize() async {
    await Alarm.init();
  }

  /// Pasang alarm baru
  static Future<bool> scheduleAlarm({
    required DateTime dateTime,
    int id = defaultAlarmId,
    String? audioPath,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioPath ?? 'assets/sounds/extreme_alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 1.0, // Volume 100%
      fadeDuration: 0.0, // Tanpa fade-in, langsung kencang
      warningNotificationOnKill: true,
      androidFullScreenIntent: true, // Tampilkan di atas lock screen
      notificationSettings: const NotificationSettings(
        title: 'ALARM EKSTREM BERBUNYI!',
        body: 'Selesaikan misi Matematika dan Scan Wajah untuk mematikan alarm!',
        stopButton: null, // Tanpa tombol Stop di notifikasi!
        icon: 'notification_icon',
      ),
    );

    final success = await Alarm.set(alarmSettings: alarmSettings);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAlarmTime, dateTime.toIso8601String());
      debugPrint('Alarm berhasil dipasang untuk: $dateTime');
    }
    return success;
  }

  /// Tandai alarm sedang berdering (untuk trap anti-reboot)
  static Future<void> setRingingStatus(bool isRinging) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsAlarmRinging, isRinging);
  }

  /// Matikan alarm secara resmi
  static Future<void> stopAlarm({int id = defaultAlarmId}) async {
    await Alarm.stop(id);
    await setRingingStatus(false);
    debugPrint('Alarm id $id resmi dihentikan.');
  }

  /// Periksa apakah ada alarm yang sedang aktif
  static bool hasActiveAlarm({int id = defaultAlarmId}) {
    return Alarm.hasAlarm();
  }
}
