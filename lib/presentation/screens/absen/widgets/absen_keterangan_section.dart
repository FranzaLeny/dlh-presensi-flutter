import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AbsenKeteranganSection extends StatelessWidget {
  final TextEditingController keteranganController;
  final Color cardBg;
  final Color subtextColor;
  final Color borderColor;
  final VoidCallback onTapAttachment;
  final String? localAttachmentPath;
  final String? attachmentMimeType;
  final String? attachmentName;
  final String? dokumenUrl;

  const AbsenKeteranganSection({
    super.key,
    required this.keteranganController,
    required this.cardBg,
    required this.subtextColor,
    required this.borderColor,
    required this.onTapAttachment,
    required this.localAttachmentPath,
    required this.attachmentMimeType,
    required this.attachmentName,
    required this.dokumenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            controller: keteranganController,
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
            onTap: onTapAttachment,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, style: BorderStyle.none),
                image: localAttachmentPath != null && attachmentMimeType == 'image/jpeg'
                    ? DecorationImage(
                        image: FileImage(File(localAttachmentPath!)),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    attachmentMimeType == 'application/pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.cloud_upload_outlined,
                    size: 36,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attachmentName ?? (dokumenUrl != null ? 'Lampiran sudah terunggah' : 'Pilih File (Foto / PDF)'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attachmentMimeType ?? 'Max 5MB. PDF, JPG, PNG',
                    style: TextStyle(fontSize: 11, color: subtextColor),
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
