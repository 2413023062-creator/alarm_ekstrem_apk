import 'package:flutter/material.dart';
import 'math_mission_view.dart';

class EmergencyOverrideView extends StatelessWidget {
  final VoidCallback onCompleted;
  final VoidCallback onCancel;

  const EmergencyOverrideView({
    super.key,
    required this.onCompleted,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1118),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Text(
                  'EMERGENCY OVERRIDE (3 SOAL TAMBAHAN)',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Kamera bermasalah? Anda wajib menyelesaikan 3 soal matematika tambahan berikut untuk mematikan alarm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: MathMissionView(
              totalQuestions: 3,
              onCompleted: onCompleted,
            ),
          ),
        ],
      ),
    );
  }
}
