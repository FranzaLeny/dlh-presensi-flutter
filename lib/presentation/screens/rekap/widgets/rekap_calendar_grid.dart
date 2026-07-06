import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/presensi_log.dart';

class RekapCalendarGrid extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final String? selectedDate;
  final Map<String, List<PresensiLog>> grouped;
  final Color textColor;
  final Color cardBg;
  final Function(String) onDateSelected;

  const RekapCalendarGrid({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDate,
    required this.grouped,
    required this.textColor,
    required this.cardBg,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedYear, selectedMonth, 1);
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1 (Mon) to 7 (Sun)

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

      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(formattedDateStr),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (hasData
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: isSelected || hasData
                    ? null
                    : Border.all(color: cardBg.withValues(alpha: 0.5)),
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
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: isSelected || hasData
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasData)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: rows),
    );
  }
}
