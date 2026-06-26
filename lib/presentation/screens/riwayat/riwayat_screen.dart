// ====================================
// Riwayat Screen — Riwayat Presensi
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/status.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/local/presensi_dao.dart';
import '../../../data/models/presensi_log.dart';
import '../../../services/auth_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<PresensiLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final pegawai = await AuthService.getPegawai();
      final now = DateTime.now();
      final logs = await PresensiDao.getByMonth(
        pegawai?.id ?? '',
        now.year,
        now.month,
      );
      if (mounted) setState(() => _logs = logs);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);
    final cardBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Riwayat Presensi',
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _logs.isEmpty
                  ? Center(
                      child: Text('Belum ada riwayat presensi',
                          style: TextStyle(color: subtextColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getTypeColor(log.tipe)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(_getTypeEmoji(log.tipe),
                                      style: const TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.tipe.displayLabel,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: textColor)),
                                    Text(log.tanggal,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: subtextColor)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    date_utils.formatTime(
                                        DateTime.parse(log.waktu)),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: log.isSynced
                                          ? AppColors.success
                                              .withValues(alpha: 0.15)
                                          : AppColors.warning
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.isSynced ? 'Synced' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: log.isSynced
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
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

  Color _getTypeColor(TipePresensi tipe) {
    switch (tipe) {
      case TipePresensi.masuk:
        return AppColors.absenMasuk;
      case TipePresensi.mulaiIstirahat:
        return AppColors.absenIstirahatMulai;
      case TipePresensi.selesaiIstirahat:
        return AppColors.absenIstirahatSelesai;
      case TipePresensi.pulang:
        return AppColors.absenPulang;
    }
  }

  String _getTypeEmoji(TipePresensi tipe) {
    switch (tipe) {
      case TipePresensi.masuk:
        return '🟢';
      case TipePresensi.mulaiIstirahat:
        return '☕';
      case TipePresensi.selesaiIstirahat:
        return '🏃';
      case TipePresensi.pulang:
        return '🔴';
    }
  }
}
