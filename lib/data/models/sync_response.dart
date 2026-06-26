// ====================================
// Model: SyncResponse — Response dari API Sync
// ====================================

/// Response dari API sync
class SyncResponse {
  final List<SyncedItem> synced;
  final List<String> unSyncedIds;

  const SyncResponse({
    required this.synced,
    required this.unSyncedIds,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      synced: (json['synced'] as List<dynamic>?)
              ?.map((e) => SyncedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unSyncedIds: (json['unSyncedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class SyncedItem {
  final String id;
  final String pegawaiId;
  final String pengaturanId;
  final String tanggal;
  final String tipe;
  final String waktu;
  final String? latitude;
  final String? longitude;
  final String? fotoUrl;
  final int status;
  final String? verifikatorId;
  final String? waktuVerifikasi;
  final String? alasanPenolakan;
  final String? keterangan;
  final String? deviceId;
  final String? syncAt;
  final String createdAt;
  final String updatedAt;

  const SyncedItem({
    required this.id,
    required this.pegawaiId,
    required this.pengaturanId,
    required this.tanggal,
    required this.tipe,
    required this.waktu,
    this.latitude,
    this.longitude,
    this.fotoUrl,
    required this.status,
    this.verifikatorId,
    this.waktuVerifikasi,
    this.alasanPenolakan,
    this.keterangan,
    this.deviceId,
    this.syncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SyncedItem.fromJson(Map<String, dynamic> json) {
    return SyncedItem(
      id: json['id'] as String,
      pegawaiId: json['pegawaiId'] as String,
      pengaturanId: json['pengaturanId'] as String,
      tanggal: json['tanggal'] as String,
      tipe: json['tipe'] as String,
      waktu: json['waktu'] as String,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      status: (json['status'] as num).toInt(),
      verifikatorId: json['verifikatorId'] as String?,
      waktuVerifikasi: json['waktuVerifikasi'] as String?,
      alasanPenolakan: json['alasanPenolakan'] as String?,
      keterangan: json['keterangan'] as String?,
      deviceId: json['deviceId'] as String?,
      syncAt: json['syncAt'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

/// Response presigned URL dari backend
class PresignedUrlResponse {
  final String uploadUrl;
  final String publicUrl;
  final String? fileName;

  const PresignedUrlResponse({
    required this.uploadUrl,
    required this.publicUrl,
    this.fileName,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      publicUrl: json['publicUrl'] as String,
      fileName: json['fileName'] as String?,
    );
  }
}

/// Koordinat GPS
class Coordinates {
  final double latitude;
  final double longitude;
  final double? accuracy;

  const Coordinates({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });
}

/// Hasil validasi geofence
class GeofenceResult {
  final bool isInRadius;
  final int distance; // jarak dalam meter
  final Coordinates coordinates;

  const GeofenceResult({
    required this.isInRadius,
    required this.distance,
    required this.coordinates,
  });
}

/// Status sinkronisasi
class SyncStatus {
  final int pendingCount;
  final String? lastSyncAt;
  final bool isRunning;
  final String? lastError;

  const SyncStatus({
    this.pendingCount = 0,
    this.lastSyncAt,
    this.isRunning = false,
    this.lastError,
  });

  SyncStatus copyWith({
    int? pendingCount,
    String? lastSyncAt,
    bool? isRunning,
    String? lastError,
  }) {
    return SyncStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isRunning: isRunning ?? this.isRunning,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Item log presensi yang siap dikirim untuk sinkronisasi
class SyncLogItem {
  final String id;
  final String pegawaiId;
  final String pengaturanId;
  final String tanggal;
  final String tipe;
  final String waktu;
  final String latitude;
  final String longitude;
  final String? fotoUrl;
  final String deviceId;

  const SyncLogItem({
    required this.id,
    required this.pegawaiId,
    required this.pengaturanId,
    required this.tanggal,
    required this.tipe,
    required this.waktu,
    required this.latitude,
    required this.longitude,
    this.fotoUrl,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pegawaiId': pegawaiId,
        'pengaturanId': pengaturanId,
        'tanggal': tanggal,
        'tipe': tipe,
        'waktu': waktu,
        'latitude': latitude,
        'longitude': longitude,
        'fotoUrl': fotoUrl,
        'deviceId': deviceId,
      };
}
