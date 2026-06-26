// ====================================
// Date Formatting Utilities — Zona Waktu WITA
// ====================================

import 'package:intl/intl.dart';

/// Memformat Date ke format tanggal Indonesia lengkap dengan hari.
/// Contoh: Kamis, 25 Juni 2026
String formatDate(DateTime date) {
  // Konversi ke WITA (UTC+8)
  final wita = date.toUtc().add(const Duration(hours: 8));
  return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(wita);
}

/// Memformat Date ke format waktu HH:mm.
/// Contoh: 08:30
String formatTime(DateTime date) {
  final wita = date.toUtc().add(const Duration(hours: 8));
  return DateFormat('HH:mm', 'id_ID').format(wita);
}

/// Memformat Date ke format waktu lengkap HH:mm:ss.
/// Contoh: 08:30:15
String formatTimeWithSeconds(DateTime date) {
  final wita = date.toUtc().add(const Duration(hours: 8));
  return DateFormat('HH:mm:ss', 'id_ID').format(wita);
}
