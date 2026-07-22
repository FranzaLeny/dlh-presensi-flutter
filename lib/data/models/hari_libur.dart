// ====================================
// Model: HariLibur — Data Hari Libur
// ====================================

class HariLibur {
  final String id;
  final String tanggal; // format: YYYY-MM-DD
  final String nama;
  final String tipe; // 'libur_nasional' | 'cuti_bersama' | 'libur_jadwal'
  final String? keterangan;
  final String? dokumenUrl;
  final String? createdAt;
  final String? updatedAt;

  const HariLibur({
    required this.id,
    required this.tanggal,
    required this.nama,
    required this.tipe,
    this.keterangan,
    this.dokumenUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Dari response API (JSON camelCase)
  factory HariLibur.fromJson(Map<String, dynamic> json) {
    return HariLibur(
      id: json['id'] as String,
      tanggal: json['tanggal'] as String,
      nama: json['nama'] as String,
      tipe: json['tipe'] as String,
      keterangan: json['keterangan'] as String?,
      dokumenUrl: json['dokumenUrl'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  /// Dari row SQLite (snake_case)
  factory HariLibur.fromRow(Map<String, dynamic> row) {
    return HariLibur(
      id: row['id']?.toString() ?? '',
      tanggal: row['tanggal']?.toString() ?? '',
      nama: row['nama']?.toString() ?? '',
      tipe: row['tipe']?.toString() ?? 'libur_nasional',
      keterangan: row['keterangan']?.toString(),
      dokumenUrl: row['dokumen_url']?.toString(),
      createdAt: row['created_at']?.toString(),
      updatedAt: row['updated_at']?.toString(),
    );
  }

  /// Ke format SQLite (snake_case)
  Map<String, dynamic> toRow() => {
        'id': id,
        'tanggal': tanggal,
        'nama': nama,
        'tipe': tipe,
        'keterangan': keterangan,
        'dokumen_url': dokumenUrl,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
