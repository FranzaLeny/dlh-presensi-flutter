import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class KeamananAkunScreen extends StatelessWidget {
  const KeamananAkunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan Akun'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenu(
            context,
            icon: Icons.password_rounded,
            title: 'Ubah Password',
            subtitle: 'Ganti kata sandi akun Anda secara berkala',
            onTap: () => context.push('/ubah-password'),
            bgColor: cardBg,
          ),
          const SizedBox(height: 12),
          _buildMenu(
            context,
            icon: Icons.email_rounded,
            title: 'Ubah Email',
            subtitle: 'Perbarui alamat email yang terdaftar',
            onTap: () => context.push('/ubah-email'),
            bgColor: cardBg,
          ),
          const SizedBox(height: 12),
          _buildMenu(
            context,
            icon: Icons.devices_rounded,
            title: 'Perangkat Tertaut',
            subtitle: 'Kelola aplikasi HP yang terhubung dengan akun ini',
            onTap: () => context.push('/perangkat'),
            bgColor: cardBg,
          ),
          const SizedBox(height: 12),
          _buildMenu(
            context,
            icon: Icons.security_rounded,
            title: 'Sesi Aktif',
            subtitle: 'Lihat daftar aktivitas login web dan perangkat',
            onTap: () => context.push('/sesi-aktif'),
            bgColor: cardBg,
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
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
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
