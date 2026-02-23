import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/screens/customer/pages/riwayat_customer.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_constants.dart';
import 'package:sidrive/services/rating_ulasan_service.dart';
import 'dart:ui';

class CustomerTrackingDialogs {
  final BuildContext context;
  final dynamic widget; // CustomerLiveTracking widget
  final SupabaseClient supabase;
  final Map<String, dynamic>? Function() getPengirimanData;
  
  final _ratingService = RatingUlasanService();

  CustomerTrackingDialogs({
    required this.context,
    required this.widget,
    required this.supabase,
    required this.getPengirimanData,
  });

  // ✅ RATING DIALOG - LIQUID GLASS STYLE (FIXED)
  void showRatingDialog() {
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
                        // 🎯 HEADER - Icon & Title
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(ResponsiveMobile.scaledR(16)),
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
                                  Icons.star_rounded,
                                  size: ResponsiveMobile.scaledR(48),
                                  color: Colors.amber.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: ResponsiveMobile.scaledH(16)),
                        
                        // 📝 TITLE
                        Text(
                          'Beri Penilaian',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.adjustedFontSize(context, 22),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveMobile.scaledH(6)),
                        
                        // 💬 SUBTITLE
                        Text(
                          'Bagaimana perjalanan Anda?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveMobile.adjustedFontSize(context, 14),
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveMobile.scaledH(28)),
                        
                        // ⭐ RATING STARS (FIXED)
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
                                margin: EdgeInsets.symmetric(
                                  horizontal: ResponsiveMobile.scaledW(4),
                                ),
                                padding: EdgeInsets.all(ResponsiveMobile.scaledR(8)),
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
                                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: ResponsiveMobile.scaledR(36),
                                  color: isSelected ? Colors.amber.shade500 : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }),
                        ),
                        
                        SizedBox(height: ResponsiveMobile.scaledH(24)),
                        
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: TextField(
                                controller: reviewController,
                                maxLength: 200,
                                maxLines: 4,
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.adjustedFontSize(context, 14),
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tulis ulasan Anda (opsional)',
                                  hintStyle: TextStyle(
                                    color: Colors.black38,
                                    fontSize: ResponsiveMobile.adjustedFontSize(context, 13),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.blue.withOpacity(0.4),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveMobile.scaledW(16),
                                    vertical: ResponsiveMobile.scaledH(14),
                                  ),
                                  counterStyle: TextStyle(
                                    fontSize: ResponsiveMobile.captionSize(context),
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveMobile.scaledH(24)),
                        
                        // 🔘 ACTION BUTTONS (FIXED)
                        Row(
                          children: [
                            // SKIP BUTTON
                            Expanded(
                              child: _buildGlassButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  showCompletionDialog();
                                },
                                label: 'Isi Nanti',
                                isPrimary: false,
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveMobile.scaledW(12)),
                            
                            // SUBMIT BUTTON
                            Expanded(
                              child: _buildGlassButton(
                                onPressed: selectedRating == 0
                                    ? null
                                    : () async {
                                        Navigator.pop(context);
                                        
                                        final success = await _submitRating(
                                          selectedRating,
                                          reviewController.text.trim(),
                                        );
                                        
                                        if (success) {
                                          showThankYouDialog();
                                        } else {
                                          showCompletionDialog();
                                        }
                                      },
                                label: 'Kirim',
                                isPrimary: true,
                                isDisabled: selectedRating == 0,
                              ),
                            ),
                          ],
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

  // 🎨 GLASS BUTTON WIDGET (IMPROVED COLORS)
  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String label,
    required bool isPrimary,
    bool isDisabled = false,
  }) {
    return Container(
      height: ResponsiveMobile.minTouchTargetSize(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDisabled
              ? [
                  Colors.grey.withOpacity(0.25),
                  Colors.grey.withOpacity(0.15),
                ]
              : isPrimary
                  ? [
                      Colors.blue.withOpacity(0.6),
                      Colors.blue.shade600.withOpacity(0.5),
                    ]
                  : [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.4),
                    ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDisabled
              ? Colors.grey.withOpacity(0.25)
              : isPrimary
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: isPrimary
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.adjustedFontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? Colors.grey.shade400
                        : isPrimary
                            ? Colors.white
                            : Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ SUBMIT RATING
  Future<bool> _submitRating(int rating, String reviewText) async {
    try {
      print('📊 Submitting rating: $rating stars');
      
      final pengirimanData = getPengirimanData();
      if (pengirimanData == null) {
        print('❌ Pengiriman data null');
        return false;
      }
      
      final success = await _ratingService.submitDriverRating(
        idPesanan: widget.idPesanan,
        idCustomer: widget.pesananData['id_user'],
        idDriver: pengirimanData['id_driver'],
        rating: rating,
        reviewText: reviewText.isEmpty ? null : reviewText,
      );
      
      if (success) {
        print('✅ Rating submitted & driver rating updated!');
        return true;
      } else {
        print('❌ Failed to submit rating');
        return false;
      }
      
    } catch (e) {
      print('❌ Error submitting rating: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }

  // ✅ THANK YOU DIALOG
  void showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              'Penilaian Anda sangat berarti bagi kami',
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
    
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.pop(context);
        
        final userId = widget.pesananData['id_user'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RiwayatCustomer(userId: userId),
          ),
        );
      }
    });
  }

  // ✅ COMPLETION DIALOG
  void showCompletionDialog() {
    print('📋 Showing completion summary...');
    
    final paymentMethod = widget.pesananData['payment_method'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.check_circle, size: 32, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pesanan Selesai!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terima kasih telah menggunakan SiDrive!',
                style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Jarak', '${widget.pesananData['jarak_km']} km'),
              _buildDetailRow('Ongkir', 'Rp ${CustomerTrackingConstants.formatCurrency(widget.pesananData['ongkir'])}'),
              _buildDetailRow('Total', 'Rp ${CustomerTrackingConstants.formatCurrency(widget.pesananData['total_harga'])}'),
              const SizedBox(height: 8),
              if (paymentMethod != null)
                Container(
                  padding: ResponsiveMobile.allScaledPadding(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        paymentMethod == 'cash' ? Icons.money : Icons.account_balance,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Metode Pembayaran: ${paymentMethod.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                            if (paymentMethod == 'cash')
                              Text(
                                'Silakan bayar langsung ke driver',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/customer/dashboard',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveMobile.scaledH(14),
                ),
                minimumSize: Size(
                  double.infinity,
                  ResponsiveMobile.minTouchTargetSize(context),
                ),
              ),
              child: Text(
                'Kembali ke Dashboard',
                style: TextStyle(
                  fontSize: ResponsiveMobile.bodySize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}