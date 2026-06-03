class FileUploadResponse {
  final String objectName;
  final String fileName;
  final int size;
  final String contentType;
  final String? url;

  FileUploadResponse({
    required this.objectName,
    required this.fileName,
    required this.size,
    required this.contentType,
    this.url,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      objectName: json['objectName']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      contentType: json['contentType']?.toString() ?? '',
      url: json['url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectName': objectName,
      'fileName': fileName,
      'size': size,
      'contentType': contentType,
      'url': url,
    };
  }
}