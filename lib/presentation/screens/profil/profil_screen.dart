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
import 'widgets/profil_action_buttons.dart';
import 'widgets/profil_header_card.dart';
import 'widgets/profil_info_section.dart';
import 'widgets/profil_pengaturan_card.dart';

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
              ProfilHeaderCard(pegawai: _pegawai),
              const SizedBox(height: 16),

              // ── Detail Info ───────────────────────────────────
              ProfilInfoSection(
                pegawai: _pegawai,
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 16),

              // ── Detail Pengaturan Presensi ────────────────────
              ProfilPengaturanCard(
                pengaturan: _pengaturan,
                cardBg: cardBg,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 24),

              // ── Sync & Logout Buttons ─────────────────────────
              ProfilActionButtons(
                isSyncing: _isSyncing,
                loggingOut: _loggingOut,
                onSync: _handleSync,
                onLogout: _handleLogout,
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
