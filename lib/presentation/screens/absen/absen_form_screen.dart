// ====================================
// Absen Form Screen — Pengajuan & Edit Absen
// ====================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/presensi_absen.dart';
import '../../../services/auth_service.dart';
import '../../../services/absen_service.dart';
import '../../../core/utils/error_utils.dart';

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



  Future<void> _showAttachmentPicker() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Ambil Foto Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih Gambar Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Pilih File PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (file != null) {
        setState(() {
          _localAttachmentPath = file.path;
          _attachmentName = file.name;
          _attachmentMimeType = 'image/jpeg';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _localAttachmentPath = result.files.single.path;
          _attachmentName = result.files.single.name;
          _attachmentMimeType = 'application/pdf';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file PDF: $e')),
      );
    }
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
        // Edit mode (Hono PATCH only allows updating fields except status)
        // Since we edit the pengajuan grouped by ID, we update all rows by calling PATCH on the group ID
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
                  // ── Section 1: Informasi Tipe ──────────────────────────
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
                          'ℹ️ Kategori Pengajuan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _tipe,
                          decoration: InputDecoration(
                            labelText: 'Jenis Absen',
                            labelStyle: TextStyle(color: subtextColor),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          dropdownColor: isDark ? const Color(0xFF2A2B3E) : Colors.white,
                          onChanged: _isEditMode
                              ? null // Tipe tidak bisa diubah saat edit
                              : (val) {
                                  if (val != null) {
                                    setState(() => _tipe = val);
                                  }
                                },
                          items: const [
                            DropdownMenuItem(value: 'cuti', child: Text('Cuti Tahunan')),
                            DropdownMenuItem(value: 'sakit', child: Text('Sakit (Surat Dokter)')),
                            DropdownMenuItem(value: 'tugas', child: Text('Tugas Dinas / Tugas Luar')),
                          ],
                        ),
                      ],
                    ),
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
                        _InlineMultiCalendar(
                          selectedDates: _selectedDates,
                          onDateToggled: _toggleDate,
                          isReadOnly: _isEditMode,
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Section 3: Keterangan & Lampiran ──────────────────
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
                          '📝 Keterangan Tambahan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _keteranganController,
                          maxLines: 3,
                          maxLength: 255,
                          decoration: InputDecoration(
                            hintText: 'Tulis alasan detail pengajuan Anda di sini...',
                            hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Keterangan harus diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '📎 Bukti Lampiran (Foto / PDF)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _showAttachmentPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, style: BorderStyle.none),
                              image: _localAttachmentPath != null && _attachmentMimeType == 'image/jpeg'
                                  ? DecorationImage(
                                      image: FileImage(File(_localAttachmentPath!)),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _attachmentMimeType == 'application/pdf'
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.cloud_upload_outlined,
                                  size: 36,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _attachmentName ?? (_dokumenUrl != null ? 'Lampiran sudah terunggah' : 'Pilih File (Foto / PDF)'),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _attachmentMimeType ?? 'Max 5MB. PDF, JPG, PNG',
                                  style: TextStyle(fontSize: 11, color: subtextColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _InlineMultiCalendar extends StatefulWidget {
  final List<String> selectedDates;
  final ValueChanged<String> onDateToggled;
  final bool isReadOnly;

  const _InlineMultiCalendar({
    required this.selectedDates,
    required this.onDateToggled,
    this.isReadOnly = false,
  });

  @override
  State<_InlineMultiCalendar> createState() => _InlineMultiCalendarState();
}

class _InlineMultiCalendarState extends State<_InlineMultiCalendar> {
  late DateTime _focusedMonth;

  final List<String> _weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedDates.isNotEmpty) {
      _focusedMonth = DateTime.parse(widget.selectedDates.first);
    } else {
      _focusedMonth = DateTime.now();
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1B2E);
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    final totalDays = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    final leadingEmptyDays = firstDayWeekday - 1;

    final totalGridItems = totalDays + leadingEmptyDays;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: textColor),
              onPressed: _prevMonth,
            ),
            Text(
              '${_months[month - 1]} $year',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, color: textColor),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays.map((day) {
            final isWeekend = day == 'Sab' || day == 'Min';
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isWeekend ? AppColors.error : subtextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: totalGridItems,
          itemBuilder: (context, index) {
            if (index < leadingEmptyDays) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - leadingEmptyDays + 1;
            final dayStr = dayNumber.toString().padLeft(2, '0');
            final monthStr = month.toString().padLeft(2, '0');
            final dateStr = '$year-$monthStr-$dayStr';

            final isSelected = widget.selectedDates.contains(dateStr);

            final now = DateTime.now();
            final isToday = now.year == year && now.month == month && now.day == dayNumber;

            return InkWell(
              onTap: widget.isReadOnly
                  ? null
                  : () => widget.onDateToggled(dateStr),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E5E1B) // Green background
                      : isToday
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.primary
                              : textColor,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
