// ====================================
// Rekap Screen — Rekap Bulanan
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/status.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
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

    // Group logs by tanggal (pastikan hanya untuk bulan & tahun terpilih)
    final selectedMonthStr = _selectedMonth.toString().padLeft(2, '0');
    final selectedYearMonth = '$_selectedYear-$selectedMonthStr';

    final grouped = <String, List<PresensiLog>>{};
    for (final log in _logs) {
      if (log.tanggal.startsWith(selectedYearMonth)) {
        grouped.putIfAbsent(log.tanggal, () => []).add(log);
      }
    }

    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

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
                        _buildCalendar(grouped, textColor, cardBg),
                        const SizedBox(height: 16),
                        _buildDateDetails(grouped, textColor, cardBg),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
      Map<String, List<PresensiLog>> grouped, Color textColor, Color cardBg) {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1 (Mon) to 7 (Sun)

    final daysOfWeek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final List<Widget> dayHeaders = daysOfWeek.map((day) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }).toList();

    List<Widget> rows = [Row(children: dayHeaders)];

    List<Widget> currentRow = [];
    // empty cells
    for (int i = 1; i < firstWeekday; i++) {
      currentRow.add(const Expanded(child: SizedBox.shrink()));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final hasData = grouped.containsKey(dateStr);
      final isSelected = _selectedDate == dateStr;

      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedDate = dateStr);
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (hasData
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: isSelected || hasData
                    ? null
                    : Border.all(color: cardBg.withValues(alpha: 0.5)),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: isSelected || hasData
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasData)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(Row(children: currentRow));
        currentRow = [];
      }
    }

    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(Row(children: currentRow));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildDateDetails(
      Map<String, List<PresensiLog>> grouped, Color textColor, Color cardBg) {
    if (_selectedDate == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Pilih tanggal pada kalender',
              style: TextStyle(color: textColor.withValues(alpha: 0.5))),
        ),
      );
    }

    final logs = grouped[_selectedDate] ?? [];
    
    // Sort logs by waktu for chronological order
    logs.sort((a, b) => a.waktu.compareTo(b.waktu));

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Tidak ada riwayat presensi',
              style: TextStyle(color: textColor.withValues(alpha: 0.5))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Detail Presensi: $_selectedDate',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
        ...logs.map((log) {
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
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTypeColor(log.tipe),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.tipe.displayLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 2),
                      Text(
                        date_utils.formatTime(DateTime.parse(log.waktu)),
                        style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: log.status == Status.approved
                              ? AppColors.success.withValues(alpha: 0.15)
                              : (log.status == Status.rejected ? AppColors.error.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          getStatusLabel(log.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: log.status == Status.approved
                                ? AppColors.success
                                : (log.status == Status.rejected ? AppColors.error : AppColors.warning),
                          ),
                        ),
                      ),
                      if (log.namaVerifikator != null && log.namaVerifikator!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.verified_user_rounded, size: 12, color: textColor.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Diverifikasi oleh: ${log.namaVerifikator}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textColor.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (log.isLuarRadius > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('WFA',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          );
        })
      ],
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
