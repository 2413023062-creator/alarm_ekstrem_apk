import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SmsService {
  static final Telephony _telephony = Telephony.instance;

  /// Meminta izin SMS
  static Future<bool> requestPermissions() async {
    try {
      bool? isGranted = await _telephony.requestPhoneAndSmsPermissions;
      return isGranted ?? false;
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Mengirim SMS Darurat tanpa interaksi UI (Silent Background SMS)
  static Future<bool> sendEmergencySms({String? customMessage}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString(AppConstants.keyEmergencyPhone);

      if (phoneNumber == null || phoneNumber.trim().isEmpty) {
        debugPrint('Nomor darurat belum dikonfigurasi!');
        return false;
      }

      final message = customMessage ??
          'Peringatan Darurat: Suci belum bangun lebih dari 5 menit sejak alarm menyala! Tolong hubungi dan bangunkan sekarang!';

      debugPrint('Mengirim SMS darurat ke: $phoneNumber');

      await _telephony.sendSms(
        to: phoneNumber.trim(),
        message: message,
        isMultipart: true,
      );

      debugPrint('SMS darurat berhasil terkirim ke $phoneNumber');
      return true;
    } catch (e) {
      debugPrint('Gagal mengirim SMS darurat: $e');
      return false;
    }
  }
}
