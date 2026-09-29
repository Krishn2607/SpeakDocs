import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/empty_state_widget.dart';
import '../controllers/document_controller.dart';
import '../models/document_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/voice_controller.dart';
import '../services/voice_command_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/document_card.dart';
import '../widgets/stat_card.dart';
import 'upload_document_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  final AuthController _authController = AuthController();

  final VoiceController _voiceController = VoiceController();

  final VoiceCommandService _voiceCommandService = VoiceCommandService();

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _isSearchActive = false;
  bool _isVoiceProcessing = false;

  String? _selectedCategory;

  List<DocumentModel> _latestDocuments = <DocumentModel>[];

  // ============================================================
  // DOCUMENT CONTROLLER
  // ============================================================

  final DocumentController _documentController = DocumentController();

  // Keep one realtime stream for the lifetime of this screen.
  // This prevents duplicate stream subscriptions when setState()
  // rebuilds the dashboard during document uploads.

  late Stream<List<DocumentModel>> _documentsStream;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDocumentsStream();

    _searchController.addListener(_onSearchChanged);
  }

  void _loadDocumentsStream() {
    _documentsStream = _documentController.documentsStream;
  }

  void _retryDocuments() {
    setState(() {
      _loadDocumentsStream();
    });
  }

  // ============================================================
  // SEARCH CHANGE
  // ============================================================

  void _onSearchChanged() {
    final bool hasQuery = _searchController.text.trim().isNotEmpty;

    if (_isSearchActive == hasQuery) {
      setState(() {});
      return;
    }

    setState(() {
      _isSearchActive = hasQuery;
    });
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _isSearchActive = false;
    });
  }

  // ============================================================
  // CATEGORY FILTER
  // ============================================================

  void _selectCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _selectAllCategories() {
    setState(() {
      _selectedCategory = null;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);

    _searchController.dispose();
    _voiceController.dispose();

    super.dispose();
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // ============================================================
  // USER NAME
  // ============================================================

  String _getUserName() {
    final String? name = _authController.currentUser?.displayName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'User';
  }

  // ============================================================
  // VOICE SEARCH
  // ============================================================

  Future<void> _toggleVoiceRecording() async {
    if (_isVoiceProcessing) {
      return;
    }

    if (_voiceController.isRecording) {
      await _stopVoiceRecording();
      return;
    }

    try {
      await _voiceController.startRecording();

      if (!mounted) {
        return;
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening... Tap the microphone when finished.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopVoiceRecording() async {
    if (_isVoiceProcessing) {
      return;
    }

    setState(() {
      _isVoiceProcessing = true;
    });

    try {
      final String transcription = await _voiceController.stopAndTranscribe();

      if (!mounted) {
        return;
      }

      await _handleVoiceCommand(transcription);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceProcessing = false;
        });
      }
    }
  }

  Future<void> _handleVoiceCommand(String transcription) async {
    final VoiceCommand command = _voiceCommandService.parseCommand(
      transcription,
    );

    switch (command.type) {
      case VoiceCommandType.open:
        await _handleOpenVoiceCommand(command.value ?? '');
        break;
      case VoiceCommandType.search:
        _handleSearchVoiceCommand(command.value ?? '');
        break;
      case VoiceCommandType.category:
        _handleCategoryVoiceCommand(command.value ?? '');
        break;
      case VoiceCommandType.clear:
        _clearSearch();
        break;
      case VoiceCommandType.showAll:
        _clearSearch();
        setState(() {
          _selectedCategory = null;
        });
        break;
      case VoiceCommandType.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'I could not understand that. Try a document name or say “open” followed by the document name.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  Future<void> _handleOpenVoiceCommand(String query) async {
    final String cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please say the document name you want to open.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final List<DocumentModel> matches = _voiceCommandService
        .findMatchingDocuments(
          documents: _latestDocuments,
          query: cleanedQuery,
        );

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No document found for “$cleanedQuery”.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (matches.length > 1) {
      _searchController.text = cleanedQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );

      setState(() {
        _selectedCategory = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'I found ${matches.length} documents. Please choose one from the results.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _documentController.openDocument(matches.single);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open document. Please check your internet connection and try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSearchVoiceCommand(String query) {
    final String cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please say a document name or search term.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _searchController.text = cleanedQuery;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );

    setState(() {
      _selectedCategory = null;
    });
  }

  void _handleCategoryVoiceCommand(String query) {
    final String? category = _voiceCommandService.findMatchingCategory(
      documents: _latestDocuments,
      query: query,
    );

    if (category == null) {
      _handleSearchVoiceCommand(query);
      return;
    }

    _searchController.clear();

    setState(() {
      _selectedCategory = category;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing “$category” documents.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await _authController.logout();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentModel>>(
      stream: _documentsStream,
      builder: (context, snapshot) {
        // ----------------------------------------------------
        // LOADING
        // ----------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F6FA),
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        // ----------------------------------------------------
        // ERROR
        // ----------------------------------------------------

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Connection problem',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF171C35),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to load your documents.\n'
                        'Please check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: _retryDocuments,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // ----------------------------------------------------
        // GET DOCUMENTS
        // ----------------------------------------------------

        final List<DocumentModel> documents = _documentController
            .sortNewestFirst(snapshot.data ?? <DocumentModel>[]);

        _latestDocuments = documents;

        // ----------------------------------------------------
        // APPLY CATEGORY FILTER
        // ----------------------------------------------------

        final List<DocumentModel> categoryResults = _documentController
            .filterByCategory(
              documents: documents,
              category: _selectedCategory,
            );

        // ----------------------------------------------------
        // APPLY SEARCH FILTER
        // ----------------------------------------------------

        final List<DocumentModel> filteredDocuments = _documentController
            .searchDocuments(
              documents: categoryResults,
              query: _searchController.text,
            );

        // ----------------------------------------------------
        // GET UNIQUE CATEGORIES
        // ----------------------------------------------------

        final List<String> categories = _documentController.getCategories(
          documents,
        );

        // ----------------------------------------------------
        // MAIN DASHBOARD
        // ----------------------------------------------------

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                  decoration: const BoxDecoration(color: Color(0xFF171C35)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --------------------------------------------
                      // TOP ROW
                      // --------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              color: Color(0xFFD8DBE7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            onPressed: _isSearchActive ? _clearSearch : _logout,
                            icon: Icon(
                              _isSearchActive
                                  ? Icons.close_rounded
                                  : Icons.logout_rounded,
                              color: const Color(0xFFD8DBE7),
                              size: 22,
                            ),
                            tooltip: _isSearchActive
                                ? 'Close search'
                                : 'Logout',
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // --------------------------------------------
                      // USER NAME
                      // --------------------------------------------
                      Text(
                        _getUserName(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 17),

                      // --------------------------------------------
                      // SEARCH BAR
                      // --------------------------------------------
                      Container(
                        height: 47,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Color(0xFF171C35),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search documents...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF7C8291),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF72798A),
                            ),
                            suffixIcon: _isSearchActive
                                ? IconButton(
                                    onPressed: _clearSearch,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF72798A),
                                    ),
                                    tooltip: 'Clear search',
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Material(
                                      color: const Color(0xFF6C63FF),
                                      borderRadius: BorderRadius.circular(10),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: _toggleVoiceRecording,
                                        child: _isVoiceProcessing
                                            ? const SizedBox(
                                                width: 19,
                                                height: 19,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Icon(
                                                _voiceController.isRecording
                                                    ? Icons.stop_rounded
                                                    : Icons.mic_rounded,
                                                color: Colors.white,
                                                size: 19,
                                              ),
                                      ),
                                    ),
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // CONTENT
                // ==================================================
                Expanded(
                  child: _isSearchActive
                      ? _buildSearchResults(filteredDocuments)
                      : _buildDashboard(
                          documents,
                          filteredDocuments,
                          categories,
                        ),
                ),
              ],
            ),
          ),

          // ============================================================
          // UPLOAD BUTTON
          // ============================================================
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
              );
            },
            backgroundColor: const Color(0xFF4DB58A),
            elevation: 2,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        );
      },
    );
  }

  // ============================================================
  // NORMAL DASHBOARD
  // ============================================================

  Widget _buildDashboard(
    List<DocumentModel> documents,
    List<DocumentModel> filteredDocuments,
    List<String> categories,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(9, 16, 9, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // STATISTICS
          // ==========================================
          Row(
            children: [
              Expanded(
                child: StatCard(
                  value: documents.length.toString(),
                  label: 'Documents',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  value: categories.length.toString(),
                  label: 'Categories',
                  icon: Icons.folder_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ==========================================
          // CATEGORIES
          // ==========================================
          const Text(
            'Categories',
            style: TextStyle(
              color: Color(0xFF171C35),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          if (categories.isEmpty)
            const Text(
              'No categories yet',
              style: TextStyle(color: Color(0xFF8A8F9D), fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CategoryChip(
                  category: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: _selectAllCategories,
                ),
                ...categories.map(
                  (category) => CategoryChip(
                    category: category,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      _selectCategory(category);
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // ==========================================
          // RECENT DOCUMENTS
          // ==========================================
          const Text(
            'Recent documents',
            style: TextStyle(
              color: Color(0xFF171C35),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          if (documents.isEmpty)
            _buildEmptyDocuments()
          else if (filteredDocuments.isEmpty)
            _buildNoCategoryResults()
          else
            Column(
              children: filteredDocuments
                  .take(5)
                  .map((document) => DocumentCard(document: document))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  Widget _buildSearchResults(List<DocumentModel> searchResults) {
    final String query = _searchController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // SEARCH RESULT LABEL
          // ========================================================
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _selectedCategory == null
                    ? 'Showing results for "$query"'
                    : 'Showing "$_selectedCategory" results for "$query"',
                style: const TextStyle(
                  color: Color(0xFF5B54C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ========================================================
          // NO RESULTS
          // ========================================================
          if (searchResults.isEmpty)
            _buildNoSearchResults(query)
          // ========================================================
          // RESULTS
          // ========================================================
          else
            Column(
              children: searchResults
                  .map((document) => DocumentCard(document: document))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NO SEARCH RESULTS
  // ============================================================

  Widget _buildNoSearchResults(String query) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No documents found',
      message: _selectedCategory == null
          ? 'No documents match "$query".'
          : 'No "$_selectedCategory" documents match "$query".',
    );
  }

  // ============================================================
  // EMPTY DOCUMENT STATE
  // ============================================================

  Widget _buildEmptyDocuments() {
    return const EmptyStateWidget(
      icon: Icons.folder_open_outlined,
      title: 'No documents yet',
      message: 'Upload your first document to get started.',
    );
  }

  // ============================================================
  // NO CATEGORY RESULTS
  // ============================================================

  Widget _buildNoCategoryResults() {
    return const EmptyStateWidget(
      icon: Icons.folder_open_outlined,
      title: 'No documents in this category',
      message: 'Try selecting another category.',
    );
  }
}
