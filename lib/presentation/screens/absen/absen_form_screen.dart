// ====================================
// Absen Form Screen — Pengajuan & Edit Absen
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/presensi_absen.dart';
import '../../../services/auth_service.dart';
import '../../../services/absen_service.dart';
import '../../../core/utils/error_utils.dart';
import 'widgets/absen_keterangan_section.dart';
import 'widgets/absen_type_section.dart';
import 'widgets/attachment_picker.dart';
import 'widgets/inline_multi_calendar.dart';

class AbsenFormScreen extends StatefulWidget {
  final List<PresensiAbsen>? initialAbsenList;

  const AbsenFormScreen({super.key, this.initialAbsenList});

  @override
  State<AbsenFormScreen> createState() => _AbsenFormScreenState();
}

class _AbsenFormScreenState extends State<AbsenFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();

  bool _isEditMode = false;
  String _tipe = 'cuti';
  List<String> _selectedDates = []; // YYYY-MM-DD format
  String? _dokumenUrl;
  
  // File upload state
  String? _localAttachmentPath;
  String? _attachmentName;
  String? _attachmentMimeType;
  bool _saving = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialAbsenList != null && widget.initialAbsenList!.isNotEmpty) {
      _isEditMode = true;
      final first = widget.initialAbsenList!.first;
      _tipe = first.tipe;
      _keteranganController.text = first.keterangan ?? '';
      _dokumenUrl = first.dokumenUrl;
      _selectedDates = widget.initialAbsenList!.map((e) => e.tanggal).toList()..sort();
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  void _toggleDate(String dateStr) {
    setState(() {
      if (_selectedDates.contains(dateStr)) {
        _selectedDates.remove(dateStr);
      } else {
        _selectedDates.add(dateStr);
        _selectedDates.sort();
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih minimal 1 tanggal pengajuan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final pegawai = await AuthService.getPegawai();
      if (pegawai == null) throw Exception('Data pegawai tidak ditemukan.');

      // 1. Upload file if path is local
      String? uploadUrl = _dokumenUrl;
      if (_localAttachmentPath != null) {
        final uploadDate = _selectedDates.isNotEmpty ? _selectedDates.first : DateFormat('yyyy-MM-dd').format(DateTime.now());
        uploadUrl = await AbsenService.uploadDokumen(
          _localAttachmentPath!,
          'absen',
          uploadDate,
          _attachmentMimeType ?? 'application/pdf',
        );
      }

      // 2. Send API request
      if (_isEditMode) {
        final id = widget.initialAbsenList!.first.id;
        await AbsenService.updateAbsen(
          id,
          keterangan: _keteranganController.text,
          dokumenUrl: uploadUrl,
        );
      } else {
        // Create mode
        await AbsenService.createAbsen(
          pegawaiId: pegawai.id,
          tanggal: _selectedDates,
          tipe: _tipe,
          keterangan: _keteranganController.text.isNotEmpty ? _keteranganController.text : null,
          dokumenUrl: uploadUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Pengajuan absen berhasil diubah' : 'Pengajuan absen berhasil diajukan'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengajuan: ${getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1B2E) : const Color(0xFFF5F5FA);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(
          _isEditMode ? 'Ubah Pengajuan Absen' : 'Pengajuan Absen Baru',
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Kategori Pengajuan ──────────────────────
                  AbsenTypeSection(
                    tipe: _tipe,
                    isEditMode: _isEditMode,
                    cardBg: cardBg,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _tipe = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Section 2: Pilih Tanggal ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📅 Pilih Tanggal Libur/Absen',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        InlineMultiCalendar(
                          selectedDates: _selectedDates,
                          onDateToggled: _toggleDate,
                          isReadOnly: _isEditMode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 3: Keterangan & Lampiran ──────────────────
                  AbsenKeteranganSection(
                    keteranganController: _keteranganController,
                    cardBg: cardBg,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    localAttachmentPath: _localAttachmentPath,
                    attachmentMimeType: _attachmentMimeType,
                    attachmentName: _attachmentName,
                    dokumenUrl: _dokumenUrl,
                    onTapAttachment: () {
                      showAttachmentPicker(
                        context: context,
                        imagePicker: _imagePicker,
                        onFilePicked: (path, name, mimeType) {
                          setState(() {
                            _localAttachmentPath = path;
                            _attachmentName = name;
                            _attachmentMimeType = mimeType;
                          });
                        },
                        onError: (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Submit Button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _saving
                            ? 'Menyimpan...'
                            : _isEditMode
                                ? 'Simpan Perubahan'
                                : 'Kirim Pengajuan',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
