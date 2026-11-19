import 'dart:math';
import 'package:flutter/material.dart';

class MathMissionView extends StatefulWidget {
  final int totalQuestions;
  final VoidCallback onCompleted;

  const MathMissionView({
    super.key,
    this.totalQuestions = 2,
    required this.onCompleted,
  });

  @override
  State<MathMissionView> createState() => _MathMissionViewState();
}

class _MathMissionViewState extends State<MathMissionView> {
  final Random _random = Random();
  late int _currentQuestionIndex;
  late int _num1;
  late int _num2;
  String _userAnswer = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentQuestionIndex = 1;
    _generateProblem();
  }

  void _generateProblem() {
    // Penjumlahan 2 digit acak yang menstimulasi otak bangun tidur
    _num1 = 15 + _random.nextInt(75); // Antara 15 - 89
    _num2 = 12 + _random.nextInt(78); // Antara 12 - 89
    _userAnswer = '';
    _errorMessage = null;
  }

  void _onKeyPress(String val) {
    if (_userAnswer.length < 5) {
      setState(() {
        _userAnswer += val;
        _errorMessage = null;
      });
    }
  }

  void _onBackspace() {
    if (_userAnswer.isNotEmpty) {
      setState(() {
        _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onSubmit() {
    final int? answer = int.tryParse(_userAnswer);
    final int correctAnswer = _num1 + _num2;

    if (answer == correctAnswer) {
      if (_currentQuestionIndex < widget.totalQuestions) {
        setState(() {
          _currentQuestionIndex++;
          _generateProblem();
        });
      } else {
        // Semua soal matematika berhasil dijawab!
        widget.onCompleted();
      }
    } else {
      setState(() {
        _errorMessage = 'Jawaban Salah! Coba lagi.';
        _userAnswer = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header Misi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade900.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Text(
              'MISI 1: MATEMATIKA ($_currentQuestionIndex/${widget.totalQuestions})',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Soal Matematika
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2238),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Text(
                  '$_num1 + $_num2 = ?',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 220,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1126),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _errorMessage != null ? Colors.redAccent : Colors.amber,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _userAnswer.isEmpty ? '?' : _userAnswer,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _userAnswer.isEmpty ? Colors.white30 : Colors.amberAccent,
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Keypad Custom di Layar
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeyButton('⌫', onPressed: _onBackspace, isAction: true),
            const SizedBox(width: 12),
            _buildKeyButton('0', onPressed: () => _onKeyPress('0')),
            const SizedBox(width: 12),
            _buildKeyButton('OK', onPressed: _onSubmit, isAction: true, isOk: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildKeyButton(key, onPressed: () => _onKeyPress(key)),
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton(String label, {required VoidCallback onPressed, bool isAction = false, bool isOk = false}) {
    return SizedBox(
      width: 76,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isOk
              ? Colors.amber
              : isAction
                  ? const Color(0xFF2C3060)
                  : const Color(0xFF1E2238),
          foregroundColor: isOk ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isOk ? Colors.amberAccent : Colors.white12,
            ),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 20 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
