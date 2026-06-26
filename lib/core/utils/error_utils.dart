// ====================================
// Error Utilities
// ====================================

String getErrorMessage(dynamic error) {
  if (error is Exception) {
    return error.toString().replaceFirst('Exception: ', '');
  }
  if (error is Error) {
    return error.toString();
  }
  if (error is String) {
    return error;
  }
  return '';
}
