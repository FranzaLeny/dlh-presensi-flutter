import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/status.dart';
import '../../../../data/models/presensi_log.dart';

class PresensiActionButtons extends StatelessWidget {
  final PresensiLog? masukLog;
  final PresensiLog? mulaiIstirahatLog;
  final PresensiLog? selesaiIstirahatLog;
  final PresensiLog? pulangLog;
  final List<PresensiLog> todayLogs;
  final bool loading;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;
  final Function(TipePresensi) onAbsen;
  final VoidCallback onRedo;

  const PresensiActionButtons({
    super.key,
    required this.masukLog,
    required this.mulaiIstirahatLog,
    required this.selesaiIstirahatLog,
    required this.pulangLog,
    required this.todayLogs,
    required this.loading,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
    required this.onAbsen,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    if (masukLog != null &&
        mulaiIstirahatLog != null &&
        selesaiIstirahatLog != null &&
        pulangLog != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('✅', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  'Presensi Lengkap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anda sudah absen masuk, istirahat, dan pulang hari ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
              ],
            ),
          ),
          if (todayLogs.any((l) => !l.isSynced || l.status == Status.rejected))
            _buildRedoButton(),
        ],
      );
    }

    Widget? actionButton;
    if (masukLog == null) {
      actionButton = _buildAbsenButton(
        context: context,
        jenis: TipePresensi.masuk,
        color: AppColors.absenMasuk,
        emoji: '👋',
        label: 'Absen Masuk',
        sublabel: 'Tap untuk absen masuk',
      );
    } else if (mulaiIstirahatLog == null) {
      actionButton = _buildAbsenButton(
        context: context,
        jenis: TipePresensi.mulaiIstirahat,
        color: AppColors.absenIstirahatMulai,
        emoji: '☕',
        label: 'Mulai Istirahat',
        sublabel: 'Tap untuk absen keluar istirahat',
      );
    } else if (selesaiIstirahatLog == null) {
      actionButton = _buildAbsenButton(
        context: context,
        jenis: TipePresensi.selesaiIstirahat,
        color: AppColors.absenIstirahatSelesai,
        emoji: '🏃',
        label: 'Selesai Istirahat',
        sublabel: 'Tap untuk absen masuk istirahat',
      );
    } else if (pulangLog == null) {
      actionButton = _buildAbsenButton(
        context: context,
        jenis: TipePresensi.pulang,
        color: AppColors.absenPulang,
        emoji: '🏠',
        label: 'Absen Pulang',
        sublabel: 'Tap untuk absen pulang',
      );
    }

    return Column(
      children: [
        ?actionButton,
        if (todayLogs.any((l) => !l.isSynced || l.status == Status.rejected))
          _buildRedoButton(),
      ],
    );
  }

  Widget _buildAbsenButton({
    required BuildContext context,
    required TipePresensi jenis,
    required Color color,
    required String emoji,
    required String label,
    required String sublabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subTxtColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);

    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: txtColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(sublabel, style: TextStyle(color: subTxtColor, fontSize: 14)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: loading ? null : () => onAbsen(jenis),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: loading
                ? Center(child: CircularProgressIndicator(color: color))
                : Center(
                    child: Icon(Icons.fingerprint, size: 80, color: color),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedoButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton(
        onPressed: loading ? null : onRedo,
        child: const Text(
          '🗑️ Hapus Absen Hari Ini',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
