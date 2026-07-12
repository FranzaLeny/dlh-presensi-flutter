import 'package:flutter/material.dart';
import '../../../../data/models/hari_libur.dart';
import 'package:intl/intl.dart';

class HariLiburListItem extends StatelessWidget {
  final List<HariLibur> items;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const HariLiburListItem({
    super.key,
    required this.items,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    // Sort items by date ascending to get start and end
    final sortedItems = List<HariLibur>.from(items)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final firstItem = sortedItems.first;
    final lastItem = sortedItems.last;
    
    String formattedDate = '';
    
    DateTime? startDate = DateTime.tryParse(firstItem.tanggal);
    DateTime? endDate = DateTime.tryParse(lastItem.tanggal);
    
    if (startDate != null && endDate != null) {
      if (startDate == endDate) {
        formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(startDate);
      } else {
        bool sameMonth = true;
        bool isContiguous = true;
        List<DateTime> parsedDates = [];
        
        for (int i = 0; i < sortedItems.length; i++) {
          final dt = DateTime.tryParse(sortedItems[i].tanggal);
          if (dt != null) {
            parsedDates.add(dt);
            if (dt.month != startDate.month || dt.year != startDate.year) {
              sameMonth = false;
            }
            if (i > 0) {
              final prev = parsedDates[i-1];
              if (dt.difference(prev).inDays != 1) {
                isContiguous = false;
              }
            }
          }
        }
        
        if (sameMonth && !isContiguous) {
          final days = parsedDates.map((e) => DateFormat('dd').format(e)).join(', ');
          final monthYear = DateFormat('MMM yyyy', 'id_ID').format(startDate);
          formattedDate = '$days $monthYear (${items.length} Hari)';
        } else if (sameMonth && isContiguous) {
          final startDay = DateFormat('dd').format(startDate);
          final endDay = DateFormat('dd MMM yyyy', 'id_ID').format(endDate);
          formattedDate = '$startDay - $endDay (${items.length} Hari)';
        } else {
          formattedDate = '${DateFormat('dd MMM', 'id_ID').format(startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(endDate)} (${items.length} Hari)';
        }
      }
    } else {
      formattedDate = firstItem.tanggal;
    }

    final isLiburNasional = firstItem.tipe == 'libur_nasional';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLiburNasional 
                  ? Colors.red.withValues(alpha: 0.1) 
                  : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLiburNasional ? Icons.calendar_month_rounded : Icons.beach_access_rounded,
                color: isLiburNasional ? Colors.red : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          firstItem.nama,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLiburNasional 
                            ? Colors.red.withValues(alpha: 0.1) 
                            : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLiburNasional ? 'Libur Nasional' : 'Cuti Bersama',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLiburNasional ? Colors.red : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.event, size: 14, color: subtextColor),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (firstItem.keterangan != null && firstItem.keterangan!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      firstItem.keterangan!,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
