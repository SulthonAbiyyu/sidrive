import 'package:flutter/material.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_constants.dart';
import 'package:sidrive/core/widgets/cancel_order_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerTrackingWidgets {
  // ✅ MINIMIZED CONTENT - COMPACT VERSION (NO OVERFLOW)
  static Widget buildMinimizedContent({
    required BuildContext context,
    required Map<String, dynamic>? driverData,
    required String currentStatus,
    bool isUmkm = false,
  }) {
    // ✅ Use correct timeline based on order type
    final timeline = isUmkm 
        ? CustomerTrackingConstants.getUmkmDeliverySteps()
        : CustomerTrackingConstants.statusTimeline;
    
    final currentIndex = timeline.indexWhere(
      (step) => step['status'] == currentStatus,
    );
    
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
    final currentStep = timeline[safeIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // ✅ REDUCED padding
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8), // ✅ REDUCED from 10 to 8
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              currentStep['icon'],
              color: Colors.blue,
              size: 20, // ✅ REDUCED from 24 to 20
            ),
          ),
          const SizedBox(width: 10),
          
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentStep['label'],
                  style: const TextStyle(
                    fontSize: 14, // ✅ REDUCED from 16 to 14
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  driverData?['nama'] ?? 'Driver',
                  style: TextStyle(
                    fontSize: 11, // ✅ REDUCED from 13 to 11
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  // ✅ FULL CONTENT - REDESIGNED (SAMA SEPERTI DRIVER)
  static Widget buildFullContent({
    required BuildContext context,
    required double screenWidth,
    required Map<String, dynamic>? driverData,
    required String currentStatus,
    required Map<String, dynamic> pesananData,
    Map<String, dynamic>? pengirimanData,
    bool isUmkm = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDriverCard(context, driverData),
          const SizedBox(height: 16),
          _buildModernStatusProgress(context, screenWidth, currentStatus, isUmkm), // ✅ NEW DESIGN
          const SizedBox(height: 16),
          _buildPesananDetail(context, pesananData), // ✅ NO JARAK
          const SizedBox(height: 12),
          _buildCancelButton(context, pesananData, pengirimanData, currentStatus),
        ],
      ),
    );
  }

  // ✅ DRIVER CARD (SAMA SEPERTI CUSTOMER CARD DI DRIVER)
  static Widget _buildDriverCard(BuildContext context, Map<String, dynamic>? driverData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: driverData?['foto_profil'] != null
                ? NetworkImage(driverData!['foto_profil'])
                : null,
            child: driverData?['foto_profil'] == null
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverData?['nama'] ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${driverData?['merk_kendaraan'] ?? ''} - ${driverData?['plat_nomor'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${driverData?['rating_driver'] ?? '5.0'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.blue),
            onPressed: () {
              // Handle phone call
            },
          ),
        ],
      ),
    );
  }

  // ✅ NEW MODERN STATUS PROGRESS DESIGN (TEMA BIRU)
  static Widget _buildModernStatusProgress(
    BuildContext context,
    double screenWidth,
    String currentStatus,
    bool isUmkm,
  ) {
    // ✅ Use correct timeline based on order type
    final timeline = isUmkm 
        ? CustomerTrackingConstants.getUmkmDeliverySteps()
        : CustomerTrackingConstants.statusTimeline;
    
    final currentIndex = timeline.indexWhere(
      (step) => step['status'] == currentStatus,
    );
    
    final safeIndex = currentIndex >= 0 ? currentIndex : 0;
  
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.lightBlue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue.shade700, size: 20),
              SizedBox(width: 8),
              Text(
                'Status Pengiriman',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // ✅ MODERN PROGRESS BAR
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (safeIndex + 1) / timeline.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '${safeIndex + 1}/${timeline.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // ✅ COMPACT STATUS STEPS
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(timeline.length, (index) {
              final step = timeline[index];
              final isCompleted = index <= safeIndex; 
              final isActive = index == safeIndex;

              return _buildCompactStatusChip(
                icon: step['icon'],
                label: step['label'],
                isCompleted: isCompleted,
                isActive: isActive,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ✅ COMPACT STATUS CHIP (TEMA BIRU)
  static Widget _buildCompactStatusChip({
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.blue 
            : (isCompleted ? Colors.blue.shade100 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
        border: isActive 
            ? Border.all(color: Colors.blue.shade700, width: 2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : icon,
            color: isActive 
                ? Colors.white 
                : (isCompleted ? Colors.blue.shade700 : Colors.grey.shade500),
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive 
                  ? Colors.white 
                  : (isCompleted ? Colors.blue.shade900 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DETAIL PESANAN (SIMPLIFIED - NO JARAK)
  static Widget _buildPesananDetail(BuildContext context, Map<String, dynamic> pesananData) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 18),
              SizedBox(width: 6),
              Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // ✅ ONLY ONGKIR, PAYMENT, CATATAN (NO JARAK)
          _buildDetailRow(
            icon: Icons.payments,
            label: 'Ongkir', 
            value: 'Rp ${CustomerTrackingConstants.formatCurrency(pesananData['ongkir'])}',
          ), 
          _buildDetailRow(
            icon: pesananData['payment_method'] == 'cash' 
                ? Icons.money 
                : Icons.credit_card,
            label: 'Pembayaran', 
            value: pesananData['payment_method'] == 'cash' ? 'Tunai' : 'Transfer',
          ),
          if (pesananData['catatan'] != null && pesananData['catatan'].toString().isNotEmpty)
            _buildDetailRow(
              icon: Icons.note,
              label: 'Catatan', 
              value: pesananData['catatan'],
            ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CANCEL BUTTON - FIX dengan status pengiriman
  static Widget _buildCancelButton(
    BuildContext context, 
    Map<String, dynamic> pesananData,
    Map<String, dynamic>? pengirimanData,
    String currentStatus,
  ) {
    // ✅ Hanya tampilkan jika status pengiriman masih awal
    // Status: diterima, menuju_pickup, sampai_pickup
    if (currentStatus != 'diterima' && 
        currentStatus != 'menuju_pickup' && 
        currentStatus != 'sampai_pickup') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _checkCanCancel(pengirimanData),
      builder: (context, snapshot) {
        final canCancelData = snapshot.data ?? {};
        final canCancel = canCancelData['canCancel'] ?? false;
        final waitTime = canCancelData['waitTime'] ?? 0;

        return Column(
          children: [
            // Warning info jika tidak bisa cancel
            if (!canCancel && snapshot.connectionState == ConnectionState.done)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Driver sedang menuju lokasi. Tunggu $waitTime menit untuk membatalkan.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canCancel
                    ? () async {
                        final result = await _showCancelDialog(context, pesananData);
                        
                        if (result == true && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text(
                  'Batalkan Pesanan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canCancel ? Colors.red.shade400 : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ FIX: Check waktu tunggu dari pengiriman
  static Future<Map<String, dynamic>> _checkCanCancel(Map<String, dynamic>? pengirimanData) async {
    try {
      if (pengirimanData == null) {
        return {'canCancel': true, 'waitTime': 0};
      }

      // ✅ Cek waktu_terima dari tabel pengiriman (bukan pesanan!)
      final waktuTerima = pengirimanData['waktu_terima'];
      if (waktuTerima == null) {
        return {'canCancel': true, 'waitTime': 0};
      }

      final waktuTerimaDate = DateTime.parse(waktuTerima);
      final now = DateTime.now();
      final elapsedMinutes = now.difference(waktuTerimaDate).inMinutes;

      const minWaitTime = 3; // 3 menit
      final remainingWait = minWaitTime - elapsedMinutes;

      return {
        'canCancel': elapsedMinutes >= minWaitTime,
        'waitTime': remainingWait > 0 ? remainingWait : 0,
      };
    } catch (e) {
      print('❌ Error checking cancel time: $e');
      return {'canCancel': true, 'waitTime': 0};
    }
  }

  static Future<bool?> _showCancelDialog(BuildContext context, Map<String, dynamic> pesananData) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      return false;
    }

    return await CancelOrderDialog.showCustomerCancelDialog(
      context: context,
      idPesanan: pesananData['id_pesanan'],
      customerId: userId,
    );
  }
}