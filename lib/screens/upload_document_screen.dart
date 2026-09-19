import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../controllers/document_controller.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final DocumentController _documentController = DocumentController();

  // ============================================================
  // UPLOAD STATE
  // ============================================================

  PlatformFile? _selectedFile;

  String? _selectedCategory;

  bool _isUploading = false;

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<String> _categories = [
    'Academic',
    'Assignments',
    'Labs',
    'Projects',
    'Notes',
  ];

  // ============================================================
  // PICK DOCUMENT
  // ============================================================

  Future<void> _pickDocument() async {
    try {
      final PlatformFile? file = await _documentController.pickDocument();

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _selectedFile = file;
      });
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

  // ============================================================
  // SELECT CATEGORY
  // ============================================================

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  // ============================================================
  // UPLOAD DOCUMENT
  // ============================================================

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _documentController.uploadDocument(
        selectedFile: _selectedFile!,
        category: _selectedCategory!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF171C35),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload document',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // SELECT FILE
              // ==================================================
              const Text(
                'Document',
                style: TextStyle(
                  color: Color(0xFF171C35),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _isUploading ? null : _pickDocument,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E3EC)),
                  ),
                  child: _selectedFile == null
                      ? Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDEAFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                color: Color(0xFF6C63FF),
                                size: 27,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Select a document',
                              style: TextStyle(
                                color: Color(0xFF171C35),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              'PDF, DOC or DOCX',
                              style: TextStyle(
                                color: Color(0xFF8A8F9D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F7EF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF4DB58A),
                                size: 27,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                _selectedFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF171C35),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF73798A),
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // CATEGORY
              // ==================================================
              const Text(
                'Category',
                style: TextStyle(
                  color: Color(0xFF171C35),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: _categories.map((category) {
                  final bool isSelected = _selectedCategory == category;

                  return GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () => _selectCategory(category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF171C35)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF171C35)
                              : const Color(0xFFE0E3EC),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4D5261),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 34),

              // ==================================================
              // UPLOAD BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB58A),
                    disabledBackgroundColor: const Color(0xFF9ACDB8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Upload document',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
