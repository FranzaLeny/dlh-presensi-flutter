import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/presensi_log.dart';

class PresensiCameraView extends StatelessWidget {
  final CameraController? cameraController;
  final TipePresensi cameraJenis;
  final bool isFaceDetected;
  final bool loading;
  final VoidCallback onTakeSelfie;
  final VoidCallback onCancel;

  const PresensiCameraView({
    super.key,
    required this.cameraController,
    required this.cameraJenis,
    required this.isFaceDetected,
    required this.loading,
    required this.onTakeSelfie,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (cameraController != null &&
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  Text(
                    'Ambil foto selfie untuk presensi ${cameraJenis.displayLabel}',
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
                      color: isFaceDetected
                          ? AppColors.success.withValues(alpha: 0.8)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFaceDetected
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isFaceDetected
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFaceDetected
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
