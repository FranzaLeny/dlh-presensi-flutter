// ====================================
// Profil Screen — Profil Pegawai
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pegawai.dart';
import '../../../data/models/pengaturan_presensi.dart';
import '../../../data/local/settings_dao.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/local/hari_libur_dao.dart';
import '../../../data/local/absen_dao.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Pegawai? _pegawai;
  PengaturanPresensi? _pengaturan;
  bool _loading = true;
  bool _isSyncing = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pegawai = await AuthService.getPegawai();
    final pengaturan = await SettingsDao.getFirst();
    if (mounted) {
      setState(() {
        _pegawai = pegawai;
        _pengaturan = pengaturan;
        _loading = false;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final skpdId = _pegawai?.skpdId;
      if (skpdId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SKPD ID tidak ditemukan.')),
          );
        }
        return;
      }
      await runFullSync(skpdId: skpdId);
      final pengaturan = await SettingsDao.getFirst();

      if (mounted) {
        setState(() {
          _pengaturan = pengaturan;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disinkronkan dari server.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi data.'),
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
          'Apakah Anda yakin ingin keluar? Seluruh data offline lokal akan dihapus.',
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
      await HariLiburDao.clear();
      await AbsenDao.clear();
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
    final cardBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Profil & Pengaturan',
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _handleSync,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Avatar & Name ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _pegawai?.nama.isNotEmpty == true
                            ? _pegawai!.nama[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pegawai?.nama ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pegawai?.jabatan ?? '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Detail Info ───────────────────────────────────
              Container(
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
                    Text(
                      '📋 Data Kepegawaian',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                        label: 'NIP',
                        value: _pegawai?.nip ?? '-',
                        textColor: textColor,
                        subtextColor: subtextColor),
                    _InfoRow(
                        label: 'Jenis Pegawai',
                        value: _pegawai?.jenisPegawai ?? '-',
                        textColor: textColor,
                        subtextColor: subtextColor),
                    _InfoRow(
                        label: 'Instansi',
                        value: _pegawai?.instansi ?? '-',
                        textColor: textColor,
                        subtextColor: subtextColor),
                    _InfoRow(
                        label: 'SKPD',
                        value: _pegawai?.namaSkpd ?? '-',
                        textColor: textColor,
                        subtextColor: subtextColor),
                    _InfoRow(
                        label: 'Jenis Kelamin',
                        value: _pegawai?.jenisKelamin == 'L'
                            ? 'Laki-laki'
                            : 'Perempuan',
                        textColor: textColor,
                        subtextColor: subtextColor,
                        isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Detail Pengaturan Presensi ────────────────────
              Container(
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
                    Text(
                      '🏢 Detail Pengaturan Presensi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_pengaturan != null) ...[
                      _InfoRow(
                        label: 'Kantor',
                        value: _pengaturan!.namaKantor ?? 'Instansi DLH',
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      _InfoRow(
                        label: 'Koordinat Titik',
                        value:
                            '${_pengaturan!.latitude.toStringAsFixed(6)}, ${_pengaturan!.longitude.toStringAsFixed(6)}',
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      _InfoRow(
                        label: 'Jejari Geofence',
                        value: '${_pengaturan!.radius} meter',
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      _InfoRow(
                        label: 'Presensi Masuk',
                        value: _pengaturan!.jamMasuk.substring(0, 5),
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      _InfoRow(
                        label: 'Istirahat',
                        value:
                            '${_pengaturan!.jamIstirahatMulai.substring(0, 5)} - ${_pengaturan!.jamIstirahatSelesai.substring(0, 5)}',
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                      _InfoRow(
                        label: 'Presensi Pulang',
                        value: _pengaturan!.jamPulang.substring(0, 5),
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
              ),
              const SizedBox(height: 24),

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
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    _isSyncing ? 'Menyinkronkan...' : 'Sinkronisasi Data Offline',
                    style: const TextStyle(
                      fontSize: 16,
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
              const SizedBox(height: 12),

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
              const SizedBox(height: 32),

              // ── Footer ────────────────────────────────────────
              Center(
                child: Text(
                  'DigiLH v1.0 • Offline-First',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
              ),
            ],
          ),
        ),
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
