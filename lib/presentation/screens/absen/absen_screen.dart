// ====================================
// Absen Screen — Daftar Pengajuan Absen
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../data/local/absen_dao.dart';
import '../../../data/models/presensi_absen.dart';
import '../../../services/sync_engine.dart';
import 'widgets/absen_empty_state.dart';
import 'widgets/absen_list_item.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  List<PresensiAbsen> _allAbsens = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await AbsenDao.getAll();
    if (mounted) {
      setState(() {
        _allAbsens = list;
        _loading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _syncing = true);
    try {
      await syncAbsenPegawai();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyinkronkan data: ${getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          'Daftar Kehadiran & Absen',
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _syncing ? null : _handleRefresh,
          ),
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
          : sortedIds.isEmpty
          ? AbsenEmptyState(subtextColor: subtextColor)
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: sortedIds.length,
                itemBuilder: (context, index) {
                  final id = sortedIds[index];
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
                },
              ),
            ),
    );
  }
}
