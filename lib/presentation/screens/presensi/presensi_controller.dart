// ====================================
// Presensi Controller mixin
// ====================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/uuid_utils.dart';
import '../../../data/local/absen_dao.dart';
import '../../../data/local/hari_libur_dao.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/local/settings_dao.dart';
import '../../../data/models/pegawai.dart';
import '../../../data/models/pengaturan_presensi.dart';
import '../../../data/models/presensi_absen.dart';
import '../../../data/models/presensi_log.dart';
import '../../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_engine.dart';
import '../../../services/time_service.dart';
import 'presensi_camera_controller.dart';
import 'presensi_screen.dart';

mixin PresensiController
    on ConsumerState<PresensiScreen>, PresensiCameraController {
  DateTime currentTime = DateTime.now();
  Pegawai? pegawaiData;
  PengaturanPresensi? pengaturan;
  List<PresensiLog> todayLogs = [];
  PresensiAbsen? approvedAbsence;
  bool isTodayLibur = false;
  String? liburNama;
  bool timeMismatch = false;
  bool retryingTime = false;
  Timer? timer;

  PresensiLog? get masukLog =>
      todayLogs.where((l) => l.tipe == TipePresensi.masuk).firstOrNull;
  PresensiLog? get mulaiIstirahatLog =>
      todayLogs.where((l) => l.tipe == TipePresensi.mulaiIstirahat).firstOrNull;
  PresensiLog? get selesaiIstirahatLog => todayLogs
      .where((l) => l.tipe == TipePresensi.selesaiIstirahat)
      .firstOrNull;
  PresensiLog? get pulangLog =>
      todayLogs.where((l) => l.tipe == TipePresensi.pulang).firstOrNull;

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final est = await TimeService.getEstimatedServerTime();
        if (!mounted) return;
        final drift =
            (DateTime.now().millisecondsSinceEpoch - est.millisecondsSinceEpoch)
                .abs();
        setState(() {
          currentTime = est;
          timeMismatch = drift > 60000;
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            timeMismatch = true;
            currentTime = DateTime.now();
          });
        }
      }
    });
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      // Fast Local Load
      final pegawai = await AuthService.getPegawai();
      if (pegawai == null) return;
      pegawaiData = pegawai;
      final pegawaiId = pegawai.id;

      var settings = await SettingsDao.getFirst();
      pengaturan = settings;

      final serverTime = await TimeService.getEstimatedServerTime().catchError(
        (_) => DateTime.now(),
      );
      final today = TimeService.getUTC8DateString(serverTime);

      final logs = await PresensiDao.getByDate(pegawaiId, today);
      final todayAbsences = await AbsenDao.getByDate(today);
      final activeAbsence = todayAbsences
          .where((a) => a.status == Status.approved || a.status == 20)
          .firstOrNull;

      final holiday = await HariLiburDao.getByDate(today);
      final holidayInfo = _resolveHoliday(holiday, settings, today);

      if (mounted) {
        setState(() {
          todayLogs = logs;
          approvedAbsence = activeAbsence;
          isTodayLibur = holidayInfo.isLibur;
          liburNama = holidayInfo.nama;
          loading = false;
        });
      }

      // Background Sync
      try {
        await TimeService.syncTime();
        await syncSettings(skpdId: pegawai.skpdId);
        final now = DateTime.now();
        await syncLogsBulanan(now.year, now.month);

        final freshSettings = await SettingsDao.getFirst();
        final freshLogs = await PresensiDao.getByDate(pegawaiId, today);
        final freshAbsences = await AbsenDao.getByDate(today);
        final freshActiveAbsence = freshAbsences
            .where((a) => a.status == Status.approved || a.status == 20)
            .firstOrNull;
        final freshHoliday = await HariLiburDao.getByDate(today);
        final freshHolidayInfo = _resolveHoliday(
          freshHoliday,
          freshSettings,
          today,
        );

        if (mounted) {
          setState(() {
            pengaturan = freshSettings;
            todayLogs = freshLogs;
            approvedAbsence = freshActiveAbsence;
            isTodayLibur = freshHolidayInfo.isLibur;
            liburNama = freshHolidayInfo.nama;
          });
        }
      } catch (_) {}

      if (pengaturan != null) {
        ref.read(geofenceProvider.notifier).checkGeofence(pengaturan!);
      }
    } catch (err) {
      if (mounted) {
        setState(() => loading = false);
        showAlert('Gagal Memuat Data', getErrorMessage(err));
      }
    }
  }

  ({bool isLibur, String? nama}) _resolveHoliday(
    dynamic holiday,
    PengaturanPresensi? pengaturan,
    String today,
  ) {
    final parsedDate = DateTime.tryParse(today) ?? DateTime.now();
    final dayOfWeek = parsedDate.weekday;
    final dayOfWeekIndex = dayOfWeek % 7;
    final override = pengaturan?.jadwalHarian
        ?.where((j) => j.hari == dayOfWeekIndex)
        .firstOrNull;

    if (holiday != null) {
      return (isLibur: true, nama: holiday.nama);
    } else if (override != null) {
      if (override.isLibur == 1) {
        return (isLibur: true, nama: 'Libur Hari ${_getNamaHari(dayOfWeek)}');
      }
      return (isLibur: false, nama: null);
    } else {
      final isWeekend =
          dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday;
      if (isWeekend) {
        return (isLibur: true, nama: 'Libur Hari ${_getNamaHari(dayOfWeek)}');
      }
      return (isLibur: false, nama: null);
    }
  }

  Future<void> handleAbsen(TipePresensi jenis) async {
    if (pengaturan == null) {
      showAlert(
        'Pengaturan Belum Sinkron',
        'Pengaturan presensi belum dimuat. Silakan lakukan sinkronisasi data terlebih dahulu.',
      );
      return;
    }
    setState(() => loading = true);
    try {
      final result = await ref
          .read(geofenceProvider.notifier)
          .checkGeofence(pengaturan!);
      if (result == null) {
        showAlert(
          'Gagal Mendapatkan Lokasi',
          'Pastikan GPS perangkat Anda aktif dan izin lokasi telah diberikan.',
        );
        return;
      }
      if (!result.isInRadius) {
        await initCamera();
        setState(() {
          cameraJenis = jenis;
          showCamera = true;
        });
        return;
      }
      await savePresensi(
        jenis,
        result.coordinates.latitude,
        result.coordinates.longitude,
        false,
      );
    } catch (err) {
      showAlert('Gagal Presensi', getErrorMessage(err));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Future<void> savePresensi(
    TipePresensi jenis,
    double lat,
    double lon,
    bool isLuarRadius, {
    String? fotoPath,
  }) async {
    final pegawai = await AuthService.getPegawai();
    if (pegawai?.id == null || pengaturan?.id == null) {
      showAlert(
        'Data Tidak Ditemukan',
        'Data pegawai atau pengaturan presensi tidak ditemukan di lokal.',
      );
      return;
    }
    DateTime nowDb;
    try {
      nowDb = await TimeService.getEstimatedServerTime();
    } catch (err) {
      showAlert('Presensi Ditolak', getErrorMessage(err));
      return;
    }
    final deviceTime = DateTime.now().millisecondsSinceEpoch;
    final diff = (deviceTime - nowDb.millisecondsSinceEpoch).abs();
    if (diff > 60000) {
      showAlert(
        'Perbedaan Waktu Terdeteksi',
        'Waktu HP Anda tidak sesuai dengan server. Silakan atur waktu HP Anda ke otomatis.',
      );
      return;
    }
    final today = TimeService.getUTC8DateString(nowDb);
    final now = TimeService.getUTC8ISOString(nowDb);
    final newLog = PresensiLog(
      id: uuidv7(),
      pegawaiId: pegawai!.id,
      pengaturanId: pengaturan!.id,
      tanggal: today,
      tipe: jenis,
      waktu: now,
      latitude: lat,
      longitude: lon,
      fotoPath: fotoPath,
      isLuarRadius: isLuarRadius ? 1 : 0,
      status: Status.pending,
      isSynced: false,
    );
    await PresensiDao.create(newLog);
    todayLogs = await PresensiDao.getByDate(pegawai.id, today);
    final nowDateTime = DateTime.now();
    await syncLogsBulanan(
      nowDateTime.year,
      nowDateTime.month,
    ).catchError((_) => (synced: 0, errors: 0));
    todayLogs = await PresensiDao.getByDate(pegawai.id, today);
    setState(() {});
    final timeFormatted = date_utils.formatTimeWithSeconds(nowDb);
    showAlert(
      '✅ Berhasil',
      'Presensi ${jenis.displayLabel} berhasil dicatat pada pukul $timeFormatted${isLuarRadius ? '\n\n⚠️ Lokasi terdeteksi diluar area kantor' : ''}',
    );
  }

  Future<void> handleRetryTimeSync() async {
    setState(() => retryingTime = true);
    try {
      await TimeService.syncTime();
      final est = await TimeService.getEstimatedServerTime();
      final drift =
          (DateTime.now().millisecondsSinceEpoch - est.millisecondsSinceEpoch)
              .abs();
      if (drift <= 60000) {
        setState(() => timeMismatch = false);
      } else {
        showAlert(
          'Waktu Masih Tidak Sesuai',
          'Silakan buka Pengaturan → Tanggal & Waktu → aktifkan "Atur waktu otomatis".',
        );
      }
    } catch (_) {
      showAlert(
        'Gagal Sinkronisasi',
        'Pastikan Anda terhubung ke internet dan waktu perangkat sudah diatur otomatis.',
      );
    } finally {
      if (mounted) setState(() => retryingTime = false);
    }
  }

  Future<void> handleRedoPresensi() async {
    if (todayLogs.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Absen'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data presensi hari ini yang belum disingkron?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => loading = true);
    try {
      for (final log in todayLogs) {
        if (!log.isSynced || log.status == Status.rejected) {
          await PresensiDao.delete(log.id);
        }
      }
      await loadData();
      showAlert(
        'Berhasil',
        'Data presensi hari ini yang belum disingkron berhasil dihapus.',
      );
    } catch (_) {
      showAlert('Gagal Reset', 'Gagal menghapus data presensi lokal.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _getNamaHari(int weekday) {
    switch (weekday) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return '';
    }
  }
}
