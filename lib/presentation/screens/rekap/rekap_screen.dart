// ====================================
// Rekap Screen — Rekap Bulanan
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/status.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/local/settings_dao.dart';
import '../../../data/local/hari_libur_dao.dart';
import '../../../data/local/absen_dao.dart';
import '../../../data/models/presensi_log.dart';
import '../../../data/models/pengaturan_presensi.dart';
import '../../../data/models/hari_libur.dart';
import '../../../data/models/presensi_absen.dart';
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
  List<PengaturanPresensi> _settings = [];
  List<HariLibur> _holidays = [];
  List<PresensiAbsen> _absences = [];
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

  int _timeStringToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (_) {
      return 0;
    }
  }

  ({double jamKerjaEfektif, double jamKerja, String statusText, Color statusColor}) calculateDailyHours(
    String dateStr,
    List<PresensiLog> dayLogs,
  ) {
    final parsedDate = DateTime.parse(dateStr);
    final weekday = parsedDate.weekday;
    final isWeekend = weekday == DateTime.saturday || weekday == DateTime.sunday;
    final isHolidayDate = _holidays.any((h) => h.tanggal == dateStr);
    final isLibur = isWeekend || isHolidayDate;

    // 1. Cari Pengaturan Presensi
    PengaturanPresensi? activeSetting;
    for (final s in _settings) {
      bool startMatch = true;
      bool endMatch = true;
      if (s.tanggalMulai != null && s.tanggalMulai!.isNotEmpty) {
        final start = DateTime.tryParse(s.tanggalMulai!);
        if (start != null && parsedDate.isBefore(start)) {
          startMatch = false;
        }
      }
      if (s.tanggalBerakhir != null && s.tanggalBerakhir!.isNotEmpty) {
        final end = DateTime.tryParse(s.tanggalBerakhir!);
        if (end != null && parsedDate.isAfter(end)) {
          endMatch = false;
        }
      }
      if (startMatch && endMatch) {
        activeSetting = s;
        break;
      }
    }
    
    if (activeSetting == null && _settings.isNotEmpty) {
      activeSetting = _settings.first;
    }

    // 2. Hitung jamKerjaEfektif
    double jamKerjaEfektif = 0.0;
    if (!isLibur && activeSetting != null) {
      final startMin = _timeStringToMinutes(activeSetting.jamMasuk);
      final endMin = _timeStringToMinutes(activeSetting.jamPulang);
      final breakStartMin = _timeStringToMinutes(activeSetting.jamIstirahatMulai);
      final breakEndMin = _timeStringToMinutes(activeSetting.jamIstirahatSelesai);
      final totalMin = endMin - startMin;
      final breakMin = breakStartMin < breakEndMin ? (breakEndMin - breakStartMin) : 0;
      jamKerjaEfektif = (totalMin - breakMin) / 60.0;
      if (jamKerjaEfektif < 0) jamKerjaEfektif = 0.0;
    }

    // 3. Cek Absen Pengajuan (Sakit, Tugas, Cuti)
    final approvedAbsence = _absences.where((a) => a.tanggal == dateStr && (a.status == Status.approved || a.status == 20)).firstOrNull;

    // 4. Hitung jamKerja & tentukan status harian
    double jamKerja = 0.0;
    String statusText = '';
    Color statusColor = Colors.transparent;

    if (approvedAbsence != null) {
      if (approvedAbsence.tipe == 'sakit') {
        statusText = 'sakit';
        statusColor = Colors.amber; // kuning
      } else if (approvedAbsence.tipe == 'tugas') {
        statusText = 'tugas';
        statusColor = Colors.blue; // biru
      } else {
        statusText = 'cuti';
        statusColor = Colors.purple; // ungu
      }

      if (!isLibur) {
        jamKerja = jamKerjaEfektif; // Dianggap hadir penuh
      } else {
        jamKerja = 0.0;
      }
    } else if (isLibur) {
      statusText = 'libur';
      statusColor = Colors.black; // hitam

      // Jika libur, jamKerja bisa dihitung jika ada log presensi masuk & pulang lengkap
      final masukLog = dayLogs.where((l) => l.tipe == TipePresensi.masuk).firstOrNull;
      final pulangLog = dayLogs.where((l) => l.tipe == TipePresensi.pulang).firstOrNull;
      if (masukLog != null && pulangLog != null) {
        final tMasuk = DateTime.parse(masukLog.waktu);
        final tPulang = DateTime.parse(pulangLog.waktu);
        final elapsedMin = tPulang.difference(tMasuk).inMinutes;
        
        int breakMin = 0;
        final mulaiIstirahat = dayLogs.where((l) => l.tipe == TipePresensi.mulaiIstirahat).firstOrNull;
        final selesaiIstirahat = dayLogs.where((l) => l.tipe == TipePresensi.selesaiIstirahat).firstOrNull;
        if (mulaiIstirahat != null && selesaiIstirahat != null) {
          breakMin = DateTime.parse(selesaiIstirahat.waktu).difference(DateTime.parse(mulaiIstirahat.waktu)).inMinutes;
        }
        
        jamKerja = (elapsedMin - breakMin) / 60.0;
        if (jamKerja < 0) jamKerja = 0.0;
      }
    } else {
      // Hari kerja & tidak ada absen
      final masukLog = dayLogs.where((l) => l.tipe == TipePresensi.masuk).firstOrNull;
      final pulangLog = dayLogs.where((l) => l.tipe == TipePresensi.pulang).firstOrNull;

      if (masukLog != null && pulangLog != null) {
        statusText = 'hadir';
        statusColor = Colors.green; // hijau

        final tMasuk = DateTime.parse(masukLog.waktu);
        final tPulang = DateTime.parse(pulangLog.waktu);
        final elapsedMin = tPulang.difference(tMasuk).inMinutes;
        
        int breakMin = 0;
        final mulaiIstirahat = dayLogs.where((l) => l.tipe == TipePresensi.mulaiIstirahat).firstOrNull;
        final selesaiIstirahat = dayLogs.where((l) => l.tipe == TipePresensi.selesaiIstirahat).firstOrNull;
        if (mulaiIstirahat != null && selesaiIstirahat != null) {
          breakMin = DateTime.parse(selesaiIstirahat.waktu).difference(DateTime.parse(mulaiIstirahat.waktu)).inMinutes;
        }
        
        jamKerja = (elapsedMin - breakMin) / 60.0;
        if (jamKerja < 0) jamKerja = 0.0;
      } else {
        statusText = 'tidak_lengkap';
        statusColor = Colors.red; // merah
        jamKerja = 0.0;
      }
    }

    return (
      jamKerjaEfektif: jamKerjaEfektif,
      jamKerja: jamKerja,
      statusText: statusText,
      statusColor: statusColor,
    );
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
      final settings = await SettingsDao.getAll();
      final holidays = await HariLiburDao.getByMonth(_selectedYear, _selectedMonth);
      final absences = await AbsenDao.getByMonth(_selectedYear, _selectedMonth);

      if (mounted) {
        setState(() {
          _logs = logs;
          _settings = settings;
          _holidays = holidays;
          _absences = absences;
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

    // Count stats and calculate daily metrics
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    
    double monthlyJamKerjaEfektifTotal = 0.0;
    double monthlyJamKerjaActualTotal = 0.0;
    int totalTugas = 0;
    int totalCuti = 0;
    int totalSakit = 0;
    int totalHadir = 0;
    int totalTidakLengkap = 0;

    final dayStatuses = <String, ({String statusText, Color statusColor, double jamKerjaEfektif, double jamKerja})>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final dayStr = day.toString().padLeft(2, '0');
      final dateStr = '$_selectedYear-$selectedMonthStr-$dayStr';
      final dayLogs = grouped[dateStr] ?? [];
      
      final daily = calculateDailyHours(dateStr, dayLogs);
      dayStatuses[dateStr] = daily;

      monthlyJamKerjaEfektifTotal += daily.jamKerjaEfektif;
      monthlyJamKerjaActualTotal += daily.jamKerja;

      if (daily.statusText == 'tugas') {
        totalTugas++;
      } else if (daily.statusText == 'cuti') {
        totalCuti++;
      } else if (daily.statusText == 'sakit') {
        totalSakit++;
      } else if (daily.statusText == 'hadir') {
        totalHadir++;
      } else if (daily.statusText == 'tidak_lengkap') {
        totalTidakLengkap++;
      }
    }

    final lengkapCount = totalHadir;
    final tidakLengkapCount = totalTidakLengkap;
    final totalHariAbsen = grouped.keys.length;

    final persentaseJamKerja = monthlyJamKerjaEfektifTotal > 0
        ? (monthlyJamKerjaActualTotal / monthlyJamKerjaEfektifTotal) * 100.0
        : 0.0;

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
                          dayStatuses: dayStatuses,
                          textColor: textColor,
                          cardBg: cardBg,
                          onDateSelected: (dateStr) {
                            setState(() => _selectedDate = dateStr);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // ── Monthly Summary Card ────────────────────
                        _MonthlySummaryCard(
                          jamKerjaEfektif: monthlyJamKerjaEfektifTotal,
                          jamKerjaActual: monthlyJamKerjaActualTotal,
                          persentase: persentaseJamKerja,
                          totalTugas: totalTugas,
                          totalCuti: totalCuti,
                          totalSakit: totalSakit,
                          cardBg: cardBg,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 16),

                        RekapDetailCard(
                          selectedDate: _selectedDate,
                          logs: _selectedDate != null ? (grouped[_selectedDate] ?? []) : [],
                          jamKerjaEfektif: _selectedDate != null ? (dayStatuses[_selectedDate!]?.jamKerjaEfektif ?? 0.0) : 0.0,
                          jamKerja: _selectedDate != null ? (dayStatuses[_selectedDate!]?.jamKerja ?? 0.0) : 0.0,
                          statusText: _selectedDate != null ? (dayStatuses[_selectedDate!]?.statusText ?? '') : '',
                          approvedAbsence: _selectedDate != null
                              ? _absences.where((a) => a.tanggal == _selectedDate && (a.status == Status.approved || a.status == 20)).firstOrNull
                              : null,
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

class _MonthlySummaryCard extends StatelessWidget {
  final double jamKerjaEfektif;
  final double jamKerjaActual;
  final double persentase;
  final int totalTugas;
  final int totalCuti;
  final int totalSakit;
  final Color cardBg;
  final Color textColor;

  const _MonthlySummaryCard({
    required this.jamKerjaEfektif,
    required this.jamKerjaActual,
    required this.persentase,
    required this.totalTugas,
    required this.totalCuti,
    required this.totalSakit,
    required this.cardBg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final subtextColor = textColor.withValues(alpha: 0.6);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Choose progress bar color based on percentage
    Color progressColor = AppColors.error;
    if (persentase >= 90) {
      progressColor = AppColors.success;
    } else if (persentase >= 75) {
      progressColor = AppColors.primary;
    } else if (persentase >= 50) {
      progressColor = AppColors.warning;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📊 Ringkasan Bulanan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Jam Kerja', style: TextStyle(fontSize: 12, color: subtextColor)),
                    const SizedBox(height: 4),
                    Text(
                      '${jamKerjaActual.toStringAsFixed(1)} Jam',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target Jam Kerja', style: TextStyle(fontSize: 12, color: subtextColor)),
                    const SizedBox(height: 4),
                    Text(
                      '${jamKerjaEfektif.toStringAsFixed(1)} Jam',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Percentage progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Persentase Kehadiran', style: TextStyle(fontSize: 12, color: subtextColor)),
                  Text(
                    '${persentase.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: progressColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: jamKerjaEfektif > 0 ? (jamKerjaActual / jamKerjaEfektif).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AbsenceMiniStat(label: 'Tugas', value: totalTugas, color: Colors.blue, textColor: textColor),
              _AbsenceMiniStat(label: 'Cuti', value: totalCuti, color: Colors.purple, textColor: textColor),
              _AbsenceMiniStat(label: 'Sakit', value: totalSakit, color: Colors.amber, textColor: textColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbsenceMiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color textColor;

  const _AbsenceMiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.6))),
      ],
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
