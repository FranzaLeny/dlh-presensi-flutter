import 'package:flutter/material.dart';

class RekapMonthSelector extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final Color textColor;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  const RekapMonthSelector({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.textColor,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevMonth,
            icon: Icon(Icons.chevron_left, color: textColor),
          ),
          Text(
            '${_months[selectedMonth - 1]} $selectedYear',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          IconButton(
            onPressed: onNextMonth,
            icon: Icon(Icons.chevron_right, color: textColor),
          ),
        ],
      ),
    );
  }
}
