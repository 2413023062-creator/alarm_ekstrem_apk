import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../history/history_screen.dart';
import 'alarm_ring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 5, minute: 0);
  DateTime? _activeAlarmTime;
  String _emergencyPhoneNumber = '';
  String _deviceId = '';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = await DeviceService.getOrCreateDeviceId();
    _emergencyPhoneNumber = prefs.getString(AppConstants.keyEmergencyPhone) ?? '';
    _phoneController.text = _emergencyPhoneNumber;

    final savedAlarm = prefs.getString(AppConstants.keyAlarmTime);
    if (savedAlarm != null) {
      final parsed = DateTime.tryParse(savedAlarm);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        _activeAlarmTime = parsed;
        _selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
    }

    _supabaseUrlController.text = prefs.getString(AppConstants.keySupabaseUrl) ?? '';
    _supabaseKeyController.text = prefs.getString(AppConstants.keySupabaseAnonKey) ?? '';

    setState(() {});
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _calculateNextAlarmDateTime(TimeOfDay time) {
    final now = DateTime.now();
    DateTime alarmDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (alarmDate.isBefore(now)) {
      alarmDate = alarmDate.add(const Duration(days: 1));
    }
    return alarmDate;
  }

  Future<void> _saveAndScheduleAlarm() async {
    final targetDateTime = _calculateNextAlarmDateTime(_selectedTime);

    // Minta izin SMS & Notifikasi
    await SmsService.requestPermissions();

    final success = await AlarmService.scheduleAlarm(dateTime: targetDateTime);
    if (success) {
      setState(() {
        _activeAlarmTime = targetDateTime;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Alarm berhasil disetel untuk ${DateFormat('EEEE, HH:mm', 'id_ID').format(targetDateTime)}!'),
          ),
        );
      }
    }
  }

  Future<void> _cancelAlarm() async {
    await AlarmService.stopAlarm();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAlarmTime);
    setState(() {
      _activeAlarmTime = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm dinonaktifkan.')),
      );
    }
  }

  Future<void> _saveEmergencyPhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyEmergencyPhone, _phoneController.text.trim());
    setState(() {
      _emergencyPhoneNumber = _phoneController.text.trim();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor darurat teman berhasil disimpan!')),
      );
    }
  }

  void _showSupabaseConfigDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2238),
        title: const Text('Konfigurasi Supabase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _supabaseUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Project URL',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'https://xyz.supabase.co',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _supabaseKeyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Anon Public Key',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'eyJh...',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(AppConstants.keySupabaseUrl, _supabaseUrlController.text.trim());
              await prefs.setString(AppConstants.keySupabaseAnonKey, _supabaseKeyController.text.trim());
              await SupabaseService.initialize();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kredensial Supabase berhasil disimpan!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _triggerTestRingScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlarmRingScreen(scheduledTime: DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1126),
      appBar: AppBar(
        title: const Text(
          'ALARM EKSTREM',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.amberAccent),
        ),
        backgroundColor: const Color(0xFF16193A),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: 'Pengaturan Supabase',
            onPressed: _showSupabaseConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Riwayat Bangun',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Alarm Aktif Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _activeAlarmTime != null
                      ? [const Color(0xFF1E2238), const Color(0xFF2C3060)]
                      : [const Color(0xFF16193A), const Color(0xFF12142B)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _activeAlarmTime != null ? Colors.amberAccent : Colors.white12,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _activeAlarmTime != null ? 'ALARM AKTIF' : 'ALARM NONAKTIF',
                    style: TextStyle(
                      color: _activeAlarmTime != null ? Colors.amberAccent : Colors.white38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Text(
                    _activeAlarmTime != null
                        ? 'Berdering pada ${DateFormat('EEEE, d MMM yyyy - HH:mm').format(_activeAlarmTime!)}'
                        : 'Sentuh angka jam untuk mengubah waktu',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _saveAndScheduleAlarm,
                          icon: const Icon(Icons.alarm_on, size: 20),
                          label: const Text('AKTIFKAN ALARM', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (_activeAlarmTime != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _cancelAlarm,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Kontak Darurat Teman
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2238),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.contact_phone, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Nomor Teman (Darurat SMS)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Jika alarm berdering > 5 menit tanpa dimatikan, aplikasi otomatis mengirim SMS ke nomor ini.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: const Color(0xFF0F1126),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _saveEmergencyPhone,
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Fitur Pengujian Langsung (Debug & Trial)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16193A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uji Coba Cepat (Test Mode)',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amberAccent,
                      side: const BorderSide(color: Colors.amberAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _triggerTestRingScreen,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Simulasi Layar Alarm Berdering Sekarang'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                      side: const BorderSide(color: Colors.lightBlueAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final ok = await SmsService.sendEmergencySms(customMessage: 'Tes SMS Alarm Ekstrem dari HP Suci.');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'SMS tes berhasil dikirim!' : 'Gagal mengirim SMS tes.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Tes Kirim 1x SMS ke Nomor Teman'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info Identitas Perangkat
            Center(
              child: Text(
                'Device ID: $_deviceId',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
