import 'package:flutter/material.dart';
import '../widgets/empty_state_widget.dart';
import '../controllers/document_controller.dart';
import '../models/document_model.dart';
import '../controllers/auth_controller.dart';
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

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _isSearchActive = false;

  String? _selectedCategory;

  // ============================================================
  // DOCUMENT CONTROLLER
  // ============================================================

  final DocumentController _documentController = DocumentController();

  // Keep one realtime stream for the lifetime of this screen.
  // This prevents duplicate stream subscriptions when setState()
  // rebuilds the dashboard during document uploads.

  late final Stream<List<DocumentModel>> _documentsStream;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _documentsStream = _documentController.documentsStream;

    _searchController.addListener(_onSearchChanged);
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);

    _searchController.dispose();

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

  void _showVoiceSearchMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice search will be added later.'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: StreamBuilder<List<DocumentModel>>(
          stream: _documentsStream,
          builder: (context, snapshot) {
            // ----------------------------------------------------
            // LOADING
            // ----------------------------------------------------

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // ----------------------------------------------------
            // ERROR
            // ----------------------------------------------------

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load documents.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              );
            }

            // ----------------------------------------------------
            // GET DOCUMENTS
            // ----------------------------------------------------

            final List<DocumentModel> documents = _documentController
                .sortNewestFirst(snapshot.data ?? <DocumentModel>[]);

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

            return Column(
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
                                        onTap: _showVoiceSearchMessage,
                                        child: const Icon(
                                          Icons.mic_rounded,
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
            );
          },
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
              children: categories
                  .map(
                    (category) => CategoryChip(
                      category: category,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        _selectCategory(category);
                      },
                    ),
                  )
                  .toList(),
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
