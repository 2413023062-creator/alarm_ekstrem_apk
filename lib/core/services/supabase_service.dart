import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'device_service.dart';

class SupabaseService {
  static bool isInitialized = false;

  /// Inisialisasi Supabase client dengan fallback aman jika belum diatur
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(AppConstants.keySupabaseUrl);
      final savedKey = prefs.getString(AppConstants.keySupabaseAnonKey);
      final url = (savedUrl != null && savedUrl.trim().isNotEmpty) ? savedUrl.trim() : AppConstants.defaultSupabaseUrl;
      final anonKey = (savedKey != null && savedKey.trim().isNotEmpty) ? savedKey.trim() : AppConstants.defaultSupabaseAnonKey;

      if (url.startsWith('http') && !url.contains('YOUR_PROJECT_ID')) {
        await Supabase.initialize(url: url, anonKey: anonKey);
        isInitialized = true;
        debugPrint('Supabase berhasil diinisialisasi.');
        // Coba sinkronisasi antrean tertunda jika terhubung internet
        syncPendingLogs();
      } else {
        debugPrint('Supabase belum dikonfigurasi dengan URL resmi. Mode offline lokal aktif.');
      }
    } catch (e) {
      debugPrint('Error init Supabase: $e');
    }
  }

  /// Catat riwayat alarm ke database (dengan fallback antrean lokal jika offline)
  static Future<void> logAlarmSession({
    required DateTime scheduledTime,
    required DateTime triggeredAt,
    DateTime? dismissedAt,
    required String status, // 'success', 'emergency_triggered', 'override_used'
    int mathSolvedCount = 0,
    int faceScanDurationSeconds = 0,
    required int totalRingingSeconds,
    bool emergencySmsSent = false,
  }) async {
    final deviceId = await DeviceService.getOrCreateDeviceId();

    final logData = {
      'device_id': deviceId,
      'alarm_scheduled_time': scheduledTime.toUtc().toIso8601String(),
      'alarm_triggered_at': triggeredAt.toUtc().toIso8601String(),
      'dismissed_at': dismissedAt?.toUtc().toIso8601String(),
      'status': status,
      'math_solved_count': mathSolvedCount,
      'face_scan_duration_seconds': faceScanDurationSeconds,
      'total_ringing_seconds': totalRingingSeconds,
      'emergency_sms_sent': emergencySmsSent,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    // Cek koneksi internet
    final connectivity = await Connectivity().checkConnectivity();
    final bool hasInternet = !connectivity.contains(ConnectivityResult.none);

    if (isInitialized && hasInternet) {
      try {
        await Supabase.instance.client.from(AppConstants.tableAlarmLogs).insert(logData);
        debugPrint('Log alarm berhasil di-sync langsung ke Supabase.');
        return;
      } catch (e) {
        debugPrint('Gagal kirim ke Supabase, masuk antrean lokal: $e');
      }
    }

    // Jika offline atau gagal, simpan ke antrean lokal (SharedPreferences)
    await _queueLogLocally(logData);
  }

  /// Simpan antrean lokal
  static Future<void> _queueLogLocally(Map<String, dynamic> logData) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(AppConstants.keyPendingSyncLogs) ?? [];
    queue.add(jsonEncode(logData));
    await prefs.setStringList(AppConstants.keyPendingSyncLogs, queue);
    debugPrint('Log alarm disimpan ke antrean offline lokal. Total pending: ${queue.length}');
  }

  /// Sinkronkan antrean log lokal ke Supabase
  static Future<void> syncPendingLogs() async {
    if (!isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(AppConstants.keyPendingSyncLogs) ?? [];
    if (queue.isEmpty) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    debugPrint('Mencoba sinkronisasi ${queue.length} log tertunda ke Supabase...');
    final List<String> remaining = [];

    for (final item in queue) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        await Supabase.instance.client.from(AppConstants.tableAlarmLogs).insert(data);
      } catch (e) {
        debugPrint('Gagal sync salah satu log: $e');
        remaining.add(item);
      }
    }

    await prefs.setStringList(AppConstants.keyPendingSyncLogs, remaining);
    debugPrint('Sinkronisasi selesai. Sisa pending: ${remaining.length}');
  }

  /// Ambil riwayat log (lokal + remote)
  static Future<List<Map<String, dynamic>>> fetchHistory() async {
    List<Map<String, dynamic>> results = [];

    // Ambil dari Supabase jika online
    if (isInitialized) {
      try {
        final deviceId = await DeviceService.getOrCreateDeviceId();
        final response = await Supabase.instance.client
            .from(AppConstants.tableAlarmLogs)
            .select()
            .eq('device_id', deviceId)
            .order('created_at', ascending: false)
            .limit(30);
        results.addAll(List<Map<String, dynamic>>.from(response));
      } catch (e) {
        debugPrint('Gagal fetch dari Supabase: $e');
      }
    }

    // Gabungkan dengan yang masih ada di antrean lokal
    final prefs = await SharedPreferences.getInstance();
    final List<String> localQueue = prefs.getStringList(AppConstants.keyPendingSyncLogs) ?? [];
    for (final item in localQueue) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      decoded['is_local_pending'] = true;
      results.insert(0, decoded);
    }

    return results;
  }
}
