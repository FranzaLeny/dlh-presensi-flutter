import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfilActionButtons extends StatelessWidget {
  final bool isSyncingHariLibur;
  final bool isSyncingAbsen;
  final bool isSyncingAllExceptPegawai;
  final bool loggingOut;
  
  final VoidCallback onSyncHariLibur;
  final VoidCallback onSyncAbsen;
  final VoidCallback onSyncAllExceptPegawai;
  final VoidCallback onLogout;

  const ProfilActionButtons({
    super.key,
    required this.isSyncingHariLibur,
    required this.isSyncingAbsen,
    required this.isSyncingAllExceptPegawai,
    required this.loggingOut,
    required this.onSyncHariLibur,
    required this.onSyncAbsen,
    required this.onSyncAllExceptPegawai,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sync Hari Libur Button ────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSyncingHariLibur ? null : onSyncHariLibur,
            icon: isSyncingHariLibur
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.calendar_month_rounded),
            label: Text(
              isSyncingHariLibur ? 'Sinkronisasi Hari Libur...' : 'Sinkronisasi Hari Libur',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Sync Data Absen Button ────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSyncingAbsen ? null : onSyncAbsen,
            icon: isSyncingAbsen
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.event_note_rounded),
            label: Text(
              isSyncingAbsen ? 'Sinkronisasi Data Absen...' : 'Sinkronisasi Data Absen',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Sync Semua (Kecuali Data Pegawai) Button ───────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSyncingAllExceptPegawai ? null : onSyncAllExceptPegawai,
            icon: isSyncingAllExceptPegawai
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              isSyncingAllExceptPegawai ? 'Menyinkronkan Semua...' : 'Sinkronkan Semua (Kecuali Pegawai)',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Logout Button ─────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loggingOut ? null : onLogout,
            icon: loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(Icons.logout),
            label: const Text('Keluar / Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
