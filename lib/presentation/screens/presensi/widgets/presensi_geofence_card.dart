import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/providers.dart';

class PresensiGeofenceCard extends StatelessWidget {
  final GeofenceState geoState;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;
  final bool loading;
  final VoidCallback onRefresh;

  const PresensiGeofenceCard({
    super.key,
    required this.geoState,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
    required this.loading,
    required this.onRefresh,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Info Lokasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.primary,
                onPressed: loading ? null : onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (geoState.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (geoState.error != null)
            Text(
              geoState.error!.replaceFirst('Exception: ', ''),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (geoState.result != null) ...[
            Text(
              'Jarak ke kantor: ${geoState.result!.distance >= 1000 ? '${(geoState.result!.distance / 1000).toStringAsFixed(1)} km' : '${geoState.result!.distance} m'}',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            const SizedBox(height: 4),
            Text(
              geoState.result!.isInRadius
                  ? 'Lokasi dalam area kantor'
                  : 'Lokasi terdeteksi diluar area kantor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: geoState.result!.isInRadius
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ] else
            Text(
              'Lokasi belum diperiksa.',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
        ],
      ),
    );
  }
}
