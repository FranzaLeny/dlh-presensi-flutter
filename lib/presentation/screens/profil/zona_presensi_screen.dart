import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pengaturan_presensi.dart';
import '../../../data/local/settings_dao.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';
import 'widgets/profil_pengaturan_card.dart';

class ZonaPresensiScreen extends StatefulWidget {
  const ZonaPresensiScreen({super.key});

  @override
  State<ZonaPresensiScreen> createState() => _ZonaPresensiScreenState();
}

class _ZonaPresensiScreenState extends State<ZonaPresensiScreen> {
  PengaturanPresensi? _pengaturan;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPengaturan();
  }

  Future<void> _loadPengaturan() async {
    final p = await SettingsDao.getFirst();
    if (mounted) {
      setState(() {
        _pengaturan = p;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSyncPengaturan() async {
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
      await syncSettings(skpdId: skpdId);
      final pengaturan = await SettingsDao.getFirst();
      if (mounted) {
        setState(() {
          _pengaturan = pengaturan;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pengaturan berhasil disinkronkan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi data pengaturan.'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi & Zona Presensi'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ProfilPengaturanCard(
              pengaturan: _pengaturan,
              cardBg: cardBg,
              textColor: textColor,
              subtextColor: subtextColor,
              borderColor: borderColor,
              onSyncPengaturan: _handleSyncPengaturan,
              isSyncingPengaturan: _isSyncing,
            ),
          ),
    );
  }
}
