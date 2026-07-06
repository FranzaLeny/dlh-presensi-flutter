import 'package:flutter/material.dart';
import '../../../../data/models/pegawai.dart';

class ProfilInfoSection extends StatelessWidget {
  final Pegawai? pegawai;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;

  const ProfilInfoSection({
    super.key,
    required this.pegawai,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Data Kepegawaian',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
              label: 'NIP',
              value: pegawai?.nip ?? '-',
              textColor: textColor,
              subtextColor: subtextColor),
          _InfoRow(
              label: 'Jenis Pegawai',
              value: pegawai?.jenisPegawai ?? '-',
              textColor: textColor,
              subtextColor: subtextColor),
          _InfoRow(
              label: 'Instansi',
              value: pegawai?.instansi ?? '-',
              textColor: textColor,
              subtextColor: subtextColor),
          _InfoRow(
              label: 'SKPD',
              value: pegawai?.namaSkpd ?? '-',
              textColor: textColor,
              subtextColor: subtextColor),
          _InfoRow(
              label: 'Jenis Kelamin',
              value: pegawai?.jenisKelamin == 'L'
                  ? 'Laki-laki'
                  : 'Perempuan',
              textColor: textColor,
              subtextColor: subtextColor,
              isLast: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color subtextColor;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtextColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: subtextColor)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
          ),
        ],
      ),
    );
  }
}
