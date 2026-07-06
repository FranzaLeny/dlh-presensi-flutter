import 'package:flutter/material.dart';
import '../../../../data/models/presensi_log.dart';
import '../../../../data/models/pengaturan_presensi.dart';
import '../../../widgets/timeline_widget.dart';

class PresensiTimelineSection extends StatelessWidget {
  final PresensiLog? masukLog;
  final PresensiLog? mulaiIstirahatLog;
  final PresensiLog? selesaiIstirahatLog;
  final PresensiLog? pulangLog;
  final PengaturanPresensi? pengaturan;
  final bool isLibur;
  final bool isDark;
  final Color cardBg;
  final Color textColor;

  const PresensiTimelineSection({
    super.key,
    required this.masukLog,
    required this.mulaiIstirahatLog,
    required this.selesaiIstirahatLog,
    required this.pulangLog,
    this.pengaturan,
    this.isLibur = false,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Presensi Hari Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TimelineWidget(
            masukLog: masukLog,
            mulaiIstirahatLog: mulaiIstirahatLog,
            selesaiIstirahatLog: selesaiIstirahatLog,
            pulangLog: pulangLog,
            pengaturan: pengaturan,
            isLibur: isLibur,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}
