import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/pegawai.dart';

class ProfilInfoSection extends StatelessWidget {
  final Pegawai? pegawai;
  final Color cardBg;
  final Color textColor;
  final Color subtextColor;
  final Color borderColor;
  final VoidCallback? onSyncPegawai;
  final bool isSyncingPegawai;

  const ProfilInfoSection({
    super.key,
    required this.pegawai,
    required this.cardBg,
    required this.textColor,
    required this.subtextColor,
    required this.borderColor,
    this.onSyncPegawai,
    this.isSyncingPegawai = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> availableData = [];

    if (pegawai != null) {
      void addData(String label, String? value) {
        if (value != null && value.trim().isNotEmpty && value != '-') {
          availableData.add({'label': label, 'value': value.trim()});
        }
      }

      final nama = pegawai!.namaTanpaGelar.isNotEmpty ? pegawai!.namaTanpaGelar : pegawai!.nama;
      addData('Nama Lengkap', nama);
      addData('NIP', pegawai!.nip);

      if (pegawai!.jenisKelamin == 'L') {
        addData('Jenis Kelamin', 'Laki-laki');
      } else if (pegawai!.jenisKelamin == 'P') {
        addData('Jenis Kelamin', 'Perempuan');
      }

      addData('Jenis Pegawai', pegawai!.jenisPegawai);
      addData('Jabatan', pegawai!.jabatan);

      final pg = pegawai!.pangkatGolongan;
      if (pg != null) {
        final pkt = pg.pangkat;
        final gol = pg.golongan;
        final rng = pg.ruang;

        if (pkt.isNotEmpty && rng.isNotEmpty) {
          addData('Pangkat, Gol./Ruang', '$pkt, $gol/$rng');
        } else if (gol.isNotEmpty) {
          addData('Golongan', gol);
        }
      }

      addData('Instansi', pegawai!.instansi);
      addData('SKPD', pegawai!.namaSkpd);
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📋 Data Kepegawaian',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (onSyncPegawai != null)
                IconButton(
                  onPressed: isSyncingPegawai ? null : onSyncPegawai,
                  icon: isSyncingPegawai
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  tooltip: 'Sinkronisasi Data Pegawai',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (availableData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Data belum tersedia.',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
            )
          else
            ...List.generate(availableData.length, (index) {
              final item = availableData[index];
              return _InfoRow(
                label: item['label']!,
                value: item['value']!,
                textColor: textColor,
                subtextColor: subtextColor,
                isLast: index == availableData.length - 1,
              );
            }),
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
