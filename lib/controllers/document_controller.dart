import 'package:file_picker/file_picker.dart';

import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentController {
  final DocumentService _documentService;

  DocumentController({DocumentService? documentService})
    : _documentService = documentService ?? DocumentService();

  // ============================================================
  // GET USER DOCUMENTS
  // ============================================================
  //
  // Keep one realtime stream for the lifetime of the controller.
  // This prevents duplicate stream subscriptions when the UI
  // rebuilds during document uploads or other state changes.
  //

  Stream<List<DocumentModel>> get documentsStream {
    return _documentService.getUserDocuments().map((documents) {
      return documents
          .map((document) => DocumentModel.fromMap(document))
          .toList();
    });
  }

  // ============================================================
  // PICK DOCUMENT
  // ============================================================

  Future<PlatformFile?> pickDocument() async {
    return await _documentService.pickDocument();
  }

  // ============================================================
  // UPLOAD DOCUMENT
  // ============================================================

  Future<void> uploadDocument({
    required PlatformFile selectedFile,
    required String category,
  }) async {
    await _documentService.uploadDocument(
      selectedFile: selectedFile,
      category: category,
    );
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================

  Future<void> openDocument(DocumentModel document) async {
    await _documentService.openDocument(storagePath: document.storagePath);
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> deleteDocument(DocumentModel document) async {
    await _documentService.deleteDocument(
      documentId: document.id,
      storagePath: document.storagePath,
    );
  }

  // ============================================================
  // SEARCH DOCUMENTS
  // ============================================================
  //
  // Searches the documents already loaded by the realtime stream.
  //
  // Search is performed against:
  //
  // 1. Document name
  // 2. Document category
  //
  // Search is case-insensitive.
  //
  // No new Supabase request is made while searching.
  //

  List<DocumentModel> searchDocuments({
    required List<DocumentModel> documents,
    required String query,
  }) {
    final String searchQuery = query.trim().toLowerCase();

    // If there is no search query, return all documents.
    if (searchQuery.isEmpty) {
      return documents;
    }

    return documents.where((document) {
      final String name = document.name.toLowerCase();

      final String category = document.category?.toLowerCase() ?? '';

      return name.contains(searchQuery) || category.contains(searchQuery);
    }).toList();
  }

  // ============================================================
  // FILTER DOCUMENTS BY CATEGORY
  // ============================================================
  //
  // Returns only documents belonging to the selected category.
  //
  // If no category is selected, all documents are returned.
  //

  List<DocumentModel> filterByCategory({
    required List<DocumentModel> documents,
    required String? category,
  }) {
    if (category == null || category.isEmpty) {
      return documents;
    }

    return documents.where((document) {
      final String documentCategory = document.category ?? '';

      return documentCategory.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  // ============================================================
  // DOCUMENT HELPERS
  // ============================================================

  List<String> getCategories(List<DocumentModel> documents) {
    final Set<String> categorySet = {};

    for (final DocumentModel document in documents) {
      final String? category = document.category;

      if (category != null && category.isNotEmpty) {
        categorySet.add(category);
      }
    }

    return categorySet.toList();
  }

  List<DocumentModel> sortNewestFirst(List<DocumentModel> documents) {
    final List<DocumentModel> sortedDocuments = List<DocumentModel>.from(
      documents,
    );

    sortedDocuments.sort((a, b) {
      final DateTime? aTime = a.uploadedAt;

      final DateTime? bTime = b.uploadedAt;

      if (aTime == null && bTime == null) {
        return 0;
      }

      if (aTime == null) {
        return 1;
      }

      if (bTime == null) {
        return -1;
      }

      return bTime.compareTo(aTime);
    });

    return sortedDocuments;
  }
}
