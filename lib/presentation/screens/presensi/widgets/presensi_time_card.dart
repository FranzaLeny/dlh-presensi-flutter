import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;

class PresensiTimeCard extends StatelessWidget {
  final DateTime currentTime;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;

  const PresensiTimeCard({
    super.key,
    required this.currentTime,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Side Card: Time (Jam, Menit)
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.2 : 0.05,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date_utils.formatTime(currentTime).split(':')[0],
                  style: TextStyle(
                    fontFamily: 'Digital7',
                    fontWeight: FontWeight.bold,
                    fontSize: 72,
                    color: isDark ? const Color(0xFF00E676) : const Color(0xFF1B5E20),
                    height: 0.9,
                  ),
                ),
                Text(
                  date_utils.formatTime(currentTime).split(':')[1],
                  style: TextStyle(
                    fontFamily: 'Digital7',
                    fontWeight: FontWeight.bold,
                    fontSize: 72,
                    color: isDark ? const Color(0xFF00E676) : const Color(0xFF1B5E20),
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Side Card: Date
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.2 : 0.05,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      date_utils.formatDate(currentTime).split(',')[0],
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.0,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      date_utils.formatDate(currentTime).split(',').length > 1
                          ? date_utils.formatDate(currentTime).split(',')[1].trim()
                          : '',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      'Waktu Indonesia Tengah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
