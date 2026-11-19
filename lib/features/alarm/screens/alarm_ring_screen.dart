import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/alarm_service.dart';
import '../../../core/services/sms_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../missions/emergency_override_view.dart';
import '../../missions/face_mission_view.dart';
import '../../missions/math_mission_view.dart';

enum RingPhase { math, faceScan, emergencyOverride }

class AlarmRingScreen extends StatefulWidget {
  final DateTime scheduledTime;

  const AlarmRingScreen({
    super.key,
    required this.scheduledTime,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  RingPhase _currentPhase = RingPhase.math;
  late final DateTime _ringStartTime;
  int _elapsedSeconds = 0;
  bool _emergencySmsSent = false;
  Timer? _stopwatchTimer;

  int _mathSolvedCount = 0;
  bool _isOverrideUsed = false;

  @override
  void initState() {
    super.initState();
    _ringStartTime = DateTime.now();
    AlarmService.setRingingStatus(true);
    _startStopwatch();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds++;
      });

      // Cek apakah mencapai 5 menit (300 detik) dan SMS belum terkirim
      if (_elapsedSeconds >= AppConstants.emergencyTimeoutSeconds && !_emergencySmsSent) {
        _triggerEmergencySms();
      }
    });
  }

  Future<void> _triggerEmergencySms() async {
    _emergencySmsSent = true;
    setState(() {});
    debugPrint('Batas 5 menit tercapai! Mengirim SMS darurat otomatis...');
    await SmsService.sendEmergencySms();
  }

  void _onMathMissionCompleted() {
    setState(() {
      _mathSolvedCount += 2;
      _currentPhase = RingPhase.faceScan;
    });
  }

  void _onFaceMissionCompleted() {
    _finishAlarm(status: 'success');
  }

  void _onEmergencyOverrideCompleted() {
    setState(() {
      _isOverrideUsed = true;
      _mathSolvedCount += 3;
    });
    _finishAlarm(status: 'override_used');
  }

  Future<void> _finishAlarm({required String status}) async {
    _stopwatchTimer?.cancel();

    // Hentikan suara alarm
    await AlarmService.stopAlarm();

    // Catat log ke Supabase / Offline queue
    await SupabaseService.logAlarmSession(
      scheduledTime: widget.scheduledTime,
      triggeredAt: _ringStartTime,
      dismissedAt: DateTime.now(),
      status: _emergencySmsSent ? 'emergency_triggered' : status,
      mathSolvedCount: _mathSolvedCount,
      totalRingingSeconds: _elapsedSeconds,
      emergencySmsSent: _emergencySmsSent,
    );

    if (!mounted) return;

    // Tampilkan dialog selamat bangun lalu kembali ke Home
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2238),
        title: const Text('🎉 SELAMAT PAGI!', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Alarm berhasil dimatikan dalam ${(_elapsedSeconds / 60).floor()} menit ${_elapsedSeconds % 60} detik.\n\nRiwayat bangun Anda telah tercatat.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('MULAI HARI INI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int remainingToSms = (AppConstants.emergencyTimeoutSeconds - _elapsedSeconds).clamp(0, AppConstants.emergencyTimeoutSeconds);
    final String minutes = (remainingToSms ~/ 60).toString().padLeft(2, '0');
    final String seconds = (remainingToSms % 60).toString().padLeft(2, '0');

    // PopScope false agar tombol Back HP tidak bisa menutup alarm!
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1126),
        body: SafeArea(
          child: Column(
            children: [
              // Header Waktu Berdering & Indikator SMS Darurat
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: _emergencySmsSent ? Colors.red.shade900 : const Color(0xFF16193A),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('HH:mm:ss').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Berdering: ${_elapsedSeconds}s',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _emergencySmsSent ? 'SMS TERKIRIM!' : 'Waktu Darurat SMS:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _emergencySmsSent ? Colors.white : Colors.amberAccent,
                          ),
                        ),
                        Text(
                          _emergencySmsSent ? 'Teman Dihubungi' : '$minutes:$seconds',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _emergencySmsSent ? Colors.white : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_emergencySmsSent)
                Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    '⚠️ Sudah lebih dari 5 menit! Pesan darurat telah dikirim ke teman Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),

              // Konten Misi yang Sedang Aktif
              Expanded(
                child: _buildCurrentPhaseView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhaseView() {
    switch (_currentPhase) {
      case RingPhase.math:
        return MathMissionView(
          totalQuestions: 2,
          onCompleted: _onMathMissionCompleted,
        );
      case RingPhase.faceScan:
        return FaceMissionView(
          onCompleted: _onFaceMissionCompleted,
          onEmergencyOverride: () {
            setState(() {
              _currentPhase = RingPhase.emergencyOverride;
            });
          },
        );
      case RingPhase.emergencyOverride:
        return EmergencyOverrideView(
          onCompleted: _onEmergencyOverrideCompleted,
          onCancel: () {
            setState(() {
              _currentPhase = RingPhase.faceScan;
            });
          },
        );
    }
  }
}
