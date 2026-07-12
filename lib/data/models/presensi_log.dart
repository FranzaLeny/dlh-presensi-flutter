// ====================================
// Model: PresensiLog — Data Log Presensi
// ====================================


/// Jenis presensi
import '../../core/utils/parse_utils.dart';

enum TipePresensi {

  masuk,
  pulang,
  mulaiIstirahat,
  selesaiIstirahat;

  /// Konversi ke string database (snake-case)
  String toDbString() {
    switch (this) {
      case TipePresensi.masuk:
        return 'masuk';
      case TipePresensi.pulang:
        return 'pulang';
      case TipePresensi.mulaiIstirahat:
        return 'mulai-istirahat';
      case TipePresensi.selesaiIstirahat:
        return 'selesai-istirahat';
    }
  }

  /// Label display untuk UI
  String get displayLabel {
    switch (this) {
      case TipePresensi.masuk:
        return 'Masuk';
      case TipePresensi.pulang:
        return 'Pulang';
      case TipePresensi.mulaiIstirahat:
        return 'Mulai Istirahat';
      case TipePresensi.selesaiIstirahat:
        return 'Selesai Istirahat';
    }
  }

  /// Parse dari string database
  static TipePresensi fromString(String value) {
    switch (value) {
      case 'masuk':
        return TipePresensi.masuk;
      case 'pulang':
        return TipePresensi.pulang;
      case 'mulai-istirahat':
        return TipePresensi.mulaiIstirahat;
      case 'selesai-istirahat':
        return TipePresensi.selesaiIstirahat;
      default:
        return TipePresensi.masuk; // Fallback to masuk instead of crashing
    }
  }
}

/// Data log presensi yang disimpan di SQLite lokal
class PresensiLog {
  final String id; // UUID v7
  final String pegawaiId;
  final String pengaturanId;
  final String tanggal; // format: YYYY-MM-DD
  final TipePresensi tipe;
  final String waktu; // format: ISO 8601 string
  final double latitude;
  final double longitude;
  final String? fotoPath; // path lokal di device
  final String? fotoUrl; // URL setelah upload ke cloud
  final int isLuarRadius;
  final int status;
  final String? keterangan;
  final bool isSynced;
  final String? deviceId;
  final String? namaVerifikator;

  const PresensiLog({
    required this.id,
    required this.pegawaiId,
    required this.pengaturanId,
    required this.tanggal,
    required this.tipe,
    required this.waktu,
    required this.latitude,
    required this.longitude,
    this.fotoPath,
    this.fotoUrl,
    this.isLuarRadius = 0,
    this.status = 2, // STATUS.PENDING
    this.keterangan,
    this.isSynced = false,
    this.deviceId,
    this.namaVerifikator,
  });

  /// Dari response API (JSON camelCase)
  factory PresensiLog.fromJson(Map<String, dynamic> json) {
    return PresensiLog(
      id: json['id'] as String,
      pegawaiId: json['pegawaiId'] as String,
      pengaturanId: json['pengaturanId'] as String,
      tanggal: json['tanggal'] as String,
      tipe: TipePresensi.fromString(json['tipe'] as String),
      waktu: json['waktu'] as String,
      latitude: (json['latitude'] is String)
          ? double.parse(json['latitude'] as String)
          : (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] is String)
          ? double.parse(json['longitude'] as String)
          : (json['longitude'] as num).toDouble(),
      fotoPath: json['fotoPath'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      isLuarRadius: (json['isLuarRadius'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 2,
      keterangan: json['keterangan'] as String?,
      isSynced: json['isSynced'] == true || json['isSynced'] == 1,
      deviceId: json['deviceId'] as String?,
      namaVerifikator: json['namaVerifikator'] as String?,
    );
  }

  /// Dari row SQLite (snake_case)
  factory PresensiLog.fromRow(Map<String, dynamic> row) {
    return PresensiLog(
      id: row['id']?.toString() ?? '',
      pegawaiId: row['pegawai_id']?.toString() ?? '',
      pengaturanId: row['pengaturan_id']?.toString() ?? '',
      tanggal: row['tanggal']?.toString() ?? '',
      tipe: TipePresensi.fromString(row['tipe']?.toString() ?? 'masuk'),
      waktu: row['waktu']?.toString() ?? '',
      latitude: parseDouble(row['latitude']),
      longitude: parseDouble(row['longitude']),
      fotoPath: row['foto_path']?.toString(),
      fotoUrl: row['foto_url']?.toString(),
      isLuarRadius: parseInt(row['is_luar_radius']),
      status: parseInt(row['status'], defaultValue: 2),
      keterangan: row['keterangan']?.toString(),
      isSynced: parseInt(row['is_synced']) == 1,
      deviceId: row['device_id']?.toString(),
      namaVerifikator: row['nama_verifikator']?.toString(),
    );
  }

  /// Ke format SQLite (snake_case)
  Map<String, dynamic> toRow() => {
        'id': id,
        'pegawai_id': pegawaiId,
        'pengaturan_id': pengaturanId,
        'tanggal': tanggal,
        'tipe': tipe.toDbString(),
        'waktu': waktu,
        'latitude': latitude,
        'longitude': longitude,
        'foto_path': fotoPath,
        'foto_url': fotoUrl,
        'is_luar_radius': isLuarRadius,
        'status': status,
        'keterangan': keterangan,
        'device_id': deviceId,
        'is_synced': isSynced ? 1 : 0,
        'nama_verifikator': namaVerifikator,
      };

  /// Ke JSON API (camelCase)
  Map<String, dynamic> toJson() => {
        'id': id,
        'pegawaiId': pegawaiId,
        'pengaturanId': pengaturanId,
        'tanggal': tanggal,
        'tipe': tipe.toDbString(),
        'waktu': waktu,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'fotoUrl': fotoUrl,
        'deviceId': deviceId,
      };

  /// Buat salinan dengan perubahan field tertentu
  PresensiLog copyWith({
    String? id,
    String? pegawaiId,
    String? pengaturanId,
    String? tanggal,
    TipePresensi? tipe,
    String? waktu,
    double? latitude,
    double? longitude,
    String? fotoPath,
    String? fotoUrl,
    int? isLuarRadius,
    int? status,
    String? keterangan,
    bool? isSynced,
    String? deviceId,
    String? namaVerifikator,
  }) {
    return PresensiLog(
      id: id ?? this.id,
      pegawaiId: pegawaiId ?? this.pegawaiId,
      pengaturanId: pengaturanId ?? this.pengaturanId,
      tanggal: tanggal ?? this.tanggal,
      tipe: tipe ?? this.tipe,
      waktu: waktu ?? this.waktu,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fotoPath: fotoPath ?? this.fotoPath,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      isLuarRadius: isLuarRadius ?? this.isLuarRadius,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      isSynced: isSynced ?? this.isSynced,
      deviceId: deviceId ?? this.deviceId,
      namaVerifikator: namaVerifikator ?? this.namaVerifikator,
    );
  }
}
