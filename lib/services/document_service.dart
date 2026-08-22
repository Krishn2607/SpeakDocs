import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class DocumentService {
  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // PICK AND UPLOAD DOCUMENT
  // ============================================================

  Future<void> pickAndUploadDocument() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Open file picker
    final List<PlatformFile> result =
    await FilePicker.pickFiles(
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
      ],
    );

    // User cancelled the picker
    if (result.isEmpty) {
      return;
    }

    final PlatformFile selectedFile =
        result.single;

    final String fileName =
        selectedFile.name;

    final String? filePath =
        selectedFile.path;

    if (filePath == null) {
      throw Exception(
        'Unable to access selected file.',
      );
    }

    final File file =
    File(filePath);

    // Get extension from file name
    String extension = '';

    if (fileName.contains('.')) {
      extension =
          fileName.split('.').last.toLowerCase();
    }

    // Get actual file size
    final int fileSize =
    await file.length();

    // Create unique Firebase Storage path
    final String storagePath =
        'documents/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final Reference storageReference =
    _storage.ref().child(storagePath);

    // Upload actual file to Firebase Storage
    await storageReference.putFile(file);

    // Get download URL
    final String downloadUrl =
    await storageReference.getDownloadURL();

    // Save document information in Firestore
    await _firestore
        .collection('documents')
        .add({
      'userId': user.uid,
      'name': fileName,
      'extension': extension,
      'size': _formatFileSize(fileSize),
      'sizeBytes': fileSize,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'category': 'General',
      'uploadedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GET CURRENT USER DOCUMENTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
  getUserDocuments() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('documents')
        .where(
      'userId',
      isEqualTo: user.uid,
    )
        .snapshots();
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