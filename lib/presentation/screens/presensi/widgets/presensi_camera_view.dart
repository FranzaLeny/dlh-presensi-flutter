import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/presensi_log.dart';

class PresensiCameraView extends StatelessWidget {
  final CameraController? cameraController;
  final TipePresensi cameraJenis;
  final bool isFaceDetected;
  final bool loading;
  final bool isFaceDetectionEnabled;
  final bool showBypassToggle;
  final String? capturedPhotoPath;
  final ValueChanged<bool> onToggleFaceDetection;
  final VoidCallback onTakeSelfie;
  final VoidCallback onCancel;
  final VoidCallback onSubmitPhoto;
  final VoidCallback onRetakePhoto;

  const PresensiCameraView({
    super.key,
    required this.cameraController,
    required this.cameraJenis,
    required this.isFaceDetected,
    required this.loading,
    required this.isFaceDetectionEnabled,
    required this.showBypassToggle,
    required this.capturedPhotoPath,
    required this.onToggleFaceDetection,
    required this.onTakeSelfie,
    required this.onCancel,
    required this.onSubmitPhoto,
    required this.onRetakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPreviewMode = capturedPhotoPath != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background: Camera Preview OR Captured Photo
          if (!isPreviewMode &&
              cameraController != null &&
              cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraController!.value.previewSize?.height ?? 1,
                  height: cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(cameraController!),
                ),
              ),
            ),
            
          if (isPreviewMode)
            SizedBox.expand(
              child: Image.file(
                File(capturedPhotoPath!),
                fit: BoxFit.cover,
              ),
            ),



          // Face Detection Bypass Toggle
          if (showBypassToggle)
            Positioned(
              top: 48,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Deteksi Wajah',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isFaceDetectionEnabled,
                      onChanged: onToggleFaceDetection,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls Layer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isPreviewMode 
                        ? 'Pratinjau Foto'
                        : 'Ambil foto selfie untuk presensi ${cameraJenis.displayLabel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  
                  // Face Detection Indicator
                  if (isPreviewMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: !isFaceDetectionEnabled
                            ? Colors.orange.withValues(alpha: 0.8)
                            : isFaceDetected
                                ? AppColors.success.withValues(alpha: 0.8)
                                : AppColors.error.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            !isFaceDetectionEnabled
                                ? Icons.warning_amber_rounded
                                : isFaceDetected
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            !isFaceDetectionEnabled
                                ? 'Bypass Deteksi Wajah'
                                : isFaceDetected
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
                  
                  // Buttons Layer
                  if (!isPreviewMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: onCancel,
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        GestureDetector(
                          onTap: loading ? null : onTakeSelfie,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 60), // spacer for balance
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: loading ? null : onRetakePhoto,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Ulangi', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: loading || (isFaceDetectionEnabled && !isFaceDetected) ? null : onSubmitPhoto,
                          icon: loading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Icon(Icons.send_rounded, color: Colors.white),
                          label: const Text('Kirim', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
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
