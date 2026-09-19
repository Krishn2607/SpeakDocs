import 'package:flutter/material.dart';

import '../models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;

  const DocumentCard({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final String name = document.name.isEmpty ? 'Document' : document.name;

    final String category = document.category?.isNotEmpty == true
        ? document.category!
        : 'General';

    final String size = document.size ?? '';

    final String extension = document.extension ?? '';

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
}
