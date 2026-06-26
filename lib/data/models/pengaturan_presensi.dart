// ====================================
// Model: PengaturanPresensi — Pengaturan per SKPD
// ====================================

/// Pengaturan presensi per SKPD (kantor)
class PengaturanPresensi {
  final String id;
  final String skpdId;
  final String? namaKantor;
  final double latitude;
  final double longitude;
  final int radius; // dalam meter
  final String jamMasukMulai; // format: HH:mm:ss
  final String jamMasukSelesai;
  final String jamIstirahatMulai;
  final String jamIstirahatSelesai;
  final String jamPulangMulai;
  final String jamPulangSelesai;
  final String? updatedAt;

  const PengaturanPresensi({
    required this.id,
    required this.skpdId,
    this.namaKantor,
    required this.latitude,
    required this.longitude,
    this.radius = 100,
    this.jamMasukMulai = '07:30:00',
    this.jamMasukSelesai = '08:30:00',
    this.jamIstirahatMulai = '12:00:00',
    this.jamIstirahatSelesai = '13:00:00',
    this.jamPulangMulai = '16:00:00',
    this.jamPulangSelesai = '17:00:00',
    this.updatedAt,
  });

  /// Dari response API (JSON camelCase)
  factory PengaturanPresensi.fromJson(Map<String, dynamic> json) {
    return PengaturanPresensi(
      id: (json['id'] ?? json['skpdId'] ?? 'default') as String,
      skpdId: json['skpdId'] as String,
      namaKantor: json['namaKantor'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toInt() ?? 100,
      jamMasukMulai: (json['jamMasukMulai'] as String?) ?? '07:30:00',
      jamMasukSelesai: (json['jamMasukSelesai'] as String?) ?? '08:30:00',
      jamIstirahatMulai: (json['jamIstirahatMulai'] as String?) ?? '12:00:00',
      jamIstirahatSelesai:
          (json['jamIstirahatSelesai'] as String?) ?? '13:00:00',
      jamPulangMulai: (json['jamPulangMulai'] as String?) ?? '16:00:00',
      jamPulangSelesai: (json['jamPulangSelesai'] as String?) ?? '17:00:00',
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Dari row SQLite (snake_case)
  factory PengaturanPresensi.fromRow(Map<String, dynamic> row) {
    return PengaturanPresensi(
      id: row['id']?.toString() ?? '',
      skpdId: row['skpd_id']?.toString() ?? '',
      namaKantor: row['nama_kantor']?.toString(),
      latitude: _parseDouble(row['latitude']),
      longitude: _parseDouble(row['longitude']),
      radius: _parseInt(row['radius'], defaultValue: 100),
      jamMasukMulai: row['jam_masuk_mulai']?.toString() ?? '07:30:00',
      jamMasukSelesai: row['jam_masuk_selesai']?.toString() ?? '08:30:00',
      jamIstirahatMulai: row['jam_istirahat_mulai']?.toString() ?? '12:00:00',
      jamIstirahatSelesai: row['jam_istirahat_selesai']?.toString() ?? '13:00:00',
      jamPulangMulai: row['jam_pulang_mulai']?.toString() ?? '16:00:00',
      jamPulangSelesai: row['jam_pulang_selesai']?.toString() ?? '17:00:00',
      updatedAt: row['updated_at']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Ke format SQLite (snake_case)
  Map<String, dynamic> toRow() => {
        'id': id,
        'skpd_id': skpdId,
        'nama_kantor': namaKantor,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'jam_masuk_mulai': jamMasukMulai,
        'jam_masuk_selesai': jamMasukSelesai,
        'jam_istirahat_mulai': jamIstirahatMulai,
        'jam_istirahat_selesai': jamIstirahatSelesai,
        'jam_pulang_mulai': jamPulangMulai,
        'jam_pulang_selesai': jamPulangSelesai,
        'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
      };
}
