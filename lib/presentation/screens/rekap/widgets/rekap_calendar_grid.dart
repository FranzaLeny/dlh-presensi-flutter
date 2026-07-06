import 'package:flutter/material.dart';
import '../../../../data/models/presensi_log.dart';

class RekapCalendarGrid extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final String? selectedDate;
  final Map<String, List<PresensiLog>> grouped;
  final Map<String, ({String statusText, Color statusColor, double jamKerjaEfektif, double jamKerja})> dayStatuses;
  final Color textColor;
  final Color cardBg;
  final Function(String) onDateSelected;

  const RekapCalendarGrid({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDate,
    required this.grouped,
    required this.dayStatuses,
    required this.textColor,
    required this.cardBg,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedYear, selectedMonth, 1);
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1 (Mon) to 7 (Sun)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final daysOfWeek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final List<Widget> dayHeaders = daysOfWeek.map((day) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }).toList();

    List<Widget> rows = [Row(children: dayHeaders)];

    List<Widget> currentRow = [];
    // empty cells
    for (int i = 1; i < firstWeekday; i++) {
      currentRow.add(const Expanded(child: SizedBox.shrink()));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dayStr = day.toString().padLeft(2, '0');
      final monthStr = selectedMonth.toString().padLeft(2, '0');
      final formattedDateStr = '$selectedYear-$monthStr-$dayStr';
      final hasData = grouped.containsKey(formattedDateStr);
      final isSelected = selectedDate == formattedDateStr;

      final statusInfo = dayStatuses[formattedDateStr];

      Color cellBgColor = Colors.transparent;
      Color textStyleColor = textColor;
      FontWeight cellFontWeight = FontWeight.normal;
      
      if (statusInfo != null) {
        final stColor = statusInfo.statusColor;
        if (isSelected) {
          cellBgColor = stColor;
          textStyleColor = stColor == Colors.amber ? Colors.black87 : Colors.white;
          cellFontWeight = FontWeight.bold;
        } else {
          if (stColor == Colors.black || stColor == Colors.grey) {
            cellBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06);
            textStyleColor = isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.5);
          } else {
            cellBgColor = stColor.withValues(alpha: 0.15);
            textStyleColor = stColor;
            cellFontWeight = FontWeight.bold;
          }
        }
      } else if (isSelected) {
        cellBgColor = Theme.of(context).primaryColor;
        textStyleColor = Colors.white;
        cellFontWeight = FontWeight.bold;
      }

      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(formattedDateStr),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: cellBgColor,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? null
                    : Border.all(
                        color: statusInfo != null
                            ? Colors.transparent
                            : cardBg.withValues(alpha: 0.3),
                      ),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          color: textStyleColor,
                          fontWeight: cellFontWeight,
                          fontSize: 13,
                        ),
                      ),
                      if (hasData && !isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: textStyleColor,
                            shape: BoxShape.circle,
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(Row(children: currentRow));
        currentRow = [];
      }
    }

    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(Row(children: currentRow));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: rows),
    );
  }
}
