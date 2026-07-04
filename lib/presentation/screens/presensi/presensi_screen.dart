// ====================================
// Presensi Screen — Absen Masuk / Pulang
// ====================================

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/status.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/error_utils.dart';
import '../../../core/utils/uuid_utils.dart';
import '../../../data/local/presensi_dao.dart';
import '../../../data/local/settings_dao.dart';
import '../../../data/models/pengaturan_presensi.dart';
import '../../../data/models/presensi_log.dart';
import '../../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../services/camera_service.dart';
import '../../../services/sync_engine.dart';
import '../../../services/time_service.dart';
import '../../widgets/timeline_widget.dart';

class PresensiScreen extends ConsumerStatefulWidget {
  const PresensiScreen({super.key});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen> with WidgetsBindingObserver {
  DateTime _currentTime = DateTime.now();
  PengaturanPresensi? _pengaturan;
  List<PresensiLog> _todayLogs = [];
  bool _loading = false;
  bool _showCamera = false;
  TipePresensi _cameraJenis = TipePresensi.masuk;
  bool _timeMismatch = false;
  bool _retryingTime = false;
  Timer? _timer;
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isFaceDetected = false;
  bool _isDetecting = false;
  int _frameCount = 0;

  PresensiLog? get _masukLog =>
      _todayLogs.where((l) => l.tipe == TipePresensi.masuk).firstOrNull;
  PresensiLog? get _mulaiIstirahatLog => _todayLogs
      .where((l) => l.tipe == TipePresensi.mulaiIstirahat)
      .firstOrNull;
  PresensiLog? get _selesaiIstirahatLog => _todayLogs
      .where((l) => l.tipe == TipePresensi.selesaiIstirahat)
      .firstOrNull;
  PresensiLog? get _pulangLog =>
      _todayLogs.where((l) => l.tipe == TipePresensi.pulang).firstOrNull;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _startTimer();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_cameraController?.value.isStreamingImages == true) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      TimeService.resetSessionReference();
      _loadData();
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.locationWhenInUse].request();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final est = await TimeService.getEstimatedServerTime();
        if (!mounted) return;
        setState(() => _currentTime = est);

        final drift =
            (DateTime.now().millisecondsSinceEpoch - est.millisecondsSinceEpoch)
                .abs();
        setState(() => _timeMismatch = drift > 60000);
      } catch (_) {
        if (mounted) {
          setState(() {
            _timeMismatch = true;
            _currentTime = DateTime.now();
          });
        }
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await TimeService.syncTime();

      var settings = await SettingsDao.getFirst();
      if (settings == null) {
        final pegawai = await AuthService.getPegawai();
        if (pegawai?.skpdId != null) {
          await syncSettings(skpdId: pegawai!.skpdId);
          settings = await SettingsDao.getFirst();
        }
      }
      _pengaturan = settings;

      // Load log hari ini
      var today = TimeService.getUTC8DateString(DateTime.now());
      try {
        final serverTime = await TimeService.getEstimatedServerTime();
        today = TimeService.getUTC8DateString(serverTime);
      } catch (_) {}

      final pegawai = await AuthService.getPegawai();
      final pegawaiId = pegawai?.id ?? 'unknown';
      var logs = await PresensiDao.getByDate(pegawaiId, today);

      if (mounted) {
        setState(() {
          _todayLogs = logs;
          _loading = false; // We can show the old data while syncing
        });
      }

      // Sync dengan server untuk hari ini (dan seluruh bulan) secara background
      final now = DateTime.now();
      try {
        await syncLogsBulanan(now.year, now.month);
        logs = await PresensiDao.getByDate(pegawaiId, today);
        if (mounted) {
          setState(() {
            _todayLogs = logs;
          });
        }
      } catch (_) {}

      // Auto-check geofence
      if (_pengaturan != null) {
        ref.read(geofenceProvider.notifier).checkGeofence(_pengaturan!);
      }
    } catch (err) {
      if (mounted) {
        setState(() => _loading = false);
        _showAlert('Error Memuat Data', 'Gagal memuat data: ${getErrorMessage(err)}');
      }
    }
  }

  Future<void> _handleAbsen(TipePresensi jenis) async {
    if (_pengaturan == null) {
      _showAlert(
        'Error',
        'Pengaturan presensi belum dimuat. Pastikan data telah disinkronisasi.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref
          .read(geofenceProvider.notifier)
          .checkGeofence(_pengaturan!);

      if (result == null) {
        _showAlert('Error', 'Gagal mendapatkan lokasi. Pastikan GPS aktif.');
        return;
      }

      if (!result.isInRadius) {
        // Di luar radius — perlu selfie
        await _initCamera();
        setState(() {
          _cameraJenis = jenis;
          _showCamera = true;
        });
        return;
      }

      // Dalam radius — langsung simpan
      await _savePresensi(
        jenis,
        result.coordinates.latitude,
        result.coordinates.longitude,
        false,
      );
    } catch (err) {
      final message = getErrorMessage(err);
      _showAlert('Error', message.isNotEmpty ? message : 'Terjadi kesalahan');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showAlert(
        'Error',
        'Izin kamera ditolak. Aktifkan izin kamera untuk presensi luar radius.',
      );
      if (mounted) setState(() => _showCamera = false);
      return;
    }

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await _cameraController!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableTracking: false,
        enableClassification: false,
        enableContours: false,
        enableLandmarks: false,
      ),
    );

    _frameCount = 0;
    _isFaceDetected = false;
    _isDetecting = false;

    await _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _frameCount++;
      if (_frameCount % 5 != 0) return;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_faceDetector == null || _cameraController == null || !mounted) return;
    _isDetecting = true;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(
            _cameraController!.description.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          (Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888);

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _faceDetector!.processImage(inputImage);

      final hasFace = faces.length == 1;

      if (mounted && _isFaceDetected != hasFace) {
        setState(() {
          _isFaceDetected = hasFace;
        });
      }
    } catch (_) {
    } finally {
      _isDetecting = false;
    }
  }

  bool _isTakingPicture = false;

  Future<void> _handleTakeSelfie() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (!_isFaceDetected) {
      _showAlert(
        'Perhatian',
        'Wajah tidak terdeteksi atau terdapat lebih dari satu wajah. Pastikan wajah Anda terlihat jelas dalam bingkai kamera.',
      );
      return;
    }

    if (_isTakingPicture) return;
    _isTakingPicture = true;

    setState(() => _loading = true);

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        // Beri waktu sedikit agar sistem kamera Android mereset state dari streaming menjadi idle
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final photo = await _cameraController!.takePicture();
      final savedPath = await CameraService.saveSelfie(
        photo.path,
        _cameraJenis.toDbString(),
      );

      setState(() => _showCamera = false);
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController?.stopImageStream();
      }
      _cameraController?.dispose();
      _cameraController = null;
      _faceDetector?.close();
      _faceDetector = null;

      final geoState = ref.read(geofenceProvider);
      if (geoState.result != null) {
        await _savePresensi(
          _cameraJenis,
          geoState.result!.coordinates.latitude,
          geoState.result!.coordinates.longitude,
          true,
          fotoPath: savedPath,
        );
      }
    } catch (e) {
      _showAlert('Error', 'Gagal mengambil foto selfie: ${getErrorMessage(e)}');
    } finally {
      _isTakingPicture = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePresensi(
    TipePresensi jenis,
    double lat,
    double lon,
    bool isLuarRadius, {
    String? fotoPath,
  }) async {
    final pegawai = await AuthService.getPegawai();
    if (pegawai?.id == null) {
      _showAlert('Error', 'Data pegawai belum tersedia');
      return;
    }
    if (_pengaturan?.id == null) {
      _showAlert('Error', 'Pengaturan presensi tidak ditemukan');
      return;
    }

    DateTime nowDb;
    try {
      nowDb = await TimeService.getEstimatedServerTime();
    } catch (err) {
      _showAlert(
        'Presensi Ditolak',
        getErrorMessage(err).isNotEmpty
            ? getErrorMessage(err)
            : 'Terjadi manipulasi waktu perangkat.',
      );
      return;
    }

    final deviceTime = DateTime.now().millisecondsSinceEpoch;
    final diff = (deviceTime - nowDb.millisecondsSinceEpoch).abs();
    if (diff > 60000) {
      _showAlert(
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
      pengaturanId: _pengaturan!.id,
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
    _todayLogs = await PresensiDao.getByDate(pegawai.id, today);

    // Trigger sync push & pull untuk bulan ini (agar sinkron dengan server jika dihapus di server)
    final nowDateTime = DateTime.now();
    await syncLogsBulanan(
      nowDateTime.year,
      nowDateTime.month,
    ).catchError((_) => (synced: 0, errors: 0));

    _todayLogs = await PresensiDao.getByDate(pegawai.id, today);
    setState(() {});

    final timeFormatted = date_utils.formatTimeWithSeconds(nowDb);
    _showAlert(
      '✅ Berhasil',
      'Absen ${jenis.displayLabel} berhasil dicatat pada pukul $timeFormatted'
          '${isLuarRadius ? '\n\n⚠️ Lokasi terdeteksi diluar area kantor' : ''}',
    );
  }

  Future<void> _handleRetryTimeSync() async {
    setState(() => _retryingTime = true);
    try {
      await TimeService.syncTime();
      final est = await TimeService.getEstimatedServerTime();
      final drift =
          (DateTime.now().millisecondsSinceEpoch - est.millisecondsSinceEpoch)
              .abs();
      if (drift <= 60000) {
        setState(() => _timeMismatch = false);
      } else {
        _showAlert(
          'Waktu Masih Tidak Sesuai',
          'Silakan buka Pengaturan → Tanggal & Waktu → aktifkan "Atur waktu otomatis".',
        );
      }
    } catch (_) {
      _showAlert(
        'Gagal Sinkronisasi',
        'Pastikan Anda terhubung ke internet dan waktu perangkat sudah diatur otomatis.',
      );
    } finally {
      if (mounted) setState(() => _retryingTime = false);
    }
  }

  Future<void> _handleRedoPresensi() async {
    if (_todayLogs.isEmpty) return;

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

    setState(() => _loading = true);
    try {
      for (final log in _todayLogs) {
        if (!log.isSynced || log.status == Status.rejected) {
          await PresensiDao.delete(log.id);
        }
      }
      await _loadData();
      _showAlert(
        'Berhasil',
        'Data presensi hari ini yang belum disingkron berhasil dihapus.',
      );
    } catch (_) {
      _showAlert('Error', 'Gagal mereset data presensi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAlert(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final geoState = ref.watch(geofenceProvider);

    // Camera view
    if (_showCamera) {
      return _buildCameraView();
    }

    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Time & Date Cards ──────────────────────────
                    IntrinsicHeight(
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
                                  date_utils
                                      .formatTime(_currentTime)
                                      .split(':')[0],
                                  style: TextStyle(
                                    fontFamily: 'Digital7',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 72,
                                    color: isDark ? const Color(0xFF00E676) : const Color(0xFF1B5E20),
                                    height: 0.9,
                                  ),
                                ),
                                Text(
                                  date_utils
                                      .formatTime(_currentTime)
                                      .split(':')[1],
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
                                      'Waktu Indonesia Tengah',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      date_utils
                                                  .formatDate(_currentTime)
                                                  .split(',')
                                                  .length >
                                              1
                                          ? date_utils
                                                .formatDate(_currentTime)
                                                .split(',')[1]
                                                .trim()
                                          : '',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      date_utils
                                          .formatDate(_currentTime)
                                          .split(',')[0],
                                      style: TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                        height: 1.0,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Action Buttons ─────────────────────────────
                    _buildActionButtons(cardBg, textColor, subtextColor),
                    const SizedBox(height: 12),

                    // ── Geofence Info ──────────────────────────────
                    if (_pengaturan != null)
                      _buildGeofenceCard(
                        geoState,
                        cardBg,
                        textColor,
                        subtextColor,
                      ),
                    const SizedBox(height: 12),

                    // ── Timeline ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timeline Presensi Hari Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TimelineWidget(
                            masukLog: _masukLog,
                            mulaiIstirahatLog: _mulaiIstirahatLog,
                            selesaiIstirahatLog: _selesaiIstirahatLog,
                            pulangLog: _pulangLog,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // ── Time Mismatch Modal ─────────────────────────────
          if (_timeMismatch) _buildTimeMismatchOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    if (_masukLog != null &&
        _mulaiIstirahatLog != null &&
        _selesaiIstirahatLog != null &&
        _pulangLog != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('✅', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  'Presensi Lengkap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anda sudah absen masuk, istirahat, dan pulang hari ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: subtextColor),
                ),
              ],
            ),
          ),
          if (_todayLogs.any((l) => !l.isSynced || l.status == Status.rejected))
            _buildRedoButton(),
        ],
      );
    }

    Widget? actionButton;
    if (_masukLog == null) {
      actionButton = _buildAbsenButton(
        jenis: TipePresensi.masuk,
        color: AppColors.absenMasuk,
        emoji: '👋',
        label: 'Absen Masuk',
        sublabel: 'Tap untuk absen masuk',
      );
    } else if (_mulaiIstirahatLog == null) {
      actionButton = _buildAbsenButton(
        jenis: TipePresensi.mulaiIstirahat,
        color: AppColors.absenIstirahatMulai,
        emoji: '☕',
        label: 'Mulai Istirahat',
        sublabel: 'Tap untuk absen keluar istirahat',
      );
    } else if (_selesaiIstirahatLog == null) {
      actionButton = _buildAbsenButton(
        jenis: TipePresensi.selesaiIstirahat,
        color: AppColors.absenIstirahatSelesai,
        emoji: '🏃',
        label: 'Selesai Istirahat',
        sublabel: 'Tap untuk absen masuk istirahat',
      );
    } else if (_pulangLog == null) {
      actionButton = _buildAbsenButton(
        jenis: TipePresensi.pulang,
        color: AppColors.absenPulang,
        emoji: '🏠',
        label: 'Absen Pulang',
        sublabel: 'Tap untuk absen pulang',
      );
    }

    return Column(
      children: [
        ?actionButton,
        if (_todayLogs.any((l) => !l.isSynced || l.status == Status.rejected))
          _buildRedoButton(),
      ],
    );
  }

  Widget _buildAbsenButton({
    required TipePresensi jenis,
    required Color color,
    required String emoji,
    required String label,
    required String sublabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);

    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(sublabel, style: TextStyle(color: subtextColor, fontSize: 14)),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _loading ? null : () => _handleAbsen(jenis),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: _loading
                ? Center(child: CircularProgressIndicator(color: color))
                : Center(
                    child: Icon(Icons.fingerprint, size: 80, color: color),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedoButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextButton(
        onPressed: _loading ? null : _handleRedoPresensi,
        child: const Text(
          '🗑️ Hapus Absen Hari Ini',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildGeofenceCard(
    GeofenceState geoState,
    Color cardBg,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Info Lokasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.primary,
                onPressed: _loading
                    ? null
                    : () => ref
                          .read(geofenceProvider.notifier)
                          .checkGeofence(_pengaturan!, force: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (geoState.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (geoState.error != null)
            Text(
              geoState.error!.replaceFirst('Exception: ', ''),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (geoState.result != null) ...[
            Text(
              'Jarak ke kantor: ${geoState.result!.distance >= 1000 ? '${(geoState.result!.distance / 1000).toStringAsFixed(1)} km' : '${geoState.result!.distance} m'}',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
            const SizedBox(height: 4),
            Text(
              geoState.result!.isInRadius
                  ? 'Lokasi dalam area kantor'
                  : 'Lokasi terdeteksi diluar area kantor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: geoState.result!.isInRadius
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ] else
            Text(
              'Lokasi belum diperiksa.',
              style: TextStyle(fontSize: 14, color: subtextColor),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeMismatchOverlay(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2B3E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'Perbedaan Waktu Terdeteksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Waktu perangkat Anda tidak sesuai dengan waktu server. Silakan atur waktu HP Anda ke otomatis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retryingTime ? null : _handleRetryTimeSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _retryingTime
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Cek Ulang Waktu'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  Text(
                    'Ambil foto selfie untuk presensi ${_cameraJenis.displayLabel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isFaceDetected
                          ? AppColors.success.withValues(alpha: 0.8)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFaceDetected
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isFaceDetected
                              ? 'Wajah Terdeteksi'
                              : 'Wajah tidak terdeteksi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          setState(() => _showCamera = false);
                          if (_cameraController?.value.isStreamingImages ==
                              true) {
                            await _cameraController?.stopImageStream();
                          }
                          _cameraController?.dispose();
                          _cameraController = null;
                          _faceDetector?.close();
                          _faceDetector = null;
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : _handleTakeSelfie,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isFaceDetected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
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
