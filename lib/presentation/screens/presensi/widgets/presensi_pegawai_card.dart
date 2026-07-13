import 'dart:io';
import 'package:flutter/material.dart';

class PresensiPegawaiCard extends StatelessWidget {
  final String nama;
  final String? nip;
  final String? jabatan;
  final String? localFotoPath;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;

  const PresensiPegawaiCard({
    super.key,
    required this.nama,
    this.nip,
    this.jabatan,
    this.localFotoPath,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              image: (localFotoPath != null && localFotoPath!.isNotEmpty)
                  ? DecorationImage(
                      image: FileImage(File(localFotoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (localFotoPath == null || localFotoPath!.isEmpty)
                ? Icon(
                    Icons.person_rounded,
                    color: accentColor,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Name & NIP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (nip != null && nip!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'NIP: $nip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (jabatan != null && jabatan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    jabatan!,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Verified badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF00E676) : const Color(0xFF43A047))
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFF00E676)
                  : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
