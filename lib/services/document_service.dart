import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // SUPABASE STORAGE BUCKET
  // ============================================================

  static const String _bucketName = 'documents';

  // ============================================================
  // ALLOWED FILE EXTENSIONS
  // ============================================================

  static const List<String> _allowedExtensions = ['pdf', 'doc', 'docx'];

  // ============================================================
  // PICK DOCUMENT
  // ============================================================
  //
  // Opens the device file picker and returns the selected file.
  //
  // The actual upload is handled separately so the UI can show
  // the selected file before uploading it.
  //

  Future<PlatformFile?> pickDocument() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );

    // User cancelled the picker.
    if (files.isEmpty) {
      return null;
    }

    return files.first;
  }

  // ============================================================
  // UPLOAD DOCUMENT
  // ============================================================

  Future<void> uploadDocument({
    required PlatformFile selectedFile,
    required String category,
  }) async {
    // ----------------------------------------------------------
    // 1. Get current Firebase user
    // ----------------------------------------------------------

    final firebase_auth.User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // ----------------------------------------------------------
    // 2. Validate file name
    // ----------------------------------------------------------

    final String fileName = selectedFile.name.trim();

    if (fileName.isEmpty) {
      throw Exception('The selected file has an invalid name.');
    }

    // ----------------------------------------------------------
    // 3. Get extension
    // ----------------------------------------------------------

    String extension = '';

    if (fileName.contains('.')) {
      extension = fileName.split('.').last.toLowerCase();
    }

    if (!_allowedExtensions.contains(extension)) {
      throw Exception('Only PDF, DOC or DOCX files are supported.');
    }

    // ----------------------------------------------------------
    // 4. Validate category
    // ----------------------------------------------------------

    final String documentCategory = category.trim();

    if (documentCategory.isEmpty) {
      throw Exception('Please select a category.');
    }

    // ----------------------------------------------------------
    // 5. Get file bytes
    // ----------------------------------------------------------

    final bytes = await selectedFile.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('Unable to read selected file.');
    }

    // ----------------------------------------------------------
    // 6. Get file size
    // ----------------------------------------------------------

    final int fileSize = bytes.length;

    // ----------------------------------------------------------
    // 7. Create unique Supabase Storage path
    //
    // Example:
    //
    // userId/
    // 1756123456_resume.pdf
    // ----------------------------------------------------------

    final String storagePath =
        '${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // ----------------------------------------------------------
    // 8. Upload file to Supabase Storage
    // ----------------------------------------------------------

    try {
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: false),
          );
    } catch (_) {
      throw Exception(
        'Upload failed. Please check your internet connection and try again.',
      );
    }

    // ----------------------------------------------------------
    // 9. Save document metadata in Supabase
    // ----------------------------------------------------------
    //
    // If the database insert fails, the file has already been
    // uploaded to Storage. We therefore try to remove it so
    // that an orphaned Storage file is not left behind.
    //

    try {
      await _supabase.from('documents').insert({
        'user_id': user.uid,
        'name': fileName,
        'extension': extension,
        'size': _formatFileSize(fileSize),
        'size_bytes': fileSize,
        'storage_path': storagePath,
        'category': documentCategory,
      });
    } catch (_) {
      // --------------------------------------------------------
      // Cleanup Storage file after database failure
      // --------------------------------------------------------

      try {
        await _supabase.storage.from(_bucketName).remove([storagePath]);
      } catch (_) {
        throw Exception(
          'Document upload could not be completed and temporary cleanup failed. Please try again.',
        );
      }

      throw Exception('Unable to save document information. Please try again.');
    }
  }

  // ============================================================
  // GET CURRENT USER DOCUMENTS
  // ============================================================

  Stream<List<Map<String, dynamic>>> getUserDocuments() {
    final firebase_auth.User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .order('uploaded_at', ascending: false);
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> deleteDocument({
    required String documentId,
    required String storagePath,
  }) async {
    final firebase_auth.User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    if (documentId.isEmpty || storagePath.isEmpty) {
      throw Exception('Invalid document information.');
    }

    // ----------------------------------------------------------
    // 1. Delete actual file from Supabase Storage
    // ----------------------------------------------------------

    await _supabase.storage.from(_bucketName).remove([storagePath]);

    // ----------------------------------------------------------
    // 2. Delete document metadata from Supabase database
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> deletedRows = await _supabase
        .from('documents')
        .delete()
        .eq('id', documentId)
        .eq('user_id', user.uid)
        .select('id');

    // ----------------------------------------------------------
    // 3. Verify that the database row was actually deleted
    // ----------------------------------------------------------

    if (deletedRows.isEmpty) {
      throw Exception(
        'Document file was removed, but the database row was not deleted.',
      );
    }
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================
  //
  // The documents bucket is private.
  //
  // Therefore we create a temporary signed URL instead of using
  // getPublicUrl().
  //
  // The signed URL remains valid for 5 minutes.
  //

  Future<void> openDocument({required String storagePath}) async {
    if (storagePath.isEmpty) {
      throw Exception('Invalid document storage path.');
    }

    final String signedUrl = await _supabase.storage
        .from(_bucketName)
        .createSignedUrl(storagePath, 300);

    final Uri uri = Uri.parse(signedUrl);

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );

    if (!launched) {
      throw Exception('Unable to open document.');
    }
  }

  // ============================================================
  // FORMAT FILE SIZE
  // ============================================================

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      final double kb = bytes / 1024;

      return '${kb.toStringAsFixed(1)} KB';
    }

    final double mb = bytes / (1024 * 1024);

    return '${mb.toStringAsFixed(1)} MB';
  }
}
