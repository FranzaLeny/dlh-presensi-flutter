import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pegawai.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/local/settings_dao.dart';
import '../../../data/local/hari_libur_dao.dart';
import '../../../data/local/absen_dao.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import 'widgets/profil_header_card.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Pegawai? _pegawai;
  bool _loading = true;
  bool _loggingOut = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pegawai = await AuthService.getPegawai();
    if (mounted) {
      setState(() {
        _pegawai = pegawai;
        _loading = false;
      });
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

  Future<void> _handleEditPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;
    final file = File(pickedFile.path);

    setState(() => _isUploadingPhoto = true);
    String? key;
    try {
      // 1. Upload ke Storage
      key = await StorageService.uploadProfilePhoto(file);
      
      // 2. Update Session (API)
      await AuthService.updateProfilePhoto(key);

      // 3. Update foto lokal secara manual
      await AuthService.setLocalProfilePhoto(file.path);

      // 4. Tarik data profil baru agar sync ke lokal
      final updatedPegawai = await AuthService.syncPegawai();
      if (mounted && updatedPegawai != null) {
        setState(() {
          _pegawai = updatedPegawai;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diubah'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Gagal upload foto profil: $e');
      if (key != null) {
        try {
          await StorageService.deleteFile(entity: 'profile', key: key);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah foto: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildMenu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      tileColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Avatar & Name ─────────────────────────────────
              ProfilHeaderCard(
                pegawai: _pegawai,
                isUploading: _isUploadingPhoto,
                onTapEdit: _handleEditPhoto,
              ),
              const SizedBox(height: 24),

              // ── Menu List ─────────────────────────────────────
              _buildMenu(
                context,
                icon: Icons.person_rounded,
                title: 'Data Kepegawaian',
                onTap: () => context.push('/profil/data-kepegawaian'),
                bgColor: cardBg,
              ),
              const SizedBox(height: 12),
              
              _buildMenu(
                context,
                icon: Icons.location_on_rounded,
                title: 'Informasi & Zona Presensi',
                onTap: () => context.push('/profil/zona-presensi'),
                bgColor: cardBg,
              ),
              const SizedBox(height: 12),

              _buildMenu(
                context,
                icon: Icons.security_rounded,
                title: 'Keamanan Akun',
                onTap: () => context.push('/profil/keamanan-akun'),
                bgColor: cardBg,
              ),
              const SizedBox(height: 12),

              _buildMenu(
                context,
                icon: Icons.cloud_sync_rounded,
                title: 'Sinkronisasi Data',
                onTap: () => context.push('/profil/sinkronisasi'),
                bgColor: cardBg,
              ),
              const SizedBox(height: 32),

              // ── Logout Button ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loggingOut ? null : _handleLogout,
                  icon: _loggingOut 
                      ? const SizedBox(
                          width: 18, height: 18, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error)
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(
                    _loggingOut ? 'Keluar...' : 'Keluar',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1),
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
                  'DigiLH v1.0 • Offline-First',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
