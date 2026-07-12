import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/sync_engine.dart';
import '../../../services/auth_service.dart';

class SinkronisasiScreen extends StatefulWidget {
  const SinkronisasiScreen({super.key});

  @override
  State<SinkronisasiScreen> createState() => _SinkronisasiScreenState();
}

class _SinkronisasiScreenState extends State<SinkronisasiScreen> {
  bool _isSyncingPegawai = false;
  bool _isSyncingPengaturan = false;
  bool _isSyncingHariLibur = false;
  bool _isSyncingAbsen = false;
  bool _isSyncingAllExceptPegawai = false;

  Future<void> _handleSyncPegawai() async {
    setState(() => _isSyncingPegawai = true);
    try {
      final updatedPegawai = await AuthService.syncPegawai();
      if (mounted && updatedPegawai != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data profil pegawai berhasil disinkronkan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi data profil pegawai.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingPegawai = false);
      }
    }
  }

  Future<void> _handleSyncPengaturan() async {
    setState(() => _isSyncingPengaturan = true);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pengaturan zona berhasil disinkronkan.'),
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
        setState(() => _isSyncingPengaturan = false);
      }
    }
  }

  Future<void> _handleSyncHariLibur() async {
    setState(() => _isSyncingHariLibur = true);
    try {
      await syncHariLibur();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data hari libur berhasil disinkronkan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi hari libur.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingHariLibur = false);
      }
    }
  }

  Future<void> _handleSyncAbsen() async {
    setState(() => _isSyncingAbsen = true);
    try {
      await syncAbsenPegawai();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data absen berhasil disinkronkan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi data absen.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingAbsen = false);
      }
    }
  }

  Future<void> _handleSyncAllExceptPegawai() async {
    setState(() => _isSyncingAllExceptPegawai = true);
    try {
      final pegawai = await AuthService.getPegawai();
      final skpdId = pegawai?.skpdId;
      await runFullSync(skpdId: skpdId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seluruh data (kecuali profil) berhasil disinkronkan.'),
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
        setState(() => _isSyncingAllExceptPegawai = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinkronisasi Data'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSyncButton(
            context,
            icon: Icons.person_rounded,
            label: 'Sinkronisasi Profil Pegawai',
            isLoading: _isSyncingPegawai,
            onPressed: _handleSyncPegawai,
          ),
          const SizedBox(height: 12),
          _buildSyncButton(
            context,
            icon: Icons.location_on_rounded,
            label: 'Sinkronisasi Pengaturan & Zona',
            isLoading: _isSyncingPengaturan,
            onPressed: _handleSyncPengaturan,
          ),
          const SizedBox(height: 12),
          _buildSyncButton(
            context,
            icon: Icons.calendar_month_rounded,
            label: 'Sinkronisasi Hari Libur',
            isLoading: _isSyncingHariLibur,
            onPressed: _handleSyncHariLibur,
          ),
          const SizedBox(height: 12),
          _buildSyncButton(
            context,
            icon: Icons.access_time_filled_rounded,
            label: 'Sinkronisasi Status Absen & Izin',
            isLoading: _isSyncingAbsen,
            onPressed: _handleSyncAbsen,
          ),
          const SizedBox(height: 12),
          _buildSyncButton(
            context,
            icon: Icons.cloud_sync_rounded,
            label: 'Sinkronisasi Semua Data Lokal',
            isLoading: _isSyncingAllExceptPegawai,
            onPressed: _handleSyncAllExceptPegawai,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(icon),
        label: Text(
          isLoading ? '$label...' : label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
