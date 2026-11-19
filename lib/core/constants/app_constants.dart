class AppConstants {
  // SharedPreferences Keys
  static const String keyDeviceId = 'device_id';
  static const String keyEmergencyPhone = 'emergency_phone';
  static const String keyIsAlarmRinging = 'is_alarm_ringing';
  static const String keyPendingSyncLogs = 'pending_sync_logs';
  static const String keySupabaseUrl = 'supabase_url';
  static const String keySupabaseAnonKey = 'supabase_anon_key';
  static const String keyAlarmTime = 'alarm_time_saved';

  // Kredensial Supabase dari Environment (--dart-define) atau Fallback
  static const String envSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String envSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Default Supabase Placeholders (Dapat diisi melalui pengaturan aplikasi)
  static const String defaultSupabaseUrl = envSupabaseUrl.isNotEmpty
      ? envSupabaseUrl
      : 'https://YOUR_PROJECT_ID.supabase.co';
  static const String defaultSupabaseAnonKey = envSupabaseAnonKey.isNotEmpty
      ? envSupabaseAnonKey
      : 'YOUR_ANON_KEY';

  // Konfigurasi Durasi
  static const int emergencyTimeoutSeconds = 300; // 5 menit
  static const int faceHoldSeconds = 3; // Wajib melek 3 detik stabil

  // Database Supabase Table Name
  static const String tableAlarmLogs = 'alarm_logs';
}
