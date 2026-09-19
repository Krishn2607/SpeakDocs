import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentService {
  final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // SUPABASE STORAGE BUCKET
  // ============================================================

  static const String _bucketName = 'documents';

  // ============================================================
  // PICK AND UPLOAD DOCUMENT
  // ============================================================

  Future<void> pickAndUploadDocument() async {
    // ----------------------------------------------------------
    // 1. Get current Firebase user
    // ----------------------------------------------------------

    final firebase_auth.User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // ----------------------------------------------------------
    // 2. Open file picker
    // ----------------------------------------------------------

    final List<PlatformFile> files =
    await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
      ],
    );

    // User cancelled the picker
    if (files.isEmpty) {
      return;
    }

    final PlatformFile selectedFile =
        files.first;

    final String fileName =
        selectedFile.name;

    // ----------------------------------------------------------
    // 3. Get file bytes
    // ----------------------------------------------------------

    final bytes =
    await selectedFile.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception(
        'Unable to read selected file.',
      );
    }

    // ----------------------------------------------------------
    // 4. Get extension
    // ----------------------------------------------------------

    String extension = '';

    if (fileName.contains('.')) {
      extension =
          fileName.split('.').last.toLowerCase();
    }

    // ----------------------------------------------------------
    // 5. Get file size
    // ----------------------------------------------------------

    final int fileSize =
        bytes.length;

    // ----------------------------------------------------------
    // 6. Create unique Supabase Storage path
    //
    // Example:
    //
    // btxfmirnu4b5hQbrm0YFtWn6Cxm1/
    // 1756123456_resume.pdf
    // ----------------------------------------------------------

    final String storagePath =
        '${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // ----------------------------------------------------------
    // 7. Upload file to Supabase Storage
    // ----------------------------------------------------------

    await _supabase.storage
        .from(_bucketName)
        .uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        upsert: false,
      ),
    );

    // ----------------------------------------------------------
    // 8. Save document metadata in Supabase
    // ----------------------------------------------------------

    await _supabase
        .from('documents')
        .insert({
      'user_id': user.uid,
      'name': fileName,
      'extension': extension,
      'size': _formatFileSize(fileSize),
      'size_bytes': fileSize,
      'storage_path': storagePath,
      'category': 'General',
    });
  }

  // ============================================================
  // GET CURRENT USER DOCUMENTS
  // ============================================================

  Stream<List<Map<String, dynamic>>>
  getUserDocuments() {
    final firebase_auth.User? user =
        _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.uid)
        .order(
      'uploaded_at',
      ascending: false,
    );
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> deleteDocument(
      Map<String, dynamic> document,
      ) async {
    final firebase_auth.User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final String? storagePath =
    document['storage_path'] as String?;

    final String? documentId =
    document['id']?.toString();

    if (storagePath == null ||
        documentId == null) {
      throw Exception(
        'Invalid document information.',
      );
    }

    // ----------------------------------------------------------
    // 1. Delete actual file from Supabase Storage
    // ----------------------------------------------------------

    await _supabase.storage
        .from(_bucketName)
        .remove([
      storagePath,
    ]);

    // ----------------------------------------------------------
    // 2. Delete metadata from Supabase database
    // ----------------------------------------------------------

    await _supabase
        .from('documents')
        .delete()
        .eq('id', documentId)
        .eq('user_id', user.uid);
  }

  // ============================================================
  // GET FILE URL
  // ============================================================

  String getFileUrl(
      String storagePath,
      ) {
    return _supabase.storage
        .from(_bucketName)
        .getPublicUrl(storagePath);
  }

  // ============================================================
  // FORMAT FILE SIZE
  // ============================================================

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      final double kb =
          bytes / 1024;

      return '${kb.toStringAsFixed(1)} KB';
    }

    final double mb =
        bytes / (1024 * 1024);

    return '${mb.toStringAsFixed(1)} MB';
  }
}