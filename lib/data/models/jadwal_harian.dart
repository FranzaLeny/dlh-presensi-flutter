// ====================================
// Model: JadwalHarian — Jadwal Harian Fleksibel
// ====================================

class JadwalHarian {
  final int hari; // 0=Minggu, 6=Sabtu
  final String jamMasuk; // format: HH:mm:ss
  final String jamPulang; // format: HH:mm:ss
  final String? jamIstirahatMulai; // format: HH:mm:ss
  final String? jamIstirahatSelesai; // format: HH:mm:ss
  final int isLibur; // 0=tidak, 1=ya

  const JadwalHarian({
    required this.hari,
    required this.jamMasuk,
    required this.jamPulang,
    this.jamIstirahatMulai,
    this.jamIstirahatSelesai,
    required this.isLibur,
  });

  /// Dari response API (JSON camelCase)
  factory JadwalHarian.fromJson(Map<String, dynamic> json) {
    return JadwalHarian(
      hari: (json['hari'] as num).toInt(),
      jamMasuk: (json['jamMasuk'] as String?) ?? '08:00:00',
      jamPulang: (json['jamPulang'] as String?) ?? '16:00:00',
      jamIstirahatMulai: json['jamIstirahatMulai'] as String?,
      jamIstirahatSelesai: json['jamIstirahatSelesai'] as String?,
      isLibur: (json['isLibur'] as num?)?.toInt() ?? 0,
    );
  }

  /// Ke format JSON camelCase
  Map<String, dynamic> toJson() {
    return {
      'hari': hari,
      'jamMasuk': jamMasuk,
      'jamPulang': jamPulang,
      'jamIstirahatMulai': jamIstirahatMulai,
      'jamIstirahatSelesai': jamIstirahatSelesai,
      'isLibur': isLibur,
    };
  }
}
