import '../models/document_model.dart';

enum VoiceCommandType { open, search, category, clear, showAll, unknown }

class VoiceCommand {
  final VoiceCommandType type;
  final String? value;

  const VoiceCommand({required this.type, this.value});
}

class VoiceCommandService {
  VoiceCommand parseCommand(String transcription) {
    final String command = transcription.trim();

    if (command.isEmpty) {
      return const VoiceCommand(type: VoiceCommandType.unknown);
    }

    final String normalized = command.toLowerCase();

    if (_matchesAny(normalized, [
      'clear',
      'clear search',
      'clear the search',
      'remove search',
      'reset search',
    ])) {
      return const VoiceCommand(type: VoiceCommandType.clear);
    }

    if (_matchesAny(normalized, [
      'show all',
      'show all documents',
      'show my documents',
      'show all my documents',
      'display all documents',
      'display my documents',
    ])) {
      return const VoiceCommand(type: VoiceCommandType.showAll);
    }

    // Explicit "open" commands are the only voice commands that open a
    // document. Normal voice search never opens a file automatically.
    final String? openQuery = _extractCommandValue(normalized, [
      'please open my ',
      'please open the ',
      'please open ',
      'can you open my ',
      'can you open the ',
      'can you open ',
      'open my ',
      'open the ',
      'open ',
    ]);

    if (openQuery != null && openQuery.isNotEmpty) {
      return VoiceCommand(
        type: VoiceCommandType.open,
        value: _cleanDocumentQuery(openQuery),
      );
    }

    // Category commands are deliberately explicit. This prevents a normal
    // search such as "database documents" from being treated as a category.
    final String? categoryQuery = _extractCommandValue(normalized, [
      'show my ',
      'show ',
      'display my ',
      'display ',
      'find my ',
      'find ',
    ]);

    if (categoryQuery != null && categoryQuery.isNotEmpty) {
      final String cleanedCategory = _cleanCategoryQuery(categoryQuery);

      if (_looksLikeCategoryCommand(cleanedCategory)) {
        return VoiceCommand(
          type: VoiceCommandType.category,
          value: cleanedCategory,
        );
      }
    }

    // Everything else is treated as normal document search. This is the
    // important fallback: the user can simply say a filename or topic.
    final String? searchQuery = _extractCommandValue(normalized, [
      'search for ',
      'search ',
      'find my documents about ',
      'find documents about ',
      'find my documents for ',
      'find documents for ',
      'find my documents ',
      'find documents ',
      'find my ',
      'find ',
      'look for ',
      'look up ',
    ]);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      return VoiceCommand(
        type: VoiceCommandType.search,
        value: _cleanSearchQuery(searchQuery),
      );
    }

    // A plain transcription such as "SDP lab" or "database assignment"
    // should behave exactly like typing it into the search box.
    return VoiceCommand(
      type: VoiceCommandType.search,
      value: _cleanSearchQuery(command),
    );
  }

  List<DocumentModel> findMatchingDocuments({
    required List<DocumentModel> documents,
    required String query,
  }) {
    final String searchQuery = query.trim().toLowerCase();

    if (searchQuery.isEmpty) {
      return <DocumentModel>[];
    }

    final List<String> queryWords = searchQuery
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return documents.where((document) {
      final String name = document.name.toLowerCase();

      if (name.contains(searchQuery)) {
        return true;
      }

      return queryWords.every(name.contains);
    }).toList();
  }

  String? findMatchingCategory({
    required List<DocumentModel> documents,
    required String query,
  }) {
    final String searchQuery = query.trim().toLowerCase();

    if (searchQuery.isEmpty) {
      return null;
    }

    final List<String> categories = documents
        .map((document) => document.category)
        .whereType<String>()
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    for (final String category in categories) {
      if (category.toLowerCase() == searchQuery) {
        return category;
      }
    }

    for (final String category in categories) {
      if (category.toLowerCase().contains(searchQuery) ||
          searchQuery.contains(category.toLowerCase())) {
        return category;
      }
    }

    return null;
  }

  bool _matchesAny(String value, List<String> phrases) {
    return phrases.any((phrase) => value == phrase);
  }

  String? _extractCommandValue(String value, List<String> prefixes) {
    for (final String prefix in prefixes) {
      if (value.startsWith(prefix)) {
        final String result = value.substring(prefix.length).trim();

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return null;
  }

  String _cleanDocumentQuery(String query) {
    String cleaned = query.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^my\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^the\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s+document$'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s+file$'), '');
    return cleaned.trim();
  }

  String _cleanSearchQuery(String query) {
    String cleaned = query.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^(show|display)\s+my\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^(show|display)\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^my\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^the\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^documents?\s+about\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^documents?\s+for\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s+documents?$'), '');
    return cleaned.trim();
  }

  String _cleanCategoryQuery(String query) {
    String cleaned = query.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^my\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^the\s+'), '');
    cleaned = cleaned.replaceFirst(
      RegExp(r'^documents?\s+(in|under|from)\s+'),
      '',
    );
    cleaned = cleaned.replaceFirst(RegExp(r'^documents?\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'\s+documents?$'), '');
    return cleaned.trim();
  }

  bool _looksLikeCategoryCommand(String value) {
    final String normalized = value.toLowerCase();
    return normalized.contains('category') ||
        normalized.contains('college') ||
        normalized.contains('university') ||
        normalized.contains('lab') ||
        normalized.contains('assignment') ||
        normalized.contains('project') ||
        normalized.contains('notes') ||
        normalized.contains('personal') ||
        normalized.contains('work');
  }
}
