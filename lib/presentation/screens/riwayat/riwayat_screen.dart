// ====================================
// Riwayat Screen — Riwayat Presensi
// ====================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/models/presensi_log.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';
import 'widgets/riwayat_log_item.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<PresensiLog> _logs = [];
  bool _loading = true;
  final Set<String> _syncingLogIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLocalLoading = true}) async {
    if (showLocalLoading) {
      setState(() => _loading = true);
    }
    try {
      final pegawai = await AuthService.getPegawai();
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final logs = await PresensiDao.getTodayAndUnsynced(
        pegawai?.id ?? '',
        today,
      );
      if (mounted) setState(() => _logs = logs);
    } catch (_) {}
    if (showLocalLoading && mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      await syncLogsBulanan(now.year, now.month);
    } catch (_) {}
    await _loadData();
  }

  Future<void> _handleSingleSync(String logId) async {
    if (_syncingLogIds.contains(logId)) return;

    setState(() {
      _syncingLogIds.add(logId);
    });

    try {
      final success = await syncSingleLog(logId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presensi berhasil disinkronkan.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mensinkronkan presensi.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncingLogIds.remove(logId);
        });
      }
      await _loadData(showLocalLoading: false);
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Riwayat Presensi',
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.sync, color: textColor),
                tooltip: 'Tarik Data Server',
                onPressed: _loading ? null : _handleRefresh,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _logs.isEmpty
                  ? Center(
                      child: Text('Belum ada riwayat presensi',
                          style: TextStyle(color: subtextColor)))
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return RiwayatLogItem(
                          log: log,
                          cardBg: cardBg,
                          textColor: textColor,
                          subtextColor: subtextColor,
                          isSyncing: _syncingLogIds.contains(log.id),
                          onSingleSync: () => _handleSingleSync(log.id),
                        );
                      },
                    ),
            ),
    );
  }
}
