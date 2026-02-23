import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/theme_provider.dart';
import 'package:sidrive/config/app_colors.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';

class OrderBottomSheet extends StatelessWidget {
  final double bottomSheetHeight;
  final double minHeight;
  final double maxHeight;
  final Function(DragUpdateDetails) onDragUpdate;
  final String jenisKendaraan;
  final LatLng? destinationPosition;
  final int estimatedTime;
  final double jarakKm;
  final String pickupAddress;
  final String destinationAddress;
  final double ongkirDriver;
  final double biayaAdmin;
  final double totalCustomer;
  final bool isCreatingOrder;
  final VoidCallback onFindDriver;
  final String selectedPaymentMethod;
  final Function(String) onPaymentMethodChanged;
  final double currentWalletBalance;
  final bool isDropPinMode;
  final bool isPickupMode;
  final VoidCallback? onToggleDropPin;
  final VoidCallback? onTogglePickupDestination;

  const OrderBottomSheet({
    super.key,
    required this.bottomSheetHeight,
    required this.minHeight,
    required this.maxHeight,
    required this.onDragUpdate,
    required this.jenisKendaraan,
    required this.destinationPosition,
    required this.estimatedTime,
    required this.jarakKm,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.ongkirDriver,
    required this.biayaAdmin,
    required this.totalCustomer,
    required this.isCreatingOrder,
    required this.onFindDriver,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.currentWalletBalance,
    this.isDropPinMode = false,
    this.isPickupMode = false,
    this.onToggleDropPin,
    this.onTogglePickupDestination,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark(context);
    // Logic untuk menyembunyikan konten jika sheet sangat pendek (opsional, bawaan file anda)
    final isMinimized = bottomSheetHeight <= (minHeight * 0.5);

    Color vehicleColor = jenisKendaraan == 'motor'
        ? const Color(0xFF00880F)
        : const Color(0xFF1E88E5);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: onDragUpdate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: destinationPosition != null 
              ? ResponsiveMobile.scaledH(340) 
              : bottomSheetHeight,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ResponsiveMobile.scaledR(16)),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: ResponsiveMobile.scaledH(8),
                  ),
                  width: ResponsiveMobile.scaledW(40),
                  height: ResponsiveMobile.scaledH(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : Colors.grey[300],
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(2)),
                  ),
                ),

                // Content Wrapper
                if (!isMinimized)
                  Flexible(
                    child: destinationPosition == null
                        ? _buildWaitingSheet(isDark, context)
                        : _buildRouteSheet(isDark, vehicleColor, context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingSheet(bool isDark, BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.scaledW(20),
          vertical: ResponsiveMobile.scaledH(10), // Reduced vertical padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching,
              size: ResponsiveMobile.scaledFont(32), // Reduced size
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.5)
                  : Colors.grey[400],
            ),
            SizedBox(height: ResponsiveMobile.scaledH(8)),
            Text(
              'Pilih tujuan untuk melihat estimasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: ResponsiveMobile.scaledH(4)),
            Text(
              'Ketik di kolom tujuan atau pilih di peta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context),
                color: isDark
                    ? AppColors.textSecondaryDark.withOpacity(0.8)
                    : AppColors.textSecondaryLight.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (onToggleDropPin != null) ...[
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              ElevatedButton.icon(
                onPressed: onToggleDropPin,
                icon: Icon(
                  isDropPinMode ? Icons.close : Icons.push_pin,
                  size: ResponsiveMobile.scaledFont(14),
                ),
                label: Text(
                  isDropPinMode ? 'Batalkan' : 'Drop Pin',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDropPinMode
                      ? Colors.red.shade400
                      : const Color(0xFF5DADE2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(16),
                    vertical: ResponsiveMobile.scaledH(6), // Compact button
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSheet(bool isDark, Color vehicleColor, BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.scaledW(16),
          vertical: 0, // Hapus padding vertikal atas-bawah container
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. Route info ---
            Row(
              children: [
                Icon(
                  jenisKendaraan == 'motor' ? Icons.two_wheeler : Icons.directions_car,
                  color: vehicleColor,
                  size: ResponsiveMobile.scaledFont(18),
                ),
                SizedBox(width: ResponsiveMobile.scaledW(6)),
                Text(
                  '$estimatedTime min',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.bodySize(context) + 2,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                SizedBox(width: ResponsiveMobile.scaledW(12)),
                Text(
                  '${jarakKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context),
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                if (onToggleDropPin != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isDropPinMode ? Icons.close : Icons.push_pin,
                      size: ResponsiveMobile.scaledFont(18),
                      color: isDropPinMode ? Colors.red : const Color(0xFF5DADE2),
                    ),
                    onPressed: onToggleDropPin,
                    tooltip: isDropPinMode ? 'Batalkan' : 'Drop Pin',
                  ),
              ],
            ),

            // Jarak dikurangi drastis (10 -> 4)
            SizedBox(height: ResponsiveMobile.scaledH(4)),

            // --- 2. Locations ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: ResponsiveMobile.scaledW(8),
                      height: ResponsiveMobile.scaledH(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4285F4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: ResponsiveMobile.scaledW(1.5),
                      height: ResponsiveMobile.scaledH(20), // Tinggi garis sedikit dikurangi
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFFEA4335),
                      size: ResponsiveMobile.scaledFont(14),
                    ),
                  ],
                ),
                SizedBox(width: ResponsiveMobile.scaledW(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup
                      Text(
                        'Lokasi Jemput',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context) - 2,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.0, // Line height rapat
                        ),
                      ),
                      Text(
                        pickupAddress,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveMobile.scaledH(4)), // Spacing antar alamat dikurangi

                      // Destination
                      Text(
                        'Tujuan',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context) - 2,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        destinationAddress,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context),
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Jarak dan Divider dirapatkan
            SizedBox(height: ResponsiveMobile.scaledH(6)),
            Divider(
              height: 1,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            SizedBox(height: ResponsiveMobile.scaledH(6)),

            // --- 3. Payment Method ---
            Text(
              'PEMBAYARAN',
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context) - 1, // Font sedikit dikecilkan
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            SizedBox(height: ResponsiveMobile.scaledH(4)), // Jarak ke tombol dikurangi

            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentOption(
                        isDark: isDark,
                        context: context,
                        label: 'Cash',
                        icon: Icons.money,
                        value: 'cash',
                        groupValue: selectedPaymentMethod,
                        onChanged: onPaymentMethodChanged,
                        isEnabled: true,
                        isCompact: true,
                      ),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(8)),
                    Expanded(
                      child: _buildPaymentOption(
                        isDark: isDark,
                        context: context,
                        label: 'Transfer',
                        icon: Icons.account_balance,
                        value: 'transfer',
                        groupValue: selectedPaymentMethod,
                        onChanged: onPaymentMethodChanged,
                        isEnabled: true,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveMobile.scaledH(6)), // Jarak antar baris payment dikurangi
                SizedBox(
                  width: double.infinity,
                  child: _buildPaymentOption(
                    isDark: isDark,
                    context: context,
                    label: 'Wallet',
                    icon: Icons.account_balance_wallet,
                    value: 'wallet',
                    groupValue: selectedPaymentMethod,
                    onChanged: onPaymentMethodChanged,
                    isEnabled: currentWalletBalance >= totalCustomer,
                    subtitle: 'Rp ${CurrencyFormatter.format(currentWalletBalance)}',
                    isCompact: true,
                  ),
                ),
              ],
            ),

            // Warning Wallet
            if (selectedPaymentMethod == 'wallet' && currentWalletBalance < totalCustomer) ...[
              SizedBox(height: ResponsiveMobile.scaledH(4)),
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(6)),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: ResponsiveMobile.scaledFont(12)),
                    SizedBox(width: ResponsiveMobile.scaledW(6)),
                    Expanded(
                      child: Text(
                        'Saldo kurang.',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context) - 1,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Jarak ke Total & Tombol Cari Driver dikurangi drastis
            SizedBox(height: ResponsiveMobile.scaledH(8)),

            // --- 4. Total & Button ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context) - 2,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Rp ${CurrencyFormatter.formatRupiah(totalCustomer)}',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.bodySize(context) + 2,
                        fontWeight: FontWeight.bold,
                        color: vehicleColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: ResponsiveMobile.scaledW(16)),
                Expanded(
                  child: SizedBox(
                    height: ResponsiveMobile.scaledH(38), // Tinggi tombol sedikit dipadatkan
                    child: ElevatedButton(
                      onPressed: isCreatingOrder ? null : onFindDriver,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DADE2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                        ),
                        elevation: 0,
                      ),
                      child: isCreatingOrder
                          ? SizedBox(
                              height: ResponsiveMobile.scaledH(16),
                              width: ResponsiveMobile.scaledW(16),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Cari Driver',
                              style: TextStyle(
                                fontSize: ResponsiveMobile.bodySize(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Padding bawah safe area agar tidak terlalu nempel tapi tetap rapat
            SizedBox(height: ResponsiveMobile.scaledH(4)), 
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required bool isDark,
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
    required bool isEnabled,
    String? subtitle,
    bool isCompact = false,
  }) {
    final isSelected = value == groupValue;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled ? () => onChanged(value) : null,
        child: Container(
          // PADDING DIMAMPATKAN: vertical dari 8/12 menjadi 6/10
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveMobile.scaledH(isCompact ? 6 : 10),
            horizontal: ResponsiveMobile.scaledW(isCompact ? 8 : 12),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2C5F7C) : const Color(0xFFE3F2FD))
                : (isDark ? AppColors.backgroundDark : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5DADE2)
                  : (isDark ? AppColors.borderDark : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF5DADE2)
                    : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
                size: ResponsiveMobile.scaledFont(16),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(6)),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF5DADE2)
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        height: 1.1, // Line height rapat
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.captionSize(context) - 2,
                          color: isEnabled 
                              ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                              : Colors.red,
                          fontWeight: isEnabled ? FontWeight.normal : FontWeight.w600,
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isEnabled)
                Padding(
                  padding: EdgeInsets.only(left: ResponsiveMobile.scaledW(4)),
                  child: Icon(
                    Icons.lock_outline,
                    size: ResponsiveMobile.scaledFont(12),
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}