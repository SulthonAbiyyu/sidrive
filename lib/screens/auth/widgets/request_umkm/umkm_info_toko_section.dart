import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/widgets/custom_textfield.dart';

class UmkmInfoTokoSection extends StatelessWidget {
  final TextEditingController namaTokoController;
  final TextEditingController alamatTokoController;
  final TextEditingController deskripsiTokoController;
  final String kategoriToko;
  final List<String> kategoriList;
  final Function(String?) onKategoriChanged;

  const UmkmInfoTokoSection({
    super.key,
    required this.namaTokoController,
    required this.alamatTokoController,
    required this.deskripsiTokoController,
    required this.kategoriToko,
    required this.kategoriList,
    required this.onKategoriChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CustomTextField(
            label: 'Nama Toko',
            hint: 'Warung Pak Budi',
            controller: namaTokoController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama toko wajib diisi';
              }
              return null;
            },
          ),
          ResponsiveMobile.vSpace(12),
          
          // Kategori Toko
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori Toko',
                style: TextStyle(
                  fontSize: ResponsiveMobile.captionSize(context) + 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ResponsiveMobile.vSpace(8),
              DropdownButtonFormField<String>(
                value: kategoriToko,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(12),
                  ),
                ),
                items: kategoriList.map((kategori) {
                  return DropdownMenuItem(
                    value: kategori,
                    child: Text(kategori[0].toUpperCase() + kategori.substring(1)),
                  );
                }).toList(),
                onChanged: onKategoriChanged,
              ),
            ],
          ),
          ResponsiveMobile.vSpace(12),
          
          // Alamat Toko
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alamat Toko',
                style: TextStyle(
                  fontSize: ResponsiveMobile.captionSize(context) + 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ResponsiveMobile.vSpace(8),
              TextFormField(
                controller: alamatTokoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Jl. Raya Sidoarjo No. 123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat toko wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
          ResponsiveMobile.vSpace(12),
          
          // Deskripsi Toko
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deskripsi Toko (Opsional)',
                style: TextStyle(
                  fontSize: ResponsiveMobile.captionSize(context) + 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ResponsiveMobile.vSpace(8),
              TextFormField(
                controller: deskripsiTokoController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ceritakan tentang toko Anda...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}