import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/pengaturan_presensi.dart';

class ProfilPengaturanCard extends StatelessWidget {
  final PengaturanPresensi? pengaturan;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final VoidCallback? onSyncPengaturan;
  final bool isSyncingPengaturan;

  const ProfilPengaturanCard({
    super.key,
    required this.pengaturan,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    this.onSyncPengaturan,
    this.isSyncingPengaturan = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏢 Detail Pengaturan Presensi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (onSyncPengaturan != null)
                IconButton(
                  onPressed: isSyncingPengaturan ? null : onSyncPengaturan,
                  icon: isSyncingPengaturan
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  tooltip: 'Sinkronisasi Data Pengaturan',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (pengaturan != null) ...[
            _InfoRow(
              label: 'Kantor',
              value: pengaturan!.namaKantor ?? 'Instansi DLH',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _InfoRow(
              label: 'Koordinat Titik',
              value:
                  '${pengaturan!.latitude.toStringAsFixed(6)}, ${pengaturan!.longitude.toStringAsFixed(6)}',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _InfoRow(
              label: 'Jejari Geofence',
              value: '${pengaturan!.radius} meter',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _InfoRow(
              label: 'Presensi Masuk',
              value: pengaturan!.jamMasuk.substring(0, 5),
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _InfoRow(
              label: 'Istirahat',
              value:
                  '${pengaturan!.jamIstirahatMulai.substring(0, 5)} - ${pengaturan!.jamIstirahatSelesai.substring(0, 5)}',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            _InfoRow(
              label: 'Presensi Pulang',
              value: pengaturan!.jamPulang.substring(0, 5),
              textColor: textColor,
              subtextColor: subtextColor,
              isLast: true,
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Pengaturan lokal belum disinkronkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subtextColor;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtextColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: subtextColor)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
          ),
        ],
      ),
    );
  }
}
