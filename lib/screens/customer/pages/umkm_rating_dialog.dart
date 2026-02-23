// ============================================================================
// UMKM_RATING_DIALOG.DART
// Dialog untuk rating produk UMKM dan driver (jika pakai delivery)
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/services/rating_ulasan_service.dart';
import 'dart:ui';

class UmkmRatingDialog {
  final BuildContext context;
  final Map<String, dynamic> pesananData;
  final VoidCallback onRatingSubmitted;

  final _ratingService = RatingUlasanService();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  UmkmRatingDialog({
    required this.context,
    required this.pesananData,
    required this.onRatingSubmitted,
  });

  // ============================================================================
  // MAIN DIALOG - CEK APAKAH ADA DRIVER ATAU TIDAK
  // ============================================================================
  void show() async {
    final hasDriver = pesananData['metode_pengiriman'] == 'driver';
    final idDriver = pesananData['id_driver'];

    print('🎯 [UmkmRatingDialog] Opening rating dialog...');
    print('   - ID Pesanan: ${pesananData['id_pesanan']}');
    print('   - Has Driver: $hasDriver');
    print('   - Driver ID: $idDriver');

    if (hasDriver && idDriver != null) {
      // ✅ ADA DRIVER → Tanya mau rating apa dulu
      _showRatingTypeSelection();
    } else {
      // ✅ PICKUP (Ambil Sendiri) → Langsung rating produk
      _showProductRatingDialog();
    }
  }

  // ============================================================================
  // STEP 1: PILIH MAU RATING APA (PRODUK / DRIVER)
  // ============================================================================
  void _showRatingTypeSelection() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.wp(context, 5),
          vertical: ResponsiveMobile.hp(context, 2),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveMobile.isTablet(context) ? 480 : double.infinity,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveMobile.scaledR(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🎯 HEADER
                    Icon(
                      Icons.star_rounded,
                      size: 64,
                      color: Colors.amber.shade600,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Beri Penilaian',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pilih yang ingin Anda nilai',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 24),

                    // ✅ BUTTON RATING PRODUK
                    _buildOptionButton(
                      icon: Icons.restaurant_menu,
                      label: 'Rating Produk',
                      subtitle: 'Nilai kualitas produk yang Anda beli',
                      color: Color(0xFFFF6B9D),
                      onTap: () {
                        Navigator.pop(context);
                        _showProductRatingDialog();
                      },
                    ),

                    SizedBox(height: 12),

                    // ✅ BUTTON RATING DRIVER
                    _buildOptionButton(
                      icon: Icons.delivery_dining,
                      label: 'Rating Driver',
                      subtitle: 'Nilai pelayanan pengiriman driver',
                      color: Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.pop(context);
                        _showDriverRatingDialog();
                      },
                    ),

                    SizedBox(height: 16),

