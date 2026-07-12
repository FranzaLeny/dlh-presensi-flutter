import 'package:flutter/material.dart';

class RekapMonthSelector extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final Color textColor;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onSync;
  final bool isSyncing;
  final bool isDark;

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
    this.onSync,
    this.isSyncing = false,
    this.isDark = false,
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
          Row(
            children: [
              IconButton(
                onPressed: onNextMonth,
                icon: Icon(Icons.chevron_right, color: textColor),
              ),
              if (onSync != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.sync, color: textColor),
                    tooltip: 'Sinkronisasi Bulan Ini',
                    onPressed: isSyncing ? null : onSync,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
