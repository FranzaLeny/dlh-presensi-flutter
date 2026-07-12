// ====================================
// Absen Screen — Daftar Pengajuan Absen
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../data/local/absen_dao.dart';
import '../../../data/local/hari_libur_dao.dart';
import '../../../data/models/presensi_absen.dart';
import '../../../data/models/hari_libur.dart';
import '../../../services/sync_engine.dart';
import 'widgets/absen_empty_state.dart';
import 'widgets/absen_list_item.dart';
import 'widgets/hari_libur_list_item.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  List<PresensiAbsen> _allAbsens = [];
  List<HariLibur> _allLibur = [];
  bool _loading = true;
  bool _syncingAbsen = false;
  bool _syncingLibur = false;

  int _absenLimit = 5;
  int _liburLimit = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final listAbsen = await AbsenDao.getAll();
    final listLibur = await HariLiburDao.getAll();
    if (mounted) {
      setState(() {
        _allAbsens = listAbsen;
        _allLibur = listLibur;
        _loading = false;
      });
    }
  }

  Future<void> _handleRefreshAbsen() async {
    setState(() => _syncingAbsen = true);
    try {
      await syncAbsenPegawai();
      await _loadData();
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
        setState(() => _syncingAbsen = false);
      }
    }
  }

  Future<void> _handleRefreshLibur() async {
    setState(() => _syncingLibur = true);
    try {
      await syncHariLibur();
      await _loadData();
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
        setState(() => _syncingLibur = false);
      }
    }
  }

  Map<String, List<PresensiAbsen>> _getGroupedAbsen() {
    final Map<String, List<PresensiAbsen>> grouped = {};
    for (final item in _allAbsens) {
      grouped.putIfAbsent(item.id, () => []).add(item);
    }
    return grouped;
  }

  List<String> _getSortedGroupedIds(Map<String, List<PresensiAbsen>> grouped) {
    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      final dateA = grouped[a]!
          .map((e) => e.tanggal)
          .reduce((x, y) => x.compareTo(y) > 0 ? x : y);
      final dateB = grouped[b]!
          .map((e) => e.tanggal)
          .reduce((x, y) => x.compareTo(y) > 0 ? x : y);
      return dateB.compareTo(dateA); // descending
    });
    return keys;
  }

  Map<String, List<HariLibur>> _getGroupedLibur() {
    final Map<String, List<HariLibur>> grouped = {};
    for (final item in _allLibur) {
      grouped.putIfAbsent(item.id, () => []).add(item);
    }
    return grouped;
  }

  List<String> _getSortedGroupedLiburIds(Map<String, List<HariLibur>> grouped) {
    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      final dateA = grouped[a]!
          .map((e) => e.tanggal)
          .reduce((x, y) => x.compareTo(y) > 0 ? x : y);
      final dateB = grouped[b]!
          .map((e) => e.tanggal)
          .reduce((x, y) => x.compareTo(y) > 0 ? x : y);
      return dateB.compareTo(dateA); // descending
    });
    return keys;
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isSyncing,
    required VoidCallback onSync,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          IconButton(
            onPressed: isSyncing ? null : onSync,
            icon: isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.sync_rounded, size: 20),
            tooltip: 'Sinkronisasi $title',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final grouped = _getGroupedAbsen();
    final sortedIds = _getSortedGroupedIds(grouped);

    final groupedLibur = _getGroupedLibur();
    final sortedLiburIds = _getSortedGroupedLiburIds(groupedLibur);

    // Limit lists
    final visibleAbsenIds = sortedIds.take(_absenLimit).toList();
    final visibleLiburIds = sortedLiburIds.take(_liburLimit).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Daftar Absen',
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await context.push('/absen/form');
              if (result == true) {
                _loadData();
              }
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            label: const Text(
              'Ajukan',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ================= ABSEN SECTION =================
                _buildSectionHeader(
                  title: 'Riwayat Pengajuan',
                  isSyncing: _syncingAbsen,
                  onSync: _handleRefreshAbsen,
                  textColor: textColor,
                ),
                
                if (sortedIds.isEmpty)
                  AbsenEmptyState(subtextColor: subtextColor)
                else
                  ...visibleAbsenIds.map((id) {
                    final list = grouped[id]!;
                    return AbsenListItem(
                      items: list,
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onEdit: () async {
                        final result = await context.push(
                          '/absen/form',
                          extra: list,
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                    );
                  }),

                if (sortedIds.length > _absenLimit)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _absenLimit += 5;
                      });
                    },
                    child: const Text('Lihat Lainnya'),
                  ),

                const SizedBox(height: 24),
                Divider(color: isDark ? Colors.white12 : Colors.black12),
                const SizedBox(height: 24),

                // ================= HARI LIBUR SECTION =================
                _buildSectionHeader(
                  title: 'Hari Libur & Cuti Bersama',
                  isSyncing: _syncingLibur,
                  onSync: _handleRefreshLibur,
                  textColor: textColor,
                ),

                if (sortedLiburIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Belum ada data hari libur.',
                        style: TextStyle(color: subtextColor),
                      ),
                    ),
                  )
                else
                  ...visibleLiburIds.map((id) {
                    final list = groupedLibur[id]!;
                    return HariLiburListItem(
                      items: list,
                      isDark: isDark,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    );
                  }),

                if (sortedLiburIds.length > _liburLimit)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _liburLimit += 5;
                      });
                    },
                    child: const Text('Lihat Lainnya'),
                  ),
                
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

