import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyLogs = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await SupabaseService.syncPendingLogs();
    final logs = await SupabaseService.fetchHistory();
    setState(() {
      _historyLogs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1126),
      appBar: AppBar(
        title: const Text('RIWAYAT BANGUN TIDUR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF16193A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : _historyLogs.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada riwayat alarm.\nJalankan alarm untuk mencatat!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historyLogs.length,
                    itemBuilder: (context, index) {
                      final log = _historyLogs[index];
                      final status = log['status'] ?? 'success';
                      final isPending = log['is_local_pending'] == true;
                      final smsSent = log['emergency_sms_sent'] == true;
                      final totalSeconds = log['total_ringing_seconds'] ?? 0;
                      final createdAt = log['created_at'] != null
                          ? DateTime.tryParse(log['created_at'])
                          : null;

                      Color statusColor = Colors.greenAccent;
                      String statusText = 'Bangun Sukses';
                      if (status == 'emergency_triggered' || smsSent) {
                        statusColor = Colors.redAccent;
                        statusText = 'Darurat (SMS Teman)';
                      } else if (status == 'override_used') {
                        statusColor = Colors.orangeAccent;
                        statusText = 'Emergency Override';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2238),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      status == 'success'
                                          ? Icons.check_circle_outline
                                          : Icons.warning_amber_rounded,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Antrean Offline',
                                      style: TextStyle(color: Colors.white60, fontSize: 10),
                                    ),
                                  )
                                else
                                  const Text(
                                    'Synced Supabase',
                                    style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              createdAt != null
                                  ? DateFormat('EEEE, d MMM yyyy - HH:mm').format(createdAt.toLocal())
                                  : '-',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'Lama Berdering: ${totalSeconds}s',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Soal Dijawab: ${log['math_solved_count'] ?? 0}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
