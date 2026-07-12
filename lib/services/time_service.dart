// ====================================
// Time Service — Sinkronisasi & Deteksi Manipulasi Waktu
// ====================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/utils/error_utils.dart';
import '../data/remote/api_client.dart';

const _storage = FlutterSecureStorage();

// Monotonic clock — menggunakan Stopwatch (tidak bisa dimanipulasi user)
final _appStopwatch = Stopwatch()..start();
int _sessionStartDeviceTime = DateTime.now().millisecondsSinceEpoch;
int _sessionStartPerfTime = _appStopwatch.elapsedMilliseconds;

int? _lastSyncServerTime;
int? _lastSyncPerfTime;
int? _cachedLastKnownTime;

class TimeService {
  TimeService._();

  /// Reset referensi sesi untuk menghindari sleep drift saat layar mati
  static void resetSessionReference() {
    _sessionStartDeviceTime = DateTime.now().millisecondsSinceEpoch;
    _sessionStartPerfTime = _appStopwatch.elapsedMilliseconds;
  }

  /// Mendapatkan waktu monotonic (ms) — equivalent ke performance.now() di JS
  static double _perfNow() => _appStopwatch.elapsedMilliseconds.toDouble();

  /// Sinkronisasi waktu dengan server menggunakan GET /server-time
  static Future<void> syncTime() async {
    try {
      final response = await apiClient.get('/server-time');
      final data = response.data;
      if (data['time'] != null) {
        final serverTimeMs =
            DateTime.parse(data['time'] as String).millisecondsSinceEpoch;
        final perfTime = _perfNow();
        final deviceTimeMs = DateTime.now().millisecondsSinceEpoch;

        // Simpan ke in-memory untuk session ini
        _lastSyncServerTime = serverTimeMs;
        _lastSyncPerfTime = perfTime.toInt();

        // Reset referensi sesi untuk mencegah sleep drift
        resetSessionReference();

        // Simpan ke SecureStore secara persistent
        await _storage.write(
            key: 'server_time_at_sync', value: serverTimeMs.toString());
        await _storage.write(
            key: 'perf_time_at_sync', value: perfTime.toInt().toString());
        await _storage.write(
            key: 'device_time_at_sync', value: deviceTimeMs.toString());

        // Update last known time
        await _updateLastKnownTime(serverTimeMs);
      }
    } catch (error) {
      // Log warning only
    }
  }

  /// Mengembalikan estimasi waktu server saat ini.
  /// Melakukan deteksi manipulasi waktu menggunakan Stopwatch dan drift.
  static Future<DateTime> getEstimatedServerTime() async {
    final nowPerf = _perfNow();
    final nowDevice = DateTime.now().millisecondsSinceEpoch;

    // 1. Deteksi manipulasi waktu dalam sesi
    final elapsedDevice = nowDevice - _sessionStartDeviceTime;
    final elapsedPerf = nowPerf.toInt() - _sessionStartPerfTime;
    if ((elapsedDevice - elapsedPerf).abs() > 15 * 60 * 1000) { // 15 menit
      throw Exception(
          'Manipulasi waktu terdeteksi! Waktu perangkat Anda diubah.');
    }

    // 2. Jika in-memory reference tersedia, gunakan rumus monotonic clock
    if (_lastSyncServerTime != null && _lastSyncPerfTime != null) {
      final estimatedMs =
          _lastSyncServerTime! + (nowPerf.toInt() - _lastSyncPerfTime!);
      await _updateLastKnownTime(estimatedMs);
      return DateTime.fromMillisecondsSinceEpoch(estimatedMs);
    }

    // 3. Jika in-memory null (baru restart), restore dari SecureStore
    try {
      final storedServer = await _storage.read(key: 'server_time_at_sync');
      final storedPerf = await _storage.read(key: 'perf_time_at_sync');
      final storedDevice = await _storage.read(key: 'device_time_at_sync');

      if (storedServer != null && storedPerf != null && storedDevice != null) {
        final sTime = int.parse(storedServer);
        final dTime = int.parse(storedDevice);

        final drift = sTime - dTime;
        final estimatedMs = nowDevice + drift;

        // Cegah waktu dimundurkan secara offline
        _cachedLastKnownTime ??= int.tryParse(await _storage.read(key: 'last_known_time') ?? '');
        if (_cachedLastKnownTime != null) {
          if (estimatedMs < _cachedLastKnownTime! - 5000) {
            throw Exception(
                'Manipulasi waktu terdeteksi! Waktu perangkat Anda dimundurkan.');
          }
        }

        await _updateLastKnownTime(estimatedMs);
        return DateTime.fromMillisecondsSinceEpoch(estimatedMs);
      }
    } catch (err) {
      final msg = getErrorMessage(err);
      if (msg.contains('Manipulasi')) rethrow;
    }

    // 4. Fallback jika tidak ada data sama sekali
    await _updateLastKnownTime(nowDevice);
    return DateTime.fromMillisecondsSinceEpoch(nowDevice);
  }

  /// Menyimpan waktu terakhir yang diketahui secara persistent
  static Future<void> _updateLastKnownTime(int currentTimeMs) async {
    if (_cachedLastKnownTime != null && currentTimeMs <= _cachedLastKnownTime!) return;
    
    // Hanya simpan ke disk jika selisih > 1 menit untuk menghemat resource
    if (_cachedLastKnownTime == null || currentTimeMs - _cachedLastKnownTime! > 60000) {
      _cachedLastKnownTime = currentTimeMs;
      try {
        await _storage.write(key: 'last_known_time', value: currentTimeMs.toString());
      } catch (_) {}
    } else {
      _cachedLastKnownTime = currentTimeMs;
    }
  }

  /// Mendapatkan DateTime bayangan dalam zona waktu WITA (UTC+8).
  /// PENTING: Gunakan ini HANYA untuk mengambil komponen tanggal/waktu (.day, .weekday, dll).
  /// Jangan gunakan untuk selisih waktu karena nilainya sudah bergeser 8 jam secara absolut.
  static DateTime getWITA(DateTime date) {
    return date.toUtc().add(const Duration(hours: 8));
  }

  /// Mengonversi Date ke format tanggal lokal UTC+8 (YYYY-MM-DD)
  static String getUTC8DateString(DateTime date) {
    final utc8Time = getWITA(date);
    final y = utc8Time.year.toString();
    final m = utc8Time.month.toString().padLeft(2, '0');
    final d = utc8Time.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Mengonversi Date ke string ISO dengan offset UTC+8
  static String getUTC8ISOString(DateTime date) {
    final utc8Time = getWITA(date);
    final y = utc8Time.year.toString();
    final mo = utc8Time.month.toString().padLeft(2, '0');
    final d = utc8Time.day.toString().padLeft(2, '0');
    final h = utc8Time.hour.toString().padLeft(2, '0');
    final mi = utc8Time.minute.toString().padLeft(2, '0');
    final s = utc8Time.second.toString().padLeft(2, '0');
    final ms = utc8Time.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-${d}T$h:$mi:$s.$ms+08:00';
  }
}
