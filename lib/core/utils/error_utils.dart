// ====================================
// Error Utilities
// ====================================

import 'package:dio/dio.dart';

String getErrorMessage(dynamic error) {
  if (error is DioException) {
    if (error.response != null && error.response!.data != null) {
      final data = error.response!.data;
      if (data is Map) {
        if (data.containsKey('message') && data['message'] != null) {
          return data['message'].toString();
        }
        if (data.containsKey('error') && data['error'] != null) {
          return data['error'].toString();
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    
    // Fallback error berdasarkan tipe DioException
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server timeout. Silakan coba lagi.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return error.message ?? 'Terjadi kesalahan jaringan.';
  }

  if (error is Exception) {
    return error.toString().replaceFirst('Exception: ', '');
  }
  if (error is Error) {
    return 'Terjadi kesalahan sistem. Silakan hubungi admin atau coba lagi.';
  }
  if (error is String) {
    return error;
  }
  return '';
}
