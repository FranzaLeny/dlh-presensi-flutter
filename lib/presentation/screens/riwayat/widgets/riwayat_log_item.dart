import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../data/models/presensi_log.dart';

class RiwayatLogItem extends StatelessWidget {
  final PresensiLog log;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;
  final bool isSyncing;
  final VoidCallback onSingleSync;

  const RiwayatLogItem({
    super.key,
    required this.log,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
    required this.isSyncing,
    required this.onSingleSync,
  });

  @override
  Widget build(BuildContext context) {
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
              color: _getTypeColor(log.tipe).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                _getTypeIcon(log.tipe),
                color: _getTypeColor(log.tipe),
                size: 20,
              ),
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
                date_utils.formatTime(DateTime.parse(log.waktu)),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (!log.isSynced)
                     GestureDetector(
                       onTap: isSyncing ? null : onSingleSync,
                       child: Container(
                         margin: const EdgeInsets.only(right: 6),
                         padding: const EdgeInsets.all(2),
                         decoration: BoxDecoration(
                           color: AppColors.warning.withValues(alpha: 0.15),
                           shape: BoxShape.circle,
                           border: Border.all(
                             color: AppColors.warning,
                             width: 1,
                           ),
                         ),
                         child: isSyncing
                             ? const SizedBox(
                                 width: 12,
                                 height: 12,
                                 child: CircularProgressIndicator(
                                   strokeWidth: 1.5,
                                   valueColor: AlwaysStoppedAnimation<Color>(
                                     AppColors.warning,
                                   ),
                                 ),
                               )
                             : const Icon(Icons.sync_rounded, size: 12, color: AppColors.warning),
                       ),
                     ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: log.isSynced
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
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

  IconData _getTypeIcon(TipePresensi tipe) {
    switch (tipe) {
      case TipePresensi.masuk:
        return Icons.login_rounded;
      case TipePresensi.mulaiIstirahat:
        return Icons.coffee_rounded;
      case TipePresensi.selesaiIstirahat:
        return Icons.directions_run_rounded;
      case TipePresensi.pulang:
        return Icons.logout_rounded;
    }
  }
}
