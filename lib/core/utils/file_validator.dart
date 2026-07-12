import 'dart:io';

class FileValidator {
  static const Map<String, int> _maxSizeBytes = {
    'presensi': 2 * 1024 * 1024, // 2 MB
    'profile': 2 * 1024 * 1024, // 2 MB
  };

  static const Map<String, List<String>> _allowedTypes = {
    'presensi': [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'application/pdf'
    ],
    'profile': ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
  };

  static String? validate(String entity, File file, String contentType) {
    final maxSize = _maxSizeBytes[entity];
    if (maxSize != null && file.lengthSync() > maxSize) {
      final maxMb = maxSize ~/ (1024 * 1024);
      return 'Ukuran file melebihi batas maksimum $maxMb MB.';
    }

    final allowed = _allowedTypes[entity];
    if (allowed != null && !allowed.contains(contentType)) {
      return 'Format file tidak didukung.';
    }

    return null; // valid
  }
}
