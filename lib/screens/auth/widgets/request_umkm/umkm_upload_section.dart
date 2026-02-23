import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class UmkmUploadSection extends StatelessWidget {
  final File? fotoToko;
  final List<File> fotoProduk;
  final VoidCallback onPickFotoToko;
  final VoidCallback onPickFotoProduk;
  final Function(int) onRemoveFotoProduk;

  const UmkmUploadSection({
    super.key,
    required this.fotoToko,
    required this.fotoProduk,
    required this.onPickFotoToko,
    required this.onPickFotoProduk,
    required this.onRemoveFotoProduk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto Toko
        _buildUploadCard(
          context: context,
          title: 'Foto Toko',
          subtitle: 'Upload foto tampak depan toko',
          file: fotoToko,
          onTap: onPickFotoToko,
        ),
        
        ResponsiveMobile.vSpace(16),
        
        // Foto Produk
        Text(
          'Foto Produk (1-5 foto)',
          style: TextStyle(
            fontSize: ResponsiveMobile.captionSize(context) + 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        ResponsiveMobile.vSpace(8),
        
        if (fotoProduk.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: ResponsiveMobile.scaledW(8),
              mainAxisSpacing: ResponsiveMobile.scaledH(8),
            ),
            itemCount: fotoProduk.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                    child: Image.file(
                      fotoProduk[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveFotoProduk(index),
                      child: Container(
                        padding: EdgeInsets.all(ResponsiveMobile.scaledR(4)),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: ResponsiveMobile.scaledFont(16),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        
        ResponsiveMobile.vSpace(8),
        
        OutlinedButton.icon(
          onPressed: fotoProduk.length < 5 ? onPickFotoProduk : null,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Tambah Foto Produk (${fotoProduk.length}/5)'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveMobile.scaledH(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        child: Padding(
          padding: ResponsiveMobile.allScaledPadding(16),
          child: Row(
            children: [
              Container(
                width: ResponsiveMobile.scaledW(60),
                height: ResponsiveMobile.scaledH(60),
                decoration: BoxDecoration(
                  color: file != null ? Colors.orange.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  border: Border.all(
                    color: file != null ? Colors.orange : Colors.grey.shade300,
                  ),
                ),
                child: file != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                        child: Image.file(file, fit: BoxFit.cover),
                      )
                    : Icon(
                        Icons.add_photo_alternate,
                        color: Colors.grey,
                        size: ResponsiveMobile.scaledFont(32),
                      ),
              ),
              ResponsiveMobile.hSpace(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context) + 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveMobile.vSpace(4),
                    Text(
                      file != null ? 'Foto sudah dipilih ✓' : subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: file != null ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                file != null ? Icons.check_circle : Icons.upload_file,
                color: file != null ? Colors.orange : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}