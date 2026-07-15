// ====================================
// Presensi Screen — Absen Masuk / Pulang
// ====================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../services/time_service.dart';
import 'presensi_camera_controller.dart';
import 'presensi_controller.dart';
import 'widgets/presensi_action_buttons.dart';
import 'widgets/presensi_camera_view.dart';
import 'widgets/presensi_geofence_card.dart';
import 'widgets/presensi_pegawai_card.dart';
import 'widgets/presensi_time_card.dart';
import 'widgets/presensi_timeline_section.dart';
import 'widgets/time_mismatch_overlay.dart';

class PresensiScreen extends ConsumerStatefulWidget {
  const PresensiScreen({super.key});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen>
    with WidgetsBindingObserver, PresensiCameraController, PresensiController {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestPermissions();
    startTimer();
    loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    if (cameraController?.value.isStreamingImages == true) {
      cameraController?.stopImageStream();
    }
    cameraController?.dispose();
    faceDetector?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      TimeService.resetSessionReference();
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final geoState = ref.watch(geofenceProvider);

    // Camera view
    if (showCamera) {
      return PresensiCameraView(
        cameraController: cameraController,
        cameraJenis: cameraJenis,
        isFaceDetected: isFaceDetected,
        loading: loading,
        isFaceDetectionEnabled: isFaceDetectionEnabled,
        showBypassToggle: showBypassToggle,
        capturedPhotoPath: capturedPhotoPath,
        onToggleFaceDetection: (val) {
          setState(() {
            isFaceDetectionEnabled = val;
          });
        },
        onTakeSelfie: handleTakeSelfie,
        onCancel: () async {
          setState(() => showCamera = false);
          cameraController?.dispose();
          cameraController = null;
          faceDetector?.close();
          faceDetector = null;
        },
        onSubmitPhoto: handleSubmitPhoto,
        onRetakePhoto: handleRetakePhoto,
      );
    }

    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final dayOfWeek = TimeService.getWITA(currentTime).weekday % 7;
    final override = pengaturan?.jadwalHarian?.where((j) => j.hari == dayOfWeek).firstOrNull;
    String jamIstirahatMulai = override != null ? (override.jamIstirahatMulai ?? '') : (pengaturan?.jamIstirahatMulai ?? '');
    bool hasBreak = jamIstirahatMulai.isNotEmpty && jamIstirahatMulai != '-' && jamIstirahatMulai != '00:00:00';

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Time & Date Cards ──────────────────────────
                    PresensiTimeCard(
                      currentTime: currentTime,
                      isDark: isDark,
                      cardBg: cardBg,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 16),

                    // ── Pegawai Identity Card ───────────────
                    if (pegawaiData != null)
                      PresensiPegawaiCard(
                        nama: pegawaiData!.nama,
                        nip: pegawaiData!.nip,
                        jabatan: pegawaiData!.jabatan,
                        localFotoPath: pegawaiData!.localFotoPath,
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        subtextColor: subtextColor,
                      ),
                    if (pegawaiData != null) const SizedBox(height: 16),

                    // ── Action Buttons ─────────────────────────────
                    PresensiActionButtons(
                      masukLog: masukLog,
                      mulaiIstirahatLog: mulaiIstirahatLog,
                      selesaiIstirahatLog: selesaiIstirahatLog,
                      pulangLog: pulangLog,
                      todayLogs: todayLogs,
                      approvedAbsence: approvedAbsence,
                      isTodayLibur: isTodayLibur,
                      liburNama: liburNama,
                      hasBreak: hasBreak,
                      loading: loading,
                      cardBg: cardBg,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      onAbsen: handleAbsen,
                      onRedo: handleRedoPresensi,
                    ),
                    const SizedBox(height: 12),

                    // ── Geofence Info ──────────────────────────────
                    if (pengaturan != null)
                      PresensiGeofenceCard(
                        geoState: geoState,
                        cardBg: cardBg,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        loading: loading,
                        onRefresh: () => ref
                            .read(geofenceProvider.notifier)
                            .checkGeofence(pengaturan!, force: true),
                      ),
                    const SizedBox(height: 12),

                    // ── Timeline ───────────────────────────────────
                    PresensiTimelineSection(
                      masukLog: masukLog,
                      mulaiIstirahatLog: mulaiIstirahatLog,
                      selesaiIstirahatLog: selesaiIstirahatLog,
                      pulangLog: pulangLog,
                      pengaturan: pengaturan,
                      isLibur: isTodayLibur,
                      isDark: isDark,
                      cardBg: cardBg,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // ── Time Mismatch Modal ─────────────────────────────
          if (timeMismatch)
            TimeMismatchOverlay(
              isDark: isDark,
              retryingTime: retryingTime,
              onRetry: handleRetryTimeSync,
            ),
        ],
      ),
    );
  }
}
