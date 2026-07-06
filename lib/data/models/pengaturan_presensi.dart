import 'dart:convert';
import 'jadwal_harian.dart';

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
  final String jamMasuk; // format: HH:mm:ss
  final String jamIstirahatMulai;
  final String jamIstirahatSelesai;
  final String jamPulang;
  final String? tanggalMulai;
  final String? tanggalBerakhir;
  final int status;
  final String? updatedAt;
  final List<JadwalHarian>? jadwalHarian;

  const PengaturanPresensi({
    required this.id,
    required this.skpdId,
    this.namaKantor,
    required this.latitude,
    required this.longitude,
    this.radius = 100,
    this.jamMasuk = '08:00:00',
    this.jamIstirahatMulai = '12:00:00',
    this.jamIstirahatSelesai = '13:00:00',
    this.jamPulang = '16:00:00',
    this.tanggalMulai,
    this.tanggalBerakhir,
    this.status = 10,
    this.updatedAt,
    this.jadwalHarian,
  });

  /// Dari response API (JSON camelCase)
  factory PengaturanPresensi.fromJson(Map<String, dynamic> json) {
    return PengaturanPresensi(
      id: (json['id'] ?? json['skpdId'] ?? 'default') as String,
      skpdId: json['skpdId'] as String,
      namaKantor: json['skpd']?['nama'] as String?,
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'] as String)
          : (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'] as String)
          : (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toInt() ?? 100,
      jamMasuk: (json['jamMasuk'] as String?) ?? '08:00:00',
      jamIstirahatMulai: (json['jamIstirahatMulai'] as String?) ?? '12:00:00',
      jamIstirahatSelesai:
          (json['jamIstirahatSelesai'] as String?) ?? '13:00:00',
      jamPulang: (json['jamPulang'] as String?) ?? '16:00:00',
      tanggalMulai: json['tanggalMulai'] as String?,
      tanggalBerakhir: json['tanggalBerakhir'] as String?,
      status: (json['status'] as num?)?.toInt() ?? 10,
      updatedAt: json['updatedAt'] as String?,
      jadwalHarian: json['jadwalHarian'] != null
          ? (json['jadwalHarian'] as List)
              .map((e) => JadwalHarian.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
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
      jamMasuk: row['jam_masuk']?.toString() ?? '08:00:00',
      jamIstirahatMulai: row['jam_istirahat_mulai']?.toString() ?? '12:00:00',
      jamIstirahatSelesai: row['jam_istirahat_selesai']?.toString() ?? '13:00:00',
      jamPulang: row['jam_pulang']?.toString() ?? '16:00:00',
      tanggalMulai: row['tanggal_mulai']?.toString(),
      tanggalBerakhir: row['tanggal_berakhir']?.toString(),
      status: _parseInt(row['status'], defaultValue: 10),
      updatedAt: row['updated_at']?.toString(),
      jadwalHarian: row['jadwal_harian_json'] != null
          ? (jsonDecode(row['jadwal_harian_json'] as String) as List)
              .map((e) => JadwalHarian.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
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
        'jam_masuk': jamMasuk,
        'jam_istirahat_mulai': jamIstirahatMulai,
        'jam_istirahat_selesai': jamIstirahatSelesai,
        'jam_pulang': jamPulang,
        'tanggal_mulai': tanggalMulai,
        'tanggal_berakhir': tanggalBerakhir,
        'status': status,
        'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
        'jadwal_harian_json': jadwalHarian != null
            ? jsonEncode(jadwalHarian!.map((e) => e.toJson()).toList())
            : null,
      };
}
