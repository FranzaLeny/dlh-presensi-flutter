import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pegawai.dart';
import '../../../services/auth_service.dart';
import 'widgets/profil_info_section.dart';

class DataKepegawaianScreen extends StatefulWidget {
  const DataKepegawaianScreen({super.key});

  @override
  State<DataKepegawaianScreen> createState() => _DataKepegawaianScreenState();
}

class _DataKepegawaianScreenState extends State<DataKepegawaianScreen> {
  Pegawai? _pegawai;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPegawai();
  }

  Future<void> _loadPegawai() async {
    final p = await AuthService.getPegawai();
    if (mounted) {
      setState(() {
        _pegawai = p;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSyncPegawai() async {
    setState(() => _isSyncing = true);
    try {
      final updatedPegawai = await AuthService.syncPegawai();
      if (mounted && updatedPegawai != null) {
        setState(() {
          _pegawai = updatedPegawai;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pegawai berhasil disinkronkan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi data pegawai.'),
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
        title: const Text('Data Kepegawaian'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ProfilInfoSection(
              pegawai: _pegawai,
              cardBg: cardBg,
              textColor: textColor,
              subtextColor: subtextColor,
              borderColor: borderColor,
              onSyncPegawai: _handleSyncPegawai,
              isSyncingPegawai: _isSyncing,
            ),
          ),
    );
  }
}
