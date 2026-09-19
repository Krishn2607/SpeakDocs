import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/document_service.dart';
import 'login_screen.dart';

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

  // ============================================================
  // CURRENT USER
  // ============================================================

  final User? _user = FirebaseAuth.instance.currentUser;

  // ============================================================
  // DOCUMENT SERVICE
  // ============================================================

  final DocumentService _documentService = DocumentService();

  bool _isUploading = false;

  // Keep one realtime stream for the lifetime of this screen.
  // This prevents duplicate stream subscriptions when setState()
  // rebuilds the dashboard during document uploads.
  late final Stream<List<Map<String, dynamic>>> _documentsStream;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _documentsStream = _documentService.getUserDocuments();
  }

  @override
  void dispose() {
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
    final String? name = _user?.displayName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'User';
  }

  // ============================================================
  // UPLOAD DOCUMENT
  // ============================================================

  Future<void> _uploadDocument() async {
    if (_isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _documentService.pickAndUploadDocument();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully!'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
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
    await AuthService().logout();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
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

            final List<Map<String, dynamic>> documents =
                List<Map<String, dynamic>>.from(snapshot.data ?? []);

            // ----------------------------------------------------
            // SORT NEWEST FIRST
            // ----------------------------------------------------

            documents.sort((a, b) {
              final DateTime? aTime = DateTime.tryParse(
                a['uploaded_at']?.toString() ?? '',
              );

              final DateTime? bTime = DateTime.tryParse(
                b['uploaded_at']?.toString() ?? '',
              );

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

            // ----------------------------------------------------
            // GET UNIQUE CATEGORIES
            // ----------------------------------------------------

            final Set<String> categorySet = {};

            for (final document in documents) {
              final Map<String, dynamic> data = document;

              final String? category = data['category']?.toString();

              if (category != null && category.isNotEmpty) {
                categorySet.add(category);
              }
            }

            final List<String> categories = categorySet.toList();

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
                            onPressed: _logout,

                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFD8DBE7),
                              size: 22,
                            ),

                            tooltip: 'Logout',
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

                            suffixIcon: Padding(
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
                // DASHBOARD CONTENT
                // ==================================================
                Expanded(
                  child: SingleChildScrollView(
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
                              child: _buildStatCard(
                                value: documents.length.toString(),

                                label: 'Documents',

                                icon: Icons.description_outlined,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: _buildStatCard(
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

                            style: TextStyle(
                              color: Color(0xFF8A8F9D),
                              fontSize: 13,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: categories
                                .map((category) => _buildCategoryChip(category))
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
                        else
                          Column(
                            children: documents
                                .take(5)
                                .map((document) => _buildDocumentCard(document))
                                .toList(),
                          ),
                      ],
                    ),
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
        onPressed: _isUploading ? null : _uploadDocument,

        backgroundColor: const Color(0xFF4DB58A),

        elevation: 2,

        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,

                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 76,

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(11),

        border: Border.all(color: const Color(0xFFE0E3EC)),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  value,

                  style: const TextStyle(
                    color: Color(0xFF171C35),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  label,

                  style: const TextStyle(
                    color: Color(0xFF73798A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Icon(icon, size: 17, color: const Color(0xFF7B8190)),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY CHIP
  // ============================================================

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

      decoration: BoxDecoration(
        color: const Color(0xFFEDEAFF),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        category,

        style: const TextStyle(
          color: Color(0xFF4D468C),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final String name = document['name']?.toString() ?? 'Document';

    final String category = document['category']?.toString() ?? 'General';

    final String size = document['size']?.toString() ?? '';

    final String extension = document['extension']?.toString() ?? '';

    IconData icon = Icons.description_outlined;

    if (extension.toLowerCase() == 'pdf') {
      icon = Icons.picture_as_pdf_outlined;
    } else if (extension.toLowerCase() == 'docx') {
      icon = Icons.description_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.all(9),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: const Color(0xFFE0E3EC)),
      ),

      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,

            decoration: BoxDecoration(
              color: const Color(0xFFFFF1DC),

              borderRadius: BorderRadius.circular(8),
            ),

            child: Icon(icon, color: const Color(0xFF9B6A2F), size: 21),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Color(0xFF171C35),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  size.isEmpty ? category : '$category • $size',

                  style: const TextStyle(
                    color: Color(0xFF73798A),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY DOCUMENT STATE
  // ============================================================

  Widget _buildEmptyDocuments() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(11),

        border: Border.all(color: const Color(0xFFE0E3EC)),
      ),

      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,

            size: 44,

            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 10),

          const Text(
            'No documents yet',

            style: TextStyle(
              color: Color(0xFF171C35),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Upload your first document to get started.',

            textAlign: TextAlign.center,

            style: TextStyle(color: Color(0xFF8A8F9D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
