import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/status.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../data/models/presensi_log.dart';
import '../../../../data/models/presensi_absen.dart';

class RekapDetailCard extends StatelessWidget {
  final String? selectedDate;
  final List<PresensiLog> logs;
  final double jamKerjaEfektif;
  final double jamKerja;
  final String statusText;
  final PresensiAbsen? approvedAbsence;
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
        return 'Tidak Lengkap';
      case 'sakit':
        return 'Sakit';
      case 'tugas':
        return 'Tugas Dinas';
      case 'cuti':
        return 'Cuti';
      default:
        return 'Tanpa Keterangan';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'libur':
        return Colors.black;
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
                      color: stColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: stColor == Colors.black
                          ? Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.1))
                          : null,
                    ),
                    child: Text(
                      _getStatusLabel(statusText),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stColor == Colors.black && isDark ? Colors.white70 : stColor,
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

        // ── Log Presensi Harian ───────────────────────────
        if (sortedLogs.isEmpty && approvedAbsence == null)
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
