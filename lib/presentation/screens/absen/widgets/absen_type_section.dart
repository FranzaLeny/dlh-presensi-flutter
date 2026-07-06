import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AbsenTypeSection extends StatelessWidget {
  final String tipe;
  final bool isEditMode;
  final Color cardBg;
  final Color subtextColor;
  final Color borderColor;
  final ValueChanged<String?> onChanged;

  const AbsenTypeSection({
    super.key,
    required this.tipe,
    required this.isEditMode,
    required this.cardBg,
    required this.subtextColor,
    required this.borderColor,
    required this.onChanged,
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
            'ℹ️ Kategori Pengajuan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: tipe,
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
            onChanged: isEditMode ? null : onChanged,
            items: const [
              DropdownMenuItem(value: 'cuti', child: Text('Cuti Tahunan')),
              DropdownMenuItem(value: 'sakit', child: Text('Sakit (Surat Dokter)')),
              DropdownMenuItem(value: 'tugas', child: Text('Tugas Dinas / Tugas Luar')),
            ],
          ),
        ],
      ),
    );
  }
}
