// ====================================
// Timeline Widget — Presensi Timeline
// ====================================

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/status.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/presensi_log.dart';

class TimelineWidget extends StatelessWidget {
  final PresensiLog? masukLog;
  final PresensiLog? mulaiIstirahatLog;
  final PresensiLog? selesaiIstirahatLog;
  final PresensiLog? pulangLog;
  final bool isDark;

  const TimelineWidget({
    super.key,
    this.masukLog,
    this.mulaiIstirahatLog,
    this.selesaiIstirahatLog,
    this.pulangLog,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        label: 'Presensi Masuk',
        log: masukLog,
        color: AppColors.absenMasuk,
        emoji: '🟢',
      ),
      _TimelineStep(
        label: 'Keluar Istirahat',
        log: mulaiIstirahatLog,
        color: AppColors.absenIstirahatMulai,
        emoji: '☕',
      ),
      _TimelineStep(
        label: 'Masuk Istirahat',
        log: selesaiIstirahatLog,
        color: AppColors.absenIstirahatSelesai,
        emoji: '🏃',
      ),
      _TimelineStep(
        label: 'Presensi Pulang',
        log: pulangLog,
        color: AppColors.absenPulang,
        emoji: '🔴',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${step.emoji} ${step.label}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              color: hasLog ? textColor : subtextColor,
                            ),
                          ),
                        ],
                      ),
                      if (step.log != null) ...[
                        const SizedBox(height: 6),
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
  final String emoji;

  const _TimelineStep({
    required this.label,
    this.log,
    required this.color,
    required this.emoji,
  });
}
