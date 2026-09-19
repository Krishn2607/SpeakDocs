import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/document_controller.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/document_card.dart';
import '../widgets/stat_card.dart';
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
  // DOCUMENT CONTROLLER
  // ============================================================

  final DocumentController _documentController = DocumentController();

  bool _isUploading = false;

  // Keep one realtime stream for the lifetime of this screen.
  // This prevents duplicate stream subscriptions when setState()
  // rebuilds the dashboard during document uploads.
  late final Stream<List<DocumentModel>> _documentsStream;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _documentsStream = _documentController.documentsStream;
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
      await _documentController.uploadDocument();

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
                                .map(
                                  (category) =>
                                      CategoryChip(category: category),
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
                        else
                          Column(
                            children: documents
                                .take(5)
                                .map(
                                  (document) =>
                                      DocumentCard(document: document),
                                )
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
