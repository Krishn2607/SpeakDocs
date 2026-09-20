import 'package:flutter/material.dart';

import '../controllers/document_controller.dart';
import '../models/document_model.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final DocumentController _documentController = DocumentController();

  bool _isOpening = false;
  bool _isDeleting = false;

  String get _name {
    return widget.document.name.isEmpty ? 'Document' : widget.document.name;
  }

  String get _category {
    final String? category = widget.document.category;

    if (category == null || category.isEmpty) {
      return 'General';
    }

    return category;
  }

  String get _fileType {
    final String extension = widget.document.extension ?? '';

    if (extension.isEmpty) {
      return 'Unknown';
    }

    return extension.toUpperCase();
  }

  String get _fileSize {
    if (widget.document.size != null && widget.document.size!.isNotEmpty) {
      return widget.document.size!;
    }

    final int? sizeBytes = widget.document.sizeBytes;

    if (sizeBytes == null) {
      return 'Unknown';
    }

    return _formatFileSize(sizeBytes);
  }

  String get _uploadedDate {
    final DateTime? uploadedAt = widget.document.uploadedAt;

    if (uploadedAt == null) {
      return 'Unknown';
    }

    return '${uploadedAt.day.toString().padLeft(2, '0')}/'
        '${uploadedAt.month.toString().padLeft(2, '0')}/'
        '${uploadedAt.year}';
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================

  Future<void> _openDocument() async {
    if (_isOpening || _isDeleting) {
      return;
    }

    setState(() {
      _isOpening = true;
    });

    try {
      await _documentController.openDocument(widget.document);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open document: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> _deleteDocument() async {
    if (_isDeleting || _isOpening) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete document?'),
          content: Text('Are you sure you want to delete "$_name"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });
    try {
      await _documentController.deleteDocument(
        widget.document,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete document: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // DOCUMENT ICON
  // ============================================================

  IconData _getDocumentIcon() {
    final String extension = widget.document.extension?.toLowerCase() ?? '';

    if (extension == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    }

    if (extension == 'doc' || extension == 'docx') {
      return Icons.description_outlined;
    }

    return Icons.insert_drive_file_outlined;
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF171C35)),
        ),
        title: Text(
          _name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF171C35),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // DOCUMENT PREVIEW
            // ==================================================
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E3EC)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getDocumentIcon(),
                      color: const Color(0xFF9B6A2F),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _fileType,
                    style: const TextStyle(
                      color: Color(0xFF73798A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ==================================================
            // DOCUMENT NAME
            // ==================================================
            Text(
              _name,
              style: const TextStyle(
                color: Color(0xFF171C35),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // DOCUMENT INFORMATION
            // ==================================================
            _buildInfoRow(
              icon: Icons.folder_outlined,
              label: 'Category',
              value: _category,
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.description_outlined,
              label: 'File type',
              value: _fileType,
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.data_usage_rounded,
              label: 'Size',
              value: _fileSize,
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Uploaded',
              value: _uploadedDate,
            ),

            const SizedBox(height: 30),

            // ==================================================
            // OPEN BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isOpening || _isDeleting ? null : _openDocument,
                icon: _isOpening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new_rounded),
                label: Text(_isOpening ? 'Opening...' : 'Open document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4D57D8),
                  side: const BorderSide(color: Color(0xFF4D57D8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DELETE BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isDeleting || _isOpening ? null : _deleteDocument,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                label: Text(_isDeleting ? 'Deleting...' : 'Delete document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9534F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E3EC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF73798A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF171C35),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
