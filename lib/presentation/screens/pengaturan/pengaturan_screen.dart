// ====================================
// Pengaturan Screen — Settings
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/local/settings_dao.dart';
import '../../../data/models/pengaturan_presensi.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _loggingOut = false;
  bool _isSyncing = false;
  PengaturanPresensi? _pengaturan;

  @override
  void initState() {
    super.initState();
    _loadPengaturan();
  }

  Future<void> _loadPengaturan() async {
    final pengaturan = await SettingsDao.getFirst();
    if (mounted) {
      setState(() {
        _pengaturan = pengaturan;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final pegawai = await AuthService.getPegawai();
      final skpdId = pegawai?.skpdId;
      if (skpdId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SKPD ID tidak ditemukan.')),
          );
        }
        return;
      }
      await syncPengaturan(skpdId: skpdId);
      await _loadPengaturan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil diperbarui dari server.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui pengaturan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Data presensi yang belum disinkronkan akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await AuthService.logout();
      await PresensiDao.clear();
      await SettingsDao.clear();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal logout. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Detail Pengaturan Presensi ────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏢 Detail Pengaturan Presensi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_pengaturan != null) ...[
                    _SettingRow(
                      label: 'Kantor',
                      value: _pengaturan!.namaKantor ?? 'Instansi DLH',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    _SettingRow(
                      label: 'Koordinat Titik',
                      value:
                          '${_pengaturan!.latitude.toStringAsFixed(6)}, ${_pengaturan!.longitude.toStringAsFixed(6)}',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    _SettingRow(
                      label: 'Jejari Geofence',
                      value: '${_pengaturan!.radius} meter',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isLast: true,
                    ),
                    Divider(color: borderColor, height: 24, thickness: 1),
                    Text(
                      '🕒 Jam Kerja',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingRow(
                      label: 'Presensi Masuk',
                      value:
                          '${_pengaturan!.jamMasukMulai.substring(0, 5)} - ${_pengaturan!.jamMasukSelesai.substring(0, 5)}',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    _SettingRow(
                      label: 'Keluar Istirahat',
                      value:
                          '${_pengaturan!.jamIstirahatMulai.substring(0, 5)} - ${_pengaturan!.jamIstirahatSelesai.substring(0, 5)}',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    _SettingRow(
                      label: 'Masuk Istirahat',
                      value:
                          '${_pengaturan!.jamIstirahatSelesai.substring(0, 5)} - ${_pengaturan!.jamIstirahatMulai.substring(0, 5)}',
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    _SettingRow(
                      label: 'Presensi Pulang',
                      value:
                          '${_pengaturan!.jamPulangMulai.substring(0, 5)} - ${_pengaturan!.jamPulangSelesai.substring(0, 5)}',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isLast: true,
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Pengaturan lokal belum disinkronkan. Hubungkan ke internet untuk memperbarui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: subtextColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── App Info ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 Informasi Aplikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingRow(
                    label: 'Versi',
                    value: '1.0.0',
                    textColor: textColor,
                    subtextColor: subtextColor,
                  ),
                  _SettingRow(
                    label: 'Framework',
                    value: 'Flutter',
                    textColor: textColor,
                    subtextColor: subtextColor,
                  ),
                  _SettingRow(
                    label: 'Mode',
                    value: 'Offline-First',
                    textColor: textColor,
                    subtextColor: subtextColor,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Sync Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _handleSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('⚙️', style: TextStyle(fontSize: 20)),
                label: Text(
                  _isSyncing ? 'Memperbarui...' : 'Sinkronkan Pengaturan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Logout Button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loggingOut ? null : _handleLogout,
                icon: _loggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Footer ────────────────────────────────────────
            Center(
              child: Text(
                'Presensi DLH v1.0 • Offline-First',
                style: TextStyle(fontSize: 12, color: subtextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subtextColor;
  final bool isLast;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtextColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
              ),
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: subtextColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
