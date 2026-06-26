// ====================================
// Rekap Screen — Rekap Bulanan
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/models/presensi_log.dart';
import '../../../services/auth_service.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
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
      final logs = await PresensiDao.getByMonth(
        pegawai?.id ?? '',
        _selectedYear,
        _selectedMonth,
      );
      if (mounted) setState(() => _logs = logs);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadData();
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

    // Group logs by tanggal
    final grouped = <String, List<PresensiLog>>{};
    for (final log in _logs) {
      grouped.putIfAbsent(log.tanggal, () => []).add(log);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    // Count stats
    final masukCount =
        _logs.where((l) => l.tipe == TipePresensi.masuk).length;
    final pulangCount =
        _logs.where((l) => l.tipe == TipePresensi.pulang).length;
    final wfaCount = _logs.where((l) => l.isLuarRadius > 0).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Rekap Presensi',
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Month Selector ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: Icon(Icons.chevron_left, color: textColor),
                ),
                Text(
                  '${months[_selectedMonth - 1]} $_selectedYear',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: Icon(Icons.chevron_right, color: textColor),
                ),
              ],
            ),
          ),

          // ── Stats Cards ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(
                  label: 'Hari Masuk',
                  value: masukCount.toString(),
                  color: AppColors.absenMasuk,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Hari Pulang',
                  value: pulangCount.toString(),
                  color: AppColors.absenPulang,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'WFA',
                  value: wfaCount.toString(),
                  color: AppColors.warning,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── List ────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : sortedDates.isEmpty
                    ? Center(
                        child: Text('Belum ada data',
                            style: TextStyle(color: subtextColor)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final dayLogs = grouped[date]!;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(date,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textColor)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: dayLogs.map((log) {
                                    return Chip(
                                      label: Text(
                                        log.tipe.displayLabel,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: _getTypeColor(log.tipe)
                                          .withValues(alpha: 0.15),
                                      side: BorderSide.none,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: textColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
