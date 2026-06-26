// ====================================
// App Colors — Palet Warna Light & Dark
// ====================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors ─────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52E0);

  // ── Light Theme ──────────────────────────────────────────
  static const Color lightText = Color(0xFF000000);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightBackgroundElement = Color(0xFFF0F0F3);
  static const Color lightBackgroundSelected = Color(0xFFE0E1E6);
  static const Color lightTextSecondary = Color(0xFF60646C);
  static const Color lightSurface = Color(0xFFF5F5FA);

  // ── Dark Theme ───────────────────────────────────────────
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkBackgroundElement = Color(0xFF212225);
  static const Color darkBackgroundSelected = Color(0xFF2E3135);
  static const Color darkTextSecondary = Color(0xFFB0B4BA);
  static const Color darkSurface = Color(0xFF1A1B2E);

  // ── Gradient ─────────────────────────────────────────────
  static const List<Color> loginGradient = [
    Color(0xFF1A1B2E),
    Color(0xFF2D2B55),
    Color(0xFF1A1B2E),
  ];

  // ── Presensi Button Colors ───────────────────────────────
  static const Color absenMasuk = Color(0xFF4CAF50);
  static const Color absenIstirahatMulai = Color(0xFF00BCD4);
  static const Color absenIstirahatSelesai = Color(0xFF9C27B0);
  static const Color absenPulang = Color(0xFFFF9800);

  // ── Status Colors ────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5722);
  static const Color info = Color(0xFF2196F3);
}
