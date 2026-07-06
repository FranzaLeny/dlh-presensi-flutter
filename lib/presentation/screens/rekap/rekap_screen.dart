// ====================================
// Rekap Screen — Rekap Bulanan
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/models/presensi_log.dart';
import '../../../services/auth_service.dart';
import 'widgets/rekap_calendar_grid.dart';
import 'widgets/rekap_detail_card.dart';
import 'widgets/rekap_month_selector.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  State<RekapScreen> createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _selectedDate; // Format: YYYY-MM-DD
  List<PresensiLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Default select hari ini jika bulannya sama
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      _selectedDate =
          '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
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
      if (mounted) {
        setState(() {
          _logs = logs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
      
      // Auto select tanggal 1 jika ganti bulan
      _selectedDate = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-01';
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

    // Group logs by tanggal
    final selectedMonthStr = _selectedMonth.toString().padLeft(2, '0');
    final selectedYearMonth = '$_selectedYear-$selectedMonthStr';

    final grouped = <String, List<PresensiLog>>{};
    for (final log in _logs) {
      if (log.tanggal.startsWith(selectedYearMonth)) {
        grouped.putIfAbsent(log.tanggal, () => []).add(log);
      }
    }

    // Count stats
    var lengkapCount = 0;
    var tidakLengkapCount = 0;
    final totalHariAbsen = grouped.keys.length;

    for (final dayLogs in grouped.values) {
      final uniqueTypes = dayLogs.map((l) => l.tipe).toSet();
      if (uniqueTypes.length == 4) {
        lengkapCount++;
      } else {
        tidakLengkapCount++;
      }
    }

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
          RekapMonthSelector(
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            textColor: textColor,
            onPrevMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
          ),

          // ── Stats Cards ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(
                  label: 'Absen Lengkap',
                  value: lengkapCount.toString(),
                  color: AppColors.success,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Tidak Lengkap',
                  value: tidakLengkapCount.toString(),
                  color: AppColors.warning,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Total Hari',
                  value: totalHariAbsen.toString(),
                  color: AppColors.primary,
                  bgColor: cardBg,
                  textColor: textColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Calendar & Details ──────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RekapCalendarGrid(
                          selectedYear: _selectedYear,
                          selectedMonth: _selectedMonth,
                          selectedDate: _selectedDate,
                          grouped: grouped,
                          textColor: textColor,
                          cardBg: cardBg,
                          onDateSelected: (dateStr) {
                            setState(() => _selectedDate = dateStr);
                          },
                        ),
                        const SizedBox(height: 16),
                        RekapDetailCard(
                          selectedDate: _selectedDate,
                          logs: _selectedDate != null ? (grouped[_selectedDate] ?? []) : [],
                          textColor: textColor,
                          cardBg: cardBg,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
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
