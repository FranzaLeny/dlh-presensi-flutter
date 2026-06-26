// ====================================
// Location Service — GPS & Geofence
// ====================================

import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../data/models/sync_response.dart';

class LocationService {
  LocationService._();

  /// Request permission dan ambil posisi GPS saat ini
  static Future<Coordinates> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Izin lokasi ditolak. Aktifkan akses lokasi di pengaturan.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return Coordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  /// Validasi apakah user berada dalam radius kantor
  static bool isInRadius(
    double userLat,
    double userLon,
    double officeLat,
    double officeLon,
    double radiusMeters,
  ) {
    final distance = _haversineDistance(userLat, userLon, officeLat, officeLon);
    return distance <= radiusMeters;
  }

  /// Cek geofence lengkap — return detail hasil
  static Future<GeofenceResult> checkGeofence(
    double officeLat,
    double officeLon,
    int radiusMeters,
  ) async {
    final coordinates = await getCurrentPosition();
    final distance = _haversineDistance(
      coordinates.latitude,
      coordinates.longitude,
      officeLat,
      officeLon,
    );

    return GeofenceResult(
      isInRadius: distance <= radiusMeters,
      distance: distance.round(),
      coordinates: coordinates,
    );
  }

  /// Hitung jarak antara dua titik (exposed utility)
  static double getDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _haversineDistance(lat1, lon1, lat2, lon2);
  }

  /// Haversine Formula — menghitung jarak antara dua koordinat GPS
  /// @returns jarak dalam meter
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371e3; // radius bumi dalam meter
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
