// ====================================
// App Router — GoRouter Configuration
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/presensi/presensi_screen.dart';
import '../screens/riwayat/riwayat_screen.dart';
import '../screens/rekap/rekap_screen.dart';
import '../screens/profil/profil_screen.dart';
import '../screens/absen/absen_screen.dart';
import '../screens/absen/absen_form_screen.dart';
import '../screens/pengaturan/ubah_password_screen.dart';
import '../screens/pengaturan/ubah_email_screen.dart';
import '../screens/pengaturan/perangkat_screen.dart';
import '../screens/pengaturan/sesi_aktif_screen.dart';
import '../screens/profil/data_kepegawaian_screen.dart';
import '../screens/profil/zona_presensi_screen.dart';
import '../screens/profil/keamanan_akun_screen.dart';
import '../screens/profil/sinkronisasi_screen.dart';
import '../screens/auth/lupa_password_screen.dart';
import '../widgets/app_shell.dart';
import '../../services/auth_service.dart';
import '../../data/models/presensi_absen.dart';
import '../../data/remote/api_client.dart' as remote;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/presensi',
  redirect: (context, state) async {
    final hasSession = await AuthService.hasValidSession();
    final isLoginRoute = state.matchedLocation == '/login';
    final isLupaPasswordRoute = state.matchedLocation == '/lupa-password';

    // Rute publik yang boleh diakses tanpa login
    final isPublicRoute = isLoginRoute || isLupaPasswordRoute;

    if (!hasSession && !isPublicRoute) return '/login';
    if (hasSession && isLoginRoute) return '/presensi';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/absen/form',
      builder: (context, state) {
        final initialAbsen = state.extra as List<PresensiAbsen>?;
        return AbsenFormScreen(initialAbsenList: initialAbsen);
      },
    ),
    GoRoute(
      path: '/ubah-password',
      builder: (context, state) => const UbahPasswordScreen(),
    ),
    GoRoute(
      path: '/ubah-email',
      builder: (context, state) => const UbahEmailScreen(),
    ),
    GoRoute(
      path: '/lupa-password',
      builder: (context, state) => const LupaPasswordScreen(),
    ),
    GoRoute(
      path: '/perangkat',
      builder: (context, state) => const PerangkatScreen(),
    ),
    GoRoute(
      path: '/sesi-aktif',
      builder: (context, state) => const SesiAktifScreen(),
    ),
    GoRoute(
      path: '/profil/data-kepegawaian',
      builder: (context, state) => const DataKepegawaianScreen(),
    ),
    GoRoute(
      path: '/profil/zona-presensi',
      builder: (context, state) => const ZonaPresensiScreen(),
    ),
    GoRoute(
      path: '/profil/keamanan-akun',
      builder: (context, state) => const KeamananAkunScreen(),
    ),
    GoRoute(
      path: '/profil/sinkronisasi',
      builder: (context, state) => const SinkronisasiScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/presensi',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PresensiScreen(),
          ),
        ),
        GoRoute(
          path: '/riwayat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RiwayatScreen(),
          ),
        ),
        GoRoute(
          path: '/rekap',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RekapScreen(),
          ),
        ),
        GoRoute(
          path: '/absen',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AbsenScreen(),
          ),
        ),
        GoRoute(
          path: '/profil',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilScreen(),
          ),
        ),
      ],
    ),
  ],
);

void setupUnauthenticatedListener() {
  remote.onUnauthenticated = () {
    AuthService.forceClearLocalSession();
    appRouter.go('/login');
  };
}
