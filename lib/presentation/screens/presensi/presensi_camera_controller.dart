import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool isDetecting = false;
  int frameCount = 0;
  bool isTakingPicture = false;
  bool loading = false;

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

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
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

    frameCount = 0;
    isFaceDetected = false;
    isDetecting = false;

    await cameraController!.startImageStream((CameraImage image) {
      if (isDetecting) return;
      frameCount++;
      if (frameCount % 5 != 0) return;
      processCameraImage(image);
    });
  }

  Future<void> processCameraImage(CameraImage image) async {
    if (faceDetector == null || cameraController == null || !mounted) return;
    isDetecting = true;

    try {
      Uint8List bytes;
      if (Platform.isAndroid && image.format.raw == 35) {
        bytes = _yuv420ToNv21(image);
      } else {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
      }

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };

      int rotationCompensation = 0;
      final camera = cameraController!.description;
      if (Platform.isIOS) {
        rotationCompensation = camera.sensorOrientation;
      } else if (Platform.isAndroid) {
        final rotationValue = orientations[cameraController!.value.deviceOrientation] ?? 0;
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (camera.sensorOrientation + rotationValue) % 360;
        } else {
          rotationCompensation = (camera.sensorOrientation - rotationValue + 360) % 360;
        }
      }
      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(rotationCompensation) ??
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

      final faces = await faceDetector!.processImage(inputImage);

      final hasFace = faces.length == 1;

      if (mounted && isFaceDetected != hasFace) {
        setState(() {
          isFaceDetected = hasFace;
        });
      }
    } catch (_) {
    } finally {
      isDetecting = false;
    }
  }

  Future<void> handleTakeSelfie() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (!isFaceDetected) {
      showAlert(
        'Perhatian',
        'Wajah tidak terdeteksi atau terdapat lebih dari satu wajah. Pastikan wajah Anda terlihat jelas dalam bingkai kamera.',
      );
      return;
    }

    if (isTakingPicture) return;
    isTakingPicture = true;

    setState(() => loading = true);

    try {
      if (cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final photo = await cameraController!.takePicture();
      final savedPath = await CameraService.saveSelfie(
        photo.path,
        cameraJenis.toDbString(),
      );

      setState(() => showCamera = false);
      if (cameraController?.value.isStreamingImages == true) {
        await cameraController?.stopImageStream();
      }
      cameraController?.dispose();
      cameraController = null;
      faceDetector?.close();
      faceDetector = null;

      final geoState = ref.read(geofenceProvider);
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
      showAlert('Gagal Mengambil Foto', 'Terjadi kesalahan saat mengambil foto selfie. Silakan coba lagi.');
    } finally {
      isTakingPicture = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    final Plane yPlane = image.planes[0];
    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;

    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    int nv21Index = 0;

    for (int y = 0; y < height; y++) {
      int yIndex = y * yRowStride;
      for (int x = 0; x < width; x++) {
        nv21[nv21Index++] = yPlane.bytes[yIndex];
        yIndex += yPixelStride;
      }
    }

    for (int y = 0; y < height ~/ 2; y++) {
      int uIndex = y * uvRowStride;
      int vIndex = y * uvRowStride;
      for (int x = 0; x < width ~/ 2; x++) {
        nv21[nv21Index++] = vPlane.bytes[vIndex];
        nv21[nv21Index++] = uPlane.bytes[uIndex];
        uIndex += uvPixelStride;
        vIndex += uvPixelStride;
      }
    }
    return nv21;
  }
}
