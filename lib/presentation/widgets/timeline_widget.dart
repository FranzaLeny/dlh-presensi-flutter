// ====================================
// Timeline Widget — Presensi Timeline
// ====================================

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/status.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/presensi_log.dart';
import '../../data/models/pengaturan_presensi.dart';
import '../../services/time_service.dart';

class TimelineWidget extends StatelessWidget {
  final PresensiLog? masukLog;
  final PresensiLog? mulaiIstirahatLog;
  final PresensiLog? selesaiIstirahatLog;
  final PresensiLog? pulangLog;
  final PengaturanPresensi? pengaturan;
  final bool isLibur;
  final bool isDark;

  const TimelineWidget({
    super.key,
    this.masukLog,
    this.mulaiIstirahatLog,
    this.selesaiIstirahatLog,
    this.pulangLog,
    this.pengaturan,
    this.isLibur = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get target times for today
    final witaTime = TimeService.getWITA(DateTime.now());
    final dayOfWeek = witaTime.weekday % 7; // 0 = Minggu, 6 = Sabtu
    final override = pengaturan?.jadwalHarian?.where((j) => j.hari == dayOfWeek).firstOrNull;

    String jamMasuk = isLibur ? '' : (override != null ? override.jamMasuk : (pengaturan?.jamMasuk ?? '08:00:00'));
    String jamPulang = isLibur ? '' : (override != null ? override.jamPulang : (pengaturan?.jamPulang ?? '16:00:00'));
    String jamIstirahatMulai = isLibur ? '' : (override != null ? (override.jamIstirahatMulai ?? '') : (pengaturan?.jamIstirahatMulai ?? '12:00:00'));
    String jamIstirahatSelesai = isLibur ? '' : (override != null ? (override.jamIstirahatSelesai ?? '') : (pengaturan?.jamIstirahatSelesai ?? '13:00:00'));

    // Format target times to HH:mm
    String formatTargetTime(String timeStr) {
      if (timeStr.isEmpty) return '—';
      try {
        final parts = timeStr.split(':');
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      } catch (_) {
        return '—';
      }
    }

    final targetMasuk = formatTargetTime(jamMasuk);
    final targetPulang = formatTargetTime(jamPulang);
    final targetIstirahatMulai = formatTargetTime(jamIstirahatMulai);
    final targetIstirahatSelesai = formatTargetTime(jamIstirahatSelesai);

    bool hasBreak = jamIstirahatMulai.isNotEmpty && jamIstirahatMulai != '-' && jamIstirahatMulai != '00:00:00' && targetIstirahatMulai != '—';

    final steps = [
      _TimelineStep(
        label: 'Presensi Masuk',
        log: masukLog,
        color: AppColors.absenMasuk,
        icon: Icons.login_rounded,
        targetTime: targetMasuk,
      ),
      if (hasBreak)
        _TimelineStep(
          label: 'Keluar Istirahat',
          log: mulaiIstirahatLog,
          color: AppColors.absenIstirahatMulai,
          icon: Icons.coffee_rounded,
          targetTime: targetIstirahatMulai,
        ),
      if (hasBreak)
        _TimelineStep(
          label: 'Masuk Istirahat',
          log: selesaiIstirahatLog,
          color: AppColors.absenIstirahatSelesai,
          icon: Icons.directions_run_rounded,
          targetTime: targetIstirahatSelesai,
        ),
      _TimelineStep(
        label: 'Presensi Pulang',
        log: pulangLog,
        color: AppColors.absenPulang,
        icon: Icons.logout_rounded,
        targetTime: targetPulang,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final hasLog = step.log != null;
        final isLast = index == steps.length - 1;
        final hasNextLog =
            !isLast && steps[index + 1].log != null;

        final timeStr = step.log?.waktu != null
            ? date_utils.formatTime(DateTime.parse(step.log!.waktu))
            : '—';

        final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
        final subtextColor = isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.5);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Circle + Line
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLog ? step.color : Colors.transparent,
                        border: Border.all(
                          color: hasLog
                              ? step.color
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: hasLog
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: hasLog && hasNextLog
                              ? step.color
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                  ],
                ),
              ),

              // Right: Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Label and Target Time (with Icon)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                step.targetTime,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: subtextColor,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                step.icon,
                                size: 16,
                                color: hasLog ? step.color : subtextColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Bottom Row (if log exists): Status Badges on left, Actual Time on right
                      if (step.log != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: step.log!.status == Status.approved
                                        ? AppColors.success.withValues(alpha: 0.15)
                                        : AppColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    getStatusLabel(step.log!.status),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: step.log!.status == Status.approved
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                                if (step.log!.isLuarRadius > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'WFA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineStep {
  final String label;
  final PresensiLog? log;
  final Color color;
  final IconData icon;
  final String targetTime;

  const _TimelineStep({
    required this.label,
    this.log,
    required this.color,
    required this.icon,
    required this.targetTime,
  });
}
