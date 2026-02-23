import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UmkmDocumentsSection extends StatelessWidget {
  final String? fotoToko;
  final List<String>? fotoProdukSample;
  final Function(String, String) onShowImage;

  const UmkmDocumentsSection({
    super.key,
    required this.fotoToko,
    required this.fotoProdukSample,
    required this.onShowImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (fotoToko != null) ...[
          _buildDocumentItem('Foto Toko', fotoToko!, onShowImage),
          const SizedBox(height: 12),
        ],
        if (fotoProdukSample != null && fotoProdukSample!.isNotEmpty) ...[
          _buildProductGallery(fotoProdukSample!, onShowImage),
        ],
      ],
    );
  }

  Widget _buildDocumentItem(
    String label,
    String url,
    Function(String, String) onShowImage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onShowImage(url, label),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap untuk melihat',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGallery(
    List<String> photos,
    Function(String, String) onShowImage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Produk Sample',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: photos
              .asMap()
              .entries
              .map((entry) => _buildProductImage(
                    entry.value,
                    'Produk ${entry.key + 1}',
                    onShowImage,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProductImage(
    String url,
    String label,
    Function(String, String) onShowImage,
  ) {
    return GestureDetector(
      onTap: () => onShowImage(url, label),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFFF3F4F6),
            child: const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          ),
        ),
      ),
    );
  }
}