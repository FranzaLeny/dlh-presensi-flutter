// ====================================
// Main — App Entry Point
// ====================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_theme.dart';
import 'data/local/database.dart';
import 'presentation/router/app_router.dart';

import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isMissingEnv) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'ERROR: Konfigurasi API_URL atau BETTER_AUTH_URL tidak ditemukan. Harap pastikan secrets sudah diatur dan disuntikkan via dart-define saat build.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // Inisialisasi locale Indonesia untuk formatting tanggal
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi database SQLite
  await initDatabase();

  setupUnauthenticatedListener();

  runApp(
    const ProviderScope(
      child: PresensiApp(),
    ),
  );
}

class PresensiApp extends StatelessWidget {
  const PresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DigiLH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
