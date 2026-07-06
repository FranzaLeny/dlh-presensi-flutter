// ====================================
// Providers — Riverpod State Management
// ====================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/presensi_dao.dart';
import '../data/models/pegawai.dart';
import '../data/models/sync_response.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/sync_engine.dart';
import '../data/models/pengaturan_presensi.dart';
import '../core/utils/error_utils.dart';

// ── Pegawai Provider ─────────────────────────────────────────────────

final pegawaiProvider = FutureProvider<Pegawai?>((ref) async {
  return AuthService.getPegawai();
});

// ── Geofence Provider ────────────────────────────────────────────────

class GeofenceState {
  final GeofenceResult? result;
  final bool loading;
  final String? error;

  const GeofenceState({this.result, this.loading = false, this.error});

  GeofenceState copyWith({
    GeofenceResult? result,
    bool? loading,
    String? error,
  }) {
    return GeofenceState(
      result: result ?? this.result,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class GeofenceNotifier extends Notifier<GeofenceState> {
  @override
  GeofenceState build() => const GeofenceState();

  // Cache
  int _cacheLastCheckTime = 0;
  GeofenceResult? _cacheLastResult;
  double _cacheLastLat = 0;
  double _cacheLastLon = 0;
  int _cacheLastRadius = 0;
  static const _cacheDurationMs = 15 * 60 * 1000; // 15 menit

  Future<GeofenceResult?> checkGeofence(
    PengaturanPresensi pengaturan, {
    bool force = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isSettingsSame = _cacheLastLat == pengaturan.latitude &&
        _cacheLastLon == pengaturan.longitude &&
        _cacheLastRadius == pengaturan.radius;

    if (!force &&
        isSettingsSame &&
        _cacheLastResult != null &&
        now - _cacheLastCheckTime < _cacheDurationMs) {
      state = GeofenceState(result: _cacheLastResult);
      return _cacheLastResult;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      final result = await LocationService.checkGeofence(
        pengaturan.latitude,
        pengaturan.longitude,
        pengaturan.radius,
      );

      _cacheLastCheckTime = now;
      _cacheLastResult = result;
      _cacheLastLat = pengaturan.latitude;
      _cacheLastLon = pengaturan.longitude;
      _cacheLastRadius = pengaturan.radius;

      state = GeofenceState(result: result);
      return result;
    } catch (e) {
      state = GeofenceState(
        error: getErrorMessage(e),
      );
      return null;
    }
  }
}

final geofenceProvider =
    NotifierProvider<GeofenceNotifier, GeofenceState>(GeofenceNotifier.new);

// ── Sync Provider ────────────────────────────────────────────────────

class SyncStatusNotifier extends Notifier<SyncStatus> {
  Timer? _refreshTimer;
  StreamSubscription? _connectivitySubscription;

  @override
  SyncStatus build() {
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _connectivitySubscription?.cancel();
    });

    _startAutoRefresh();
    _startAutoSync();
    
    return const SyncStatus();
  }

  void _startAutoRefresh() {
    refreshStatus();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshStatus(),
    );
  }

  void _startAutoSync() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        // Delay sedikit untuk memastikan koneksi stabil
        Future.delayed(const Duration(seconds: 2), () {
          _runSync();
        });
      }
    });

    // Initial sync
    _runSync();
  }

  Future<void> _runSync() async {
    try {
      final pegawai = await AuthService.getPegawai();
      final skpdId = pegawai?.skpdId;
      await runFullSync(skpdId: skpdId);
      await refreshStatus();
    } catch (_) {}
  }

  Future<void> refreshStatus() async {
    final pendingCount = await PresensiDao.countUnsynced();
    state = state.copyWith(
      pendingCount: pendingCount,
      isRunning: isSyncRunning(),
    );
  }

  Future<({int synced, int errors})> triggerSync() async {
    state = state.copyWith(isRunning: true);
    try {
      final pegawai = await AuthService.getPegawai();
      final skpdId = pegawai?.skpdId;
      final result = await runFullSync(skpdId: skpdId);
      final pendingCount = await PresensiDao.countUnsynced();
      state = SyncStatus(
        pendingCount: pendingCount,
        isRunning: false,
        lastSyncAt: DateTime.now().toIso8601String(),
        lastError:
            result.errors > 0 ? '${result.errors} data gagal disinkronkan' : null,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        lastError: getErrorMessage(e),
      );
      return (synced: 0, errors: 1);
    }
  }

}

final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);
