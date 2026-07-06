import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/status.dart';
import '../../../../data/models/presensi_absen.dart';

class AbsenListItem extends StatelessWidget {
  final List<PresensiAbsen> items;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onEdit;

  const AbsenListItem({
    super.key,
    required this.items,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    required this.onEdit,
  });

  String _formatDateString(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: onEdit,
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
