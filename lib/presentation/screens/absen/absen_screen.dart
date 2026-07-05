// ====================================
// Absen Screen — Daftar Pengajuan Absen
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/status.dart';
import '../../../core/utils/error_utils.dart';
import '../../../data/local/absen_dao.dart';
import '../../../data/models/presensi_absen.dart';
import '../../../services/sync_engine.dart';

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

  String _formatDateString(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
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
          ? _buildEmptyState(subtextColor)
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: sortedIds.length,
                itemBuilder: (context, index) {
                  final id = sortedIds[index];
                  final list = grouped[id]!;
                  return _buildAbsenCard(
                    context,
                    list,
                    isDark,
                    textColor,
                    subtextColor,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(Color subtextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengajuan absen.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + di bawah untuk mengajukan cuti, sakit, atau dinas luar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenCard(
    BuildContext context,
    List<PresensiAbsen> items,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final first = items.first;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    // Get date range string
    final sortedDates = items.map((e) => e.tanggal).toList()..sort();
    final dateRangeStr = sortedDates.length == 1
        ? _formatDateString(sortedDates.first)
        : '${_formatDateString(sortedDates.first)} - ${_formatDateString(sortedDates.last)}';

    final isEditable =
        first.status == Status.pending || first.status == Status.rejected;

    // Icon & Color based on Tipe
    IconData typeIcon = Icons.event_note_outlined;
    Color typeColor = Colors.blue;
    if (first.tipe == 'cuti') {
      typeIcon = Icons.beach_access_rounded;
      typeColor = Colors.orange;
    } else if (first.tipe == 'sakit') {
      typeIcon = Icons.medical_services_rounded;
      typeColor = Colors.red;
    } else if (first.tipe == 'tugas') {
      typeIcon = Icons.work_history_rounded;
      typeColor = Colors.teal;
    }

    // Status Badge Color
    Color statusColor = Colors.orange;
    if (first.status == Status.approved) {
      statusColor = AppColors.success;
    } else if (first.status == Status.rejected) {
      statusColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tipe & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      first.tipe.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getStatusLabel(first.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: subtextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateRangeStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${items.length} Hari)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
                if (first.keterangan?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    first.keterangan!,
                    style: TextStyle(fontSize: 13, color: textColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (first.dokumenUrl?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      // Buka URL lampiran
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            first.dokumenUrl!.endsWith('.pdf')
                                ? Icons.picture_as_pdf_rounded
                                : Icons.image_rounded,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Lihat Lampiran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isEditable) ...[
            const Divider(height: 1),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final result = await context.push(
                          '/absen/form',
                          extra: items,
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text(
                        'Ubah Pengajuan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
