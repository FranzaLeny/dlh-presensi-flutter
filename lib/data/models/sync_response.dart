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
  final int status;
  final int isLuarRadius;
  final String? keterangan;

  const SyncedItem({
    required this.id,
    required this.status,
    required this.isLuarRadius,
    this.keterangan,
  });

  factory SyncedItem.fromJson(Map<String, dynamic> json) {
    return SyncedItem(
      id: json['id'] as String,
      status: (json['status'] as num).toInt(),
      isLuarRadius: (json['isLuarRadius'] as num?)?.toInt() ?? 0,
      keterangan: json['keterangan'] as String?,
    );
  }
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
