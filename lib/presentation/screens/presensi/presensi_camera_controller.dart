import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/models/presensi_log.dart';
import '../../../providers/providers.dart';
import '../../../services/camera_service.dart';
import 'presensi_screen.dart';

mixin PresensiCameraController on ConsumerState<PresensiScreen> {
  bool showCamera = false;
  TipePresensi cameraJenis = TipePresensi.masuk;
  CameraController? cameraController;
  FaceDetector? faceDetector;
  
  bool isFaceDetected = false;
  bool isTakingPicture = false;
  bool loading = false;
  
  bool isFaceDetectionEnabled = true;
  bool showBypassToggle = false;
  int failedDetectionFrames = 0; // Not strictly used for static image, but kept for UI compatibility if needed

  String? capturedPhotoPath;

  Future<void> savePresensi(
    TipePresensi jenis,
    double lat,
    double lon,
    bool isLuarRadius, {
    String? fotoPath,
  });

  Future<void> requestPermissions() async {
    await [Permission.camera, Permission.locationWhenInUse].request();
  }

  void showAlert(String title, String message) {
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

  Future<void> initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      showAlert(
        'Izin Kamera Ditolak',
        'Izin kamera ditolak. Silakan aktifkan izin kamera di pengaturan perangkat untuk melakukan presensi luar radius.',
      );
      if (mounted) setState(() => showCamera = false);
      return;
    }

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await cameraController!.initialize();

      faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableTracking: false,
          enableClassification: false,
          enableContours: false,
          enableLandmarks: false,
        ),
      );

      isFaceDetected = false;
      capturedPhotoPath = null;
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Init Camera Error: $e');
      showAlert(
        'Kamera Bermasalah',
        'Gagal mengakses kamera perangkat Anda. Silakan tutup aplikasi dan coba buka kembali.',
      );
      if (mounted) setState(() => showCamera = false);
    }
  }

  Future<void> handleTakeSelfie() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (isTakingPicture) return;
    isTakingPicture = true;

    setState(() {
      loading = true;
    });

    try {
      final photo = await cameraController!.takePicture();
      final path = photo.path;
      
      // Run static face detection
      final inputImage = InputImage.fromFilePath(path);
      final faces = await faceDetector!.processImage(inputImage);
      final hasFace = faces.length == 1;

      if (mounted) {
        setState(() {
          capturedPhotoPath = path;
          isFaceDetected = hasFace;
        });
      }
    } catch (e) {
      debugPrint('Take Selfie Error: $e');
      showAlert('Gagal Mengambil Foto', 'Mohon maaf, kamera gagal menangkap foto. Silakan pastikan memori penyimpanan Anda tidak penuh dan coba lagi.');
    } finally {
      isTakingPicture = false;
      if (mounted) setState(() => loading = false);
    }
  }

  void handleRetakePhoto() {
    setState(() {
      capturedPhotoPath = null;
      isFaceDetected = false;
    });
  }

  Future<void> handleSubmitPhoto() async {
    if (capturedPhotoPath == null) return;

    // TODO: Later we can uncomment this to strictly enforce face detection
    // if (isFaceDetectionEnabled && !isFaceDetected) {
    //   showAlert(
    //     'Perhatian',
    //     'Wajah tidak terdeteksi atau terdapat lebih dari satu wajah. Pastikan wajah Anda terlihat jelas dalam bingkai kamera.',
    //   );
    //   return;
    // }

    setState(() => loading = true);

    try {
      final geoState = ref.read(geofenceProvider);
      
      // Tambahkan watermark jika lokasi tersedia
      if (geoState.result != null) {
        await CameraService.addWatermarkToSelfie(
          capturedPhotoPath!,
          geoState.result!.coordinates.latitude,
          geoState.result!.coordinates.longitude,
          DateTime.now(),
        );
      }

      // Save selfie internally
      final savedPath = await CameraService.saveSelfie(
        capturedPhotoPath!,
        cameraJenis.toDbString(),
      );

      setState(() {
        showCamera = false;
        capturedPhotoPath = null;
      });
      
      cameraController?.dispose();
      cameraController = null;
      faceDetector?.close();
      faceDetector = null;

      if (geoState.result != null) {
        await savePresensi(
          cameraJenis,
          geoState.result!.coordinates.latitude,
          geoState.result!.coordinates.longitude,
          true,
          fotoPath: savedPath,
        );
      }
    } catch (e) {
      showAlert('Gagal Menyimpan', 'Terjadi kesalahan saat menyimpan presensi. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
