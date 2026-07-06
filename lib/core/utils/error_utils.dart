// ====================================
// Error Utilities
// ====================================

import 'package:dio/dio.dart';

/// Pesan fallback berdasarkan HTTP status code
String _httpStatusMessage(int statusCode) {
  return switch (statusCode) {
    400 => 'Permintaan tidak valid. Silakan periksa kembali data Anda.',
    401 => 'Sesi Anda telah berakhir. Silakan login kembali.',
    403 => 'Anda tidak memiliki akses untuk melakukan tindakan ini.',
    404 => 'Data yang diminta tidak ditemukan.',
    405 => 'Metode permintaan tidak didukung oleh server.',
    408 => 'Koneksi ke server timeout. Silakan coba lagi.',
    409 => 'Terjadi konflik data. Silakan coba lagi.',
    413 => 'Ukuran file terlalu besar untuk diunggah.',
    422 => 'Data yang dikirim tidak valid atau tidak lengkap.',
    429 => 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.',
    >= 500 && < 600 => 'Server sedang mengalami gangguan. Silakan coba lagi nanti.',
    _ => 'Terjadi kesalahan pada server (Status: $statusCode).',
  };
}

/// Memeriksa apakah pesan error mengandung istilah teknis/sistem
bool _isTechnicalMessage(String msg) {
  final cleanMsg = msg.toLowerCase();
  final technicalKeywords = [
    'sql',
    'database',
    'query',
    'syntax',
    'null pointer',
    'exception',
    'dioexception',
    'socketexception',
    'handshake',
    'failed to',
    'unexpected',
    'undefined',
    'unauthorized',
    'forbidden',
    'not found',
    'internal server error',
    'bad gateway',
    'service unavailable',
    'method not allowed',
    'argument',
    'type cast',
    'stacktrace',
    'table',
    'column',
    'row',
    'invalid signature',
    'crypto',
    'rsa',
    'keypair',
  ];
  
  return technicalKeywords.any((keyword) => cleanMsg.contains(keyword));
}

/// Mendapatkan pesan error yang ramah untuk user (end-user friendly) dalam Bahasa Indonesia
String getErrorMessage(dynamic error) {
  if (error == null) return 'Terjadi kesalahan yang tidak diketahui.';

  if (error is DioException) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      // Jika server mengembalikan detail error
      if (data != null && data is Map) {
        String? serverMsg;
        if (data.containsKey('message') && data['message'] != null) {
          serverMsg = data['message'].toString();
        } else if (data.containsKey('error') && data['error'] != null) {
          serverMsg = data['error'].toString();
        }
        
        // Validasi apakah pesan dari server aman untuk ditampilkan ke user
        if (serverMsg != null && serverMsg.isNotEmpty && !_isTechnicalMessage(serverMsg)) {
          return serverMsg;
        }
      } else if (data is String && data.isNotEmpty && !_isTechnicalMessage(data)) {
        return data;
      }
      
      // Gunakan mapping HTTP status code jika tidak ada pesan aman dari server
      if (statusCode != null) {
        return _httpStatusMessage(statusCode);
      }
    }
    
    // Fallback berdasarkan tipe DioException
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server lambat. Silakan periksa koneksi internet Anda dan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Silakan periksa koneksi internet Anda.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        break;
    }
    
    return 'Terjadi masalah jaringan. Pastikan perangkat Anda terhubung ke internet.';
  }

  // Handle Exception standard
  if (error is Exception) {
    final msg = error.toString().replaceFirst('Exception: ', '').trim();
    if (msg.isEmpty) {
      return 'Terjadi kesalahan pada sistem.';
    }
    if (_isTechnicalMessage(msg)) {
      return 'Terjadi kesalahan sistem. Silakan coba lagi.';
    }
    return msg;
  }

  // Handle Error standard (sistem/runtime)
  if (error is Error) {
    return 'Terjadi kesalahan sistem. Silakan hubungi admin atau coba beberapa saat lagi.';
  }

  // Handle String
  if (error is String) {
    final trimmed = error.trim();
    if (_isTechnicalMessage(trimmed)) {
      return 'Terjadi kesalahan sistem.';
    }
    return trimmed.isNotEmpty ? trimmed : 'Terjadi kesalahan yang tidak diketahui.';
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}

