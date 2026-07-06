import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class InlineMultiCalendar extends StatefulWidget {
  final List<String> selectedDates;
  final ValueChanged<String> onDateToggled;
  final bool isReadOnly;

  const InlineMultiCalendar({
    super.key,
    required this.selectedDates,
    required this.onDateToggled,
    this.isReadOnly = false,
  });

  @override
  State<InlineMultiCalendar> createState() => _InlineMultiCalendarState();
}

class _InlineMultiCalendarState extends State<InlineMultiCalendar> {
  late DateTime _focusedMonth;

  final List<String> _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedDates.isNotEmpty) {
      _focusedMonth = DateTime.parse(widget.selectedDates.first);
    } else {
      _focusedMonth = DateTime.now();
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    final totalDays = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    final leadingEmptyDays = firstDayWeekday - 1;

    final totalGridItems = totalDays + leadingEmptyDays;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: textColor),
              onPressed: _prevMonth,
            ),
            Text(
              '${_months[month - 1]} $year',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: textColor),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays.map((day) {
            final isWeekend = day == 'Sab' || day == 'Min';
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isWeekend ? AppColors.error : subtextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: totalGridItems,
          itemBuilder: (context, index) {
            if (index < leadingEmptyDays) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - leadingEmptyDays + 1;
            final dayStr = dayNumber.toString().padLeft(2, '0');
            final monthStr = month.toString().padLeft(2, '0');
            final dateStr = '$year-$monthStr-$dayStr';

            final isSelected = widget.selectedDates.contains(dateStr);

            final now = DateTime.now();
            final isToday = now.year == year && now.month == month && now.day == dayNumber;

            return InkWell(
              onTap: widget.isReadOnly
                  ? null
                  : () => widget.onDateToggled(dateStr),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E5E1B) // Green background
                      : isToday
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.primary
                              : textColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
