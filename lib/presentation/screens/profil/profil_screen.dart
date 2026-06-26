// ====================================
// Profil Screen — Profil Pegawai
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/pegawai.dart';
import '../../../services/auth_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Pegawai? _pegawai;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPegawai();
  }

  Future<void> _loadPegawai() async {
    final pegawai = await AuthService.getPegawai();
    if (mounted) {
      setState(() {
        _pegawai = pegawai;
        _loading = false;
      });
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
        title: Text('Profil',
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
              ),
              child: Column(
                children: [
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
          ],
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
