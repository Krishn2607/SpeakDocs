import 'package:file_picker/file_picker.dart';

import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentController {
  final DocumentService _documentService;

  DocumentController({
    DocumentService? documentService,
  }) : _documentService =
      documentService ?? DocumentService();

  // ============================================================
  // GET USER DOCUMENTS
  // ============================================================
  //
  // Keep one realtime stream for the lifetime of the controller.
  // This prevents duplicate stream subscriptions when the UI
  // rebuilds during document uploads or other state changes.
  //

  late final Stream<List<DocumentModel>> documentsStream =
  _documentService.getUserDocuments().map(
        (documents) {
      return documents
          .map(
            (document) =>
            DocumentModel.fromMap(document),
      )
          .toList();
    },
  );

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
  // DOCUMENT HELPERS
  // ============================================================

  List<String> getCategories(
      List<DocumentModel> documents,
      ) {
    final Set<String> categorySet = {};

    for (final DocumentModel document
    in documents) {
      final String? category =
          document.category;

      if (category != null &&
          category.isNotEmpty) {
        categorySet.add(category);
      }
    }

    return categorySet.toList();
  }

  List<DocumentModel> sortNewestFirst(
      List<DocumentModel> documents,
      ) {
    final List<DocumentModel>
    sortedDocuments =
    List<DocumentModel>.from(
      documents,
    );

    sortedDocuments.sort(
          (a, b) {
        final DateTime? aTime =
            a.uploadedAt;

        final DateTime? bTime =
            b.uploadedAt;

        if (aTime == null &&
            bTime == null) {
          return 0;
        }

        if (aTime == null) {
          return 1;
        }

        if (bTime == null) {
          return -1;
        }

        return bTime.compareTo(aTime);
      },
    );

    return sortedDocuments;
  }
}