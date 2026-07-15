import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/presensi_log.dart';

class PresensiCameraView extends StatelessWidget {
  final CameraController? cameraController;
  final TipePresensi cameraJenis;
  final bool isFaceDetected;
  final bool loading;
  final String debugMessage;
  final bool isFaceDetectionEnabled;
  final bool showBypassToggle;
  final ValueChanged<bool> onToggleFaceDetection;
  final VoidCallback onTakeSelfie;
  final VoidCallback onCancel;

  const PresensiCameraView({
    super.key,
    required this.cameraController,
    required this.cameraJenis,
    required this.isFaceDetected,
    required this.loading,
    required this.debugMessage,
    required this.isFaceDetectionEnabled,
    required this.showBypassToggle,
    required this.onToggleFaceDetection,
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
          if (debugMessage.isNotEmpty)
            Positioned(
              top: 48,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent, width: 1),
                ),
                child: Text(
                  debugMessage,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          if (showBypassToggle)
            Positioned(
              top: debugMessage.isNotEmpty ? 120 : 48,
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
                      color: !isFaceDetectionEnabled
                          ? Colors.orange.withValues(alpha: 0.8)
                          : isFaceDetected
                              ? AppColors.success.withValues(alpha: 0.8)
                              : Colors.black54,
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
                                  : Icons.warning_amber_rounded,
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
                                    color: !isFaceDetectionEnabled || isFaceDetected
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
