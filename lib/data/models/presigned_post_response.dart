class PresignedPostResponse {
  final String uploadUrl;
  final String publicUrl;
  final String key;

  const PresignedPostResponse({
    required this.uploadUrl,
    required this.publicUrl,
    required this.key,
  });

  factory PresignedPostResponse.fromJson(Map<String, dynamic> json) {
    return PresignedPostResponse(
      uploadUrl: json['uploadUrl'] as String,
      publicUrl: json['publicUrl'] as String,
      key: json['key'] as String,
    );
  }
}
