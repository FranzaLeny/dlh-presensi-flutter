import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/status.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../data/models/presensi_log.dart';

class RekapDetailCard extends StatelessWidget {
  final String? selectedDate;
  final List<PresensiLog> logs;
  final Color textColor;
  final Color cardBg;

  const RekapDetailCard({
    super.key,
    required this.selectedDate,
    required this.logs,
    required this.textColor,
    required this.cardBg,
  });

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

    // Sort logs by waktu for chronological order
    final sortedLogs = List<PresensiLog>.from(logs);
    sortedLogs.sort((a, b) => a.waktu.compareTo(b.waktu));

    if (sortedLogs.isEmpty) {
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
            'Detail Presensi: $selectedDate',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
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
                            color: textColor.withValues(alpha: 0.7)),
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
