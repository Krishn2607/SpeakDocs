class DocumentModel {
  final String id;
  final String userId;
  final String name;
  final String? extension;
  final String? size;
  final int? sizeBytes;
  final String storagePath;
  final String? category;
  final DateTime? uploadedAt;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.name,
    this.extension,
    this.size,
    this.sizeBytes,
    required this.storagePath,
    this.category,
    this.uploadedAt,
  });

  // ============================================================
  // CREATE DOCUMENT MODEL FROM SUPABASE DATA
  // ============================================================

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      extension: map['extension']?.toString(),
      size: map['size']?.toString(),
      sizeBytes: map['size_bytes'] is int
          ? map['size_bytes'] as int
          : int.tryParse(map['size_bytes']?.toString() ?? ''),
      storagePath: map['storage_path']?.toString() ?? '',
      category: map['category']?.toString(),
      uploadedAt: map['uploaded_at'] != null
          ? DateTime.tryParse(map['uploaded_at'].toString())
          : null,
    );
  }

  // ============================================================
  // CONVERT DOCUMENT MODEL BACK TO A MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'extension': extension,
      'size': size,
      'size_bytes': sizeBytes,
      'storage_path': storagePath,
      'category': category,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}
