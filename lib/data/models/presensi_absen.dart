// ====================================
// Model: PresensiAbsen — Data Pengajuan Absen
// ====================================

class PresensiAbsen {
  final String id;
  final String skpdId;
  final String pegawaiId;
  final String tanggal; // format: YYYY-MM-DD (single date per row in database)
  final String tipe; // 'cuti' | 'sakit' | 'tugas'
  final String? keterangan;
  final String? dokumenUrl;
  final int status; // 0=PENDING, 20=APPROVED, -20=REJECTED
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const PresensiAbsen({
    required this.id,
    required this.skpdId,
    required this.pegawaiId,
    required this.tanggal,
    required this.tipe,
    this.keterangan,
    this.dokumenUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  /// Dari response API (JSON camelCase)
  factory PresensiAbsen.fromJson(Map<String, dynamic> json) {
    return PresensiAbsen(
      id: json['id'] as String,
      skpdId: json['skpdId'] as String,
      pegawaiId: json['pegawaiId'] as String,
      tanggal: json['tanggal'] as String,
      tipe: json['tipe'] as String,
      keterangan: json['keterangan'] as String?,
      dokumenUrl: json['dokumenUrl'] as String?,
      status: (json['status'] as num).toInt(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  /// Dari row SQLite (snake_case)
  factory PresensiAbsen.fromRow(Map<String, dynamic> row) {
    return PresensiAbsen(
      id: row['id']?.toString() ?? '',
      skpdId: row['skpd_id']?.toString() ?? '',
      pegawaiId: row['pegawai_id']?.toString() ?? '',
      tanggal: row['tanggal']?.toString() ?? '',
      tipe: row['tipe']?.toString() ?? 'cuti',
      keterangan: row['keterangan']?.toString(),
      dokumenUrl: row['dokumen_url']?.toString(),
      status: _parseInt(row['status'], defaultValue: 0),
      createdAt: row['created_at']?.toString(),
      updatedAt: row['updated_at']?.toString(),
      createdBy: row['created_by']?.toString(),
      updatedBy: row['updated_by']?.toString(),
    );
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
        'pegawai_id': pegawaiId,
        'tanggal': tanggal,
        'tipe': tipe,
        'keterangan': keterangan,
        'dokumen_url': dokumenUrl,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'created_by': createdBy,
        'updated_by': updatedBy,
      };

  PresensiAbsen copyWith({
    String? id,
    String? skpdId,
    String? pegawaiId,
    String? tanggal,
    String? tipe,
    String? keterangan,
    String? dokumenUrl,
    int? status,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return PresensiAbsen(
      id: id ?? this.id,
      skpdId: skpdId ?? this.skpdId,
      pegawaiId: pegawaiId ?? this.pegawaiId,
      tanggal: tanggal ?? this.tanggal,
      tipe: tipe ?? this.tipe,
      keterangan: keterangan ?? this.keterangan,
      dokumenUrl: dokumenUrl ?? this.dokumenUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
