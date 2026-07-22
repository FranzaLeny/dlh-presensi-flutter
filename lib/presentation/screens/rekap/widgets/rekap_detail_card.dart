import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/status.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../data/models/presensi_log.dart';
import '../../../../data/models/presensi_absen.dart';
import '../../../../data/models/hari_libur.dart';

class RekapDetailCard extends StatelessWidget {
  final String? selectedDate;
  final List<PresensiLog> logs;
  final double jamKerjaEfektif;
  final double jamKerja;
  final String statusText;
  final PresensiAbsen? approvedAbsence;
  final HariLibur? hariLibur;
  final Color textColor;
  final Color cardBg;

  const RekapDetailCard({
    super.key,
    required this.selectedDate,
    required this.logs,
    required this.jamKerjaEfektif,
    required this.jamKerja,
    required this.statusText,
    required this.approvedAbsence,
    this.hariLibur,
    required this.textColor,
    required this.cardBg,
  });

  String _getStatusLabel(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'libur':
        return 'Hari Libur';
      case 'tidak_lengkap':
      case 'alpa':
        return 'Tanpa Berita';
      case 'sakit':
        return 'Sakit';
      case 'tugas':
        return 'Tugas Dinas';
      case 'cuti':
        return 'Cuti';
      default:
        return 'Tanpa Berita';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'libur':
        return Colors.grey;
      case 'tidak_lengkap':
        return Colors.red;
      case 'sakit':
        return Colors.amber;
      case 'tugas':
        return Colors.blue;
      case 'cuti':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getBadgeTextColor(String status, bool isDark) {
    if (isDark) {
      switch (status) {
        case 'hadir':
          return const Color(0xFF81C784); // light green
        case 'libur':
          return const Color(0xFFE0E0E0); // light grey
        case 'tidak_lengkap':
          return const Color(0xFFE57373); // light red
        case 'sakit':
          return const Color(0xFFFFD54F); // light amber
        case 'tugas':
          return const Color(0xFF64B5F6); // light blue
        case 'cuti':
          return const Color(0xFFBA68C8); // light purple
        default:
          return Colors.white70;
      }
    } else {
      switch (status) {
        case 'hadir':
          return const Color(0xFF1E4620); // dark green
        case 'libur':
          return const Color(0xFF333333); // dark grey
        case 'tidak_lengkap':
          return const Color(0xFF721C24); // dark red
        case 'sakit':
          return const Color(0xFF856404); // dark amber
        case 'tugas':
          return const Color(0xFF004085); // dark blue
        case 'cuti':
          return const Color(0xFF381460); // dark purple
        default:
          return const Color(0xFF333333);
      }
    }
  }

  Color _getBadgeBgColor(String status, bool isDark) {
    final baseColor = _getStatusColor(status);
    return baseColor.withValues(alpha: isDark ? 0.2 : 0.15);
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Pilih tanggal pada kalender',
              style: TextStyle(color: textColor.withValues(alpha: 0.5))),
        ),
      );
    }

    final subtextColor = textColor.withValues(alpha: 0.6);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort logs by waktu for chronological order
    final sortedLogs = List<PresensiLog>.from(logs);
    sortedLogs.sort((a, b) => a.waktu.compareTo(b.waktu));

    final stColor = _getStatusColor(statusText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Detail Presensi: $selectedDate',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),

        // ── Card Ringkasan Harian ─────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status Kehadiran',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBadgeBgColor(statusText, isDark),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getBadgeTextColor(statusText, isDark).withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(statusText),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getBadgeTextColor(statusText, isDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Kerja Efektif',
                          style: TextStyle(fontSize: 11, color: subtextColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${jamKerjaEfektif.toStringAsFixed(1)} Jam',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Kerja Aktual',
                          style: TextStyle(fontSize: 11, color: subtextColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${jamKerja.toStringAsFixed(1)} Jam',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: jamKerja > 0 ? Colors.green : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Card Detail Absen Pengajuan jika ada ───────────
        if (approvedAbsence != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    approvedAbsence!.tipe == 'sakit'
                        ? Icons.medical_services_rounded
                        : (approvedAbsence!.tipe == 'tugas'
                            ? Icons.work_history_rounded
                            : Icons.beach_access_rounded),
                    color: stColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Izin ${approvedAbsence!.tipe.toUpperCase()} Disetujui',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keterangan: ${approvedAbsence!.keterangan ?? '-'}',
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Card Detail Hari Libur jika ada ───────────
        if (hariLibur != null && logs.isEmpty && approvedAbsence == null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (hariLibur!.tipe == 'libur_nasional'
                            ? Colors.red
                            : (hariLibur!.tipe == 'cuti_bersama' ? Colors.orange : Colors.blue))
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hariLibur!.tipe == 'libur_nasional'
                        ? Icons.calendar_month_rounded
                        : (hariLibur!.tipe == 'cuti_bersama' ? Icons.beach_access_rounded : Icons.event_note_rounded),
                    color: hariLibur!.tipe == 'libur_nasional'
                        ? Colors.red
                        : (hariLibur!.tipe == 'cuti_bersama' ? Colors.orange : Colors.blue),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hariLibur!.nama,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keterangan: ${hariLibur!.keterangan ?? hariLibur!.tipe.replaceAll('_', ' ')}',
                        style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (statusText == 'libur' && logs.isEmpty && approvedAbsence == null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.weekend_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Libur Reguler',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keterangan: Libur akhir pekan atau sesuai edaran jam kerja',
                        style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Log Presensi Harian ───────────────────────────
        if (sortedLogs.isEmpty && approvedAbsence == null && hariLibur == null && statusText != 'libur')
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Tidak ada riwayat presensi',
                style: TextStyle(color: subtextColor),
              ),
            ),
          )
        else
          ...sortedLogs.map((log) {
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
                              color: subtextColor),
                        ),
                        if (log.keterangan != null && log.keterangan!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Keterangan: ${log.keterangan}',
                            style: TextStyle(
                              fontSize: 11,
                              color: subtextColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (log.namaVerifikator != null && log.namaVerifikator!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified_user_rounded, size: 12, color: subtextColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Diverifikasi oleh: ${log.namaVerifikator}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subtextColor,
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
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      if (log.isLuarRadius > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('WFA',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
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