                    // ✅ CANCEL BUTTON
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Nanti Saja',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  void _showProductRatingDialog() async {
    try {
      // ✅ FETCH ITEMS DARI DATABASE - TABLE YANG BENAR: detail_pesanan
      print('🔍 Fetching items for pesanan: ${pesananData['id_pesanan']}');
      
      final itemsResponse = await _supabase
          .from('detail_pesanan')  // ← FIX: Ganti dari item_pesanan
          .select('id_produk, nama_produk, jumlah, harga_satuan')
          .eq('id_pesanan', pesananData['id_pesanan']);

      print('✅ Items fetched: ${itemsResponse.length}');

      if (itemsResponse.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak ada produk untuk dinilai'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final items = List<Map<String, dynamic>>.from(itemsResponse);

      // ✅ STATE UNTUK SETIAP PRODUK
      final productRatings = <Map<String, dynamic>>[];
      for (var item in items) {
        productRatings.add({
          'idProduk': item['id_produk'],
          'namaProduk': item['nama_produk'],
          'rating': 0,
          'reviewText': '',
          'fotoUlasan': <String>[],
          'localImages': <File>[],
        });
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.4),
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.wp(context, 5),
                vertical: ResponsiveMobile.hp(context, 2),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveMobile.isTablet(context) ? 480 : double.infinity,
                  maxHeight: ResponsiveMobile.hp(context, 90),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ HEADER
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF6B9D).withOpacity(0.1),
                                Color(0xFFFF6B9D).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFFFF6B9D),
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rating Produk',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${items.length} produk untuk dinilai',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ PRODUK LIST (SCROLLABLE)
                        Flexible(
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: List.generate(
                                productRatings.length,
                                (index) => _buildProductRatingItem(
                                  productRatings[index],
                                  index,
                                  setDialogState,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ✅ SUBMIT BUTTON
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // ✅ VALIDASI: Minimal 1 produk harus diberi rating
                                    final hasRating = productRatings.any(
                                      (p) => p['rating'] > 0,
                                    );

                                    if (!hasRating) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Minimal beri rating 1 produk',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    // ✅ SUBMIT RATING
                                    await _submitProductRatings(
                                      productRatings,
                                      dialogContext,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFF6B9D),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Kirim Penilaian',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(
                                  'Lewati',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      print('❌ Error loading product rating dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data produk'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProductRatingItem(
    Map<String, dynamic> productData,
    int index,
    StateSetter setDialogState,
  ) {
    final rating = productData['rating'] as int;
    final reviewController = TextEditingController(
      text: productData['reviewText'],
    );
    final localImages = productData['localImages'] as List<File>;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ NAMA PRODUK
          Text(
            productData['namaProduk'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),

          // ✅ RATING STARS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (starIndex) {
              final isSelected = starIndex < rating;
              return GestureDetector(
                onTap: () {
                  setDialogState(() {
                    productData['rating'] = starIndex + 1;
                  });
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.2),
                              Colors.orange.withOpacity(0.1),
                            ],
                          )
                        : null,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: isSelected
                        ? Colors.amber.shade500
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: 12),

          // ✅ REVIEW TEXT
          TextField(
            controller: reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis ulasan (opsional)',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFFFF6B9D),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              productData['reviewText'] = value;
            },
          ),

          SizedBox(height: 12),

          // ✅ UPLOAD FOTO
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Preview gambar yang sudah dipilih
              ...localImages.map((image) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            localImages.remove(image);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),

              // Button tambah foto (max 5)
              if (localImages.length < 5)
                GestureDetector(
                  onTap: () => _pickImage(productData, setDialogState),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          color: Colors.grey.shade600,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Foto',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    Map<String, dynamic> productData,
    StateSetter setDialogState,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setDialogState(() {
          final localImages = productData['localImages'] as List<File>;
          localImages.add(File(image.path));
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitProductRatings(
    List<Map<String, dynamic>> productRatings,
    BuildContext dialogContext,
  ) async {
    try {
      print('📤 Submitting product ratings...');

      // Process each product
      for (var product in productRatings) {
        if (product['rating'] == 0) continue;

        print('   - Processing: ${product['namaProduk']}');

        List<String> fotoUrls = [];

        // Upload photos
        final localImages = product['localImages'] as List<File>;
        if (localImages.isNotEmpty) {
          print('     Uploading ${localImages.length} images...');
          
          try {
            for (var i = 0; i < localImages.length; i++) {
              final file = localImages[i];
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final fileName = '${pesananData['id_pesanan']}_${product['idProduk']}_${timestamp}_$i.jpg';
              final path = 'reviews/$fileName';

              final uploadResult = await _supabase.storage
                  .from('review-photos')
                  .upload(path, file);

              if (uploadResult.isNotEmpty) {
                final url = _supabase.storage
                    .from('review-photos')
                    .getPublicUrl(path);
                fotoUrls.add(url);
                print('     ✅ Image $i uploaded: $fileName');
              }
            }
          } catch (storageError) {
            print('     ⚠️ Storage error (continuing without photos): $storageError');
          }
        }

        // Submit rating
        print('     Submitting rating...');
        await _ratingService.submitProdukRating(
          idPesanan: pesananData['id_pesanan'],
          idUser: pesananData['id_user'],
          idProduk: product['idProduk'],
          rating: product['rating'],
          reviewText: product['reviewText'].isEmpty ? null : product['reviewText'],
          fotoUlasan: fotoUrls.isEmpty ? null : fotoUrls,
        );
        
        print('     ✅ Success');
      }

      print('✅ All submitted');

      // ✅ CEK CONTEXT MOUNTED sebelum tutup dialog
      if (!dialogContext.mounted) {
        print('⚠️ Dialog context not mounted, skipping close');
        return;
      }

      // Tutup dialog
      if (Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }

      // ✅ CEK CONTEXT MOUNTED sebelum show success
      if (!context.mounted) {
        print('⚠️ Context not mounted, skipping success dialog');
        return;
      }

      // Show success
      _showSuccessDialog();
      
    } catch (e) {
      print('❌ Error: $e');

      // Tutup dialog jika masih ada
      if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim penilaian produk'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


  // ============================================================================
  // STEP 2B: RATING DRIVER (SAMA SEPERTI OJEK)
  // ============================================================================
  void _showDriverRatingDialog() {
    int selectedRating = 0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveMobile.wp(context, 5),
              vertical: ResponsiveMobile.hp(context, 2),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveMobile.isTablet(context) ? 480 : double.infinity,
                maxHeight: ResponsiveMobile.hp(context, 85),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveMobile.wp(context, 6),
                      vertical: ResponsiveMobile.hp(context, 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🎯 HEADER
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.withOpacity(0.15),
                                      Colors.orange.withOpacity(0.08),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.25),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.delivery_dining,
                                  size: 48,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 16),

                        Text(
                          'Rating Driver',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Bagaimana pelayanan driver?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: 28),

                        // ⭐ RATING STARS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final isSelected = index < selectedRating;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedRating = index + 1;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            Colors.amber.withOpacity(0.2),
                                            Colors.orange.withOpacity(0.1),
                                          ],
                                        )
                                      : null,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.amber.withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 36,
                                  color: isSelected
                                      ? Colors.amber.shade500
                                      : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: 24),

                        // 📝 REVIEW INPUT
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: reviewController,
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tulis ulasan (opsional)',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.all(16),
                              filled: false,
                            ),
                          ),
                        ),

                        SizedBox(height: 28),

                        // ✅ SUBMIT BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedRating == 0
                                ? null
                                : () async {
                                    await _submitDriverRating(
                                      selectedRating,
                                      reviewController.text,
                                      dialogContext,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: selectedRating == 0 ? 0 : 4,
                            ),
                            child: Text(
                              'Kirim Penilaian',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12),

                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                          ),
                          child: Text(
                            'Lewati',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitDriverRating(
    int rating,
    String reviewText,
    BuildContext dialogContext,
  ) async {
    try {
      print('📤 Submitting driver rating...');
      print('   - ID Pesanan: ${pesananData['id_pesanan']}');
      print('   - ID Customer: ${pesananData['id_user']}');
      print('   - ID Driver: ${pesananData['id_driver']}');
      print('   - Rating: $rating');

      // Submit rating
      final success = await _ratingService.submitDriverRating(
        idPesanan: pesananData['id_pesanan'],
        idCustomer: pesananData['id_user'],
        idDriver: pesananData['id_driver'],
        rating: rating,
        reviewText: reviewText.isEmpty ? null : reviewText,
      );

      print('✅ Submit result: $success');

      // ✅ CEK CONTEXT MOUNTED sebelum tutup dialog
      if (!dialogContext.mounted) {
        print('⚠️ Dialog context not mounted, skipping close');
        return;
      }

      // Tutup dialog
      if (Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }

      if (success) {
        // ✅ CEK CONTEXT MOUNTED sebelum show success
        if (!context.mounted) {
          print('⚠️ Context not mounted, skipping success dialog');
          return;
        }

        // Show success
        _showSuccessDialog();
      } else {
        throw Exception('Failed to submit rating');
      }
    } catch (e) {
      print('❌ Error: $e');

      // Tutup dialog jika masih ada
      if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
        Navigator.of(dialogContext).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim penilaian driver'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


  // ============================================================================
  // SUCCESS DIALOG
  // ============================================================================
  void _showSuccessDialog() {
    // ✅ DOUBLE CHECK context mounted sebelum show dialog
    if (!context.mounted) {
      print('⚠️ Context not mounted, calling callback directly');
      onRatingSubmitted();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (successDialogContext) => AlertDialog(  // ← GANTI nama variable
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Terima Kasih!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Penilaian Anda sangat berarti',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      // ✅ CEK context (bukan dialogContext) sebelum pop & callback
      if (context.mounted) {
        Navigator.pop(context);  // ← Pakai context, bukan successDialogContext
        onRatingSubmitted();
      }
    });
  }
}