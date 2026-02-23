// lib/screens/page/profile_widgets.dart
// ============================================================================
// PROFILE WIDGETS - Reusable widgets untuk Profile Tab
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/screens/auth/request_driver_role_screen.dart';

class ProfileWidgets {
  static void showFullPhoto({
    required BuildContext context,
    required String photoUrl,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
        child: Stack(
          children: [
            // Foto (tap untuk tutup)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: EdgeInsets.all(ResponsiveMobile.scaledW(40)),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: ResponsiveMobile.scaledFont(60),
                                color: Colors.white54,
                              ),
                              SizedBox(height: ResponsiveMobile.scaledH(12)),
                              Text(
                                'Gagal memuat foto',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: ResponsiveMobile.scaledFont(14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Tombol close
            Positioned(
              top: ResponsiveMobile.scaledH(10),
              right: ResponsiveMobile.scaledW(10),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: ResponsiveMobile.scaledFont(24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =========================================================================
  // VEHICLE TOGGLE CARD
  // =========================================================================
  static Widget buildVehicleToggleCard({
    required BuildContext context,
    required String activeVehicle,
    required Function(String) onToggle,
  }) {
    return Container(
      padding: ResponsiveMobile.allScaledPadding(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activeVehicle == 'motor'
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
        boxShadow: [
          BoxShadow(
            color: (activeVehicle == 'motor' ? Colors.green : Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: ResponsiveMobile.scaledFont(22),
              ),
              ResponsiveMobile.hSpace(8),
              Text(
                'Kendaraan Aktif',
                style: TextStyle(
                  fontSize: ResponsiveMobile.bodySize(context),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          ResponsiveMobile.vSpace(14),
          
          Row(
            children: [
              // Motor Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggle('motor'),
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                    child: Container(
                      padding: ResponsiveMobile.allScaledPadding(12),
                      decoration: BoxDecoration(
                        // ✅ FIX: Dinamis sesuai activeVehicle
                        color: activeVehicle == 'motor'
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                        border: Border.all(
                          color: Colors.white.withOpacity(activeVehicle == 'motor' ? 1 : 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.motorcycle,
                            // ✅ FIX: Warna icon dinamis
                            color: activeVehicle == 'motor'
                                ? Colors.green.shade700
                                : Colors.white,
                            size: ResponsiveMobile.scaledFont(32),
                          ),
                          ResponsiveMobile.vSpace(6),
                          Text(
                            'Motor',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.captionSize(context),
                              fontWeight: FontWeight.bold,
                              // ✅ FIX: Warna text dinamis
                              color: activeVehicle == 'motor'
                                  ? Colors.green.shade700
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              ResponsiveMobile.hSpace(12),
              
              // Mobil Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggle('mobil'),
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                    child: Container(
                      padding: ResponsiveMobile.allScaledPadding(12),
                      decoration: BoxDecoration(
                        // ✅ FIX: Dinamis sesuai activeVehicle
                        color: activeVehicle == 'mobil'
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                        border: Border.all(
                          color: Colors.white.withOpacity(activeVehicle == 'mobil' ? 1 : 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_car,
                            // ✅ FIX: Warna icon dinamis
                            color: activeVehicle == 'mobil'
                                ? Colors.blue.shade700
                                : Colors.white,
                            size: ResponsiveMobile.scaledFont(32),
                          ),
                          ResponsiveMobile.vSpace(6),
                          Text(
                            'Mobil',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.captionSize(context),
                              fontWeight: FontWeight.bold,
                              // ✅ FIX: Warna text dinamis
                              color: activeVehicle == 'mobil'
                                  ? Colors.blue.shade700
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // =========================================================================
  // ADD VEHICLE CARD (SPECIAL)
  // =========================================================================
  static Widget buildAddVehicleCard({
    required BuildContext context,
    required bool hasMotor,
    required bool hasMobil,
  }) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.add_road;
    Color color = Colors.orange;
    
    if (!hasMotor && !hasMobil) {
      title = 'Daftar Kendaraan Driver';
      subtitle = 'Daftar Motor atau Mobil untuk mulai menerima order';
      icon = Icons.directions_car;
      color = Colors.blue;
    } else if (hasMotor && !hasMobil) {
      title = 'Tambah Mobil 🚗';
      subtitle = 'Perluas peluang dengan mendaftar mobil';
      icon = Icons.directions_car;
      color = Colors.blue;
    } else if (!hasMotor && hasMobil) {
      title = 'Tambah Motor 🏍️';
      subtitle = 'Perluas peluang dengan mendaftar motor';
      icon = Icons.motorcycle;
      color = Colors.green;
    }
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDriverRoleScreen(
              lockedVehicleType: hasMotor ? 'motor' : (hasMobil ? 'mobil' : null),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
      child: Container(
        padding: ResponsiveMobile.allScaledPadding(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.7),
              color.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: ResponsiveMobile.allScaledPadding(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: ResponsiveMobile.scaledFont(28),
              ),
            ),
            
            ResponsiveMobile.hSpace(14),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.bodySize(context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ResponsiveMobile.vSpace(4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.captionSize(context),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: ResponsiveMobile.scaledFont(18),
            ),
          ],
        ),
      ),
    );
  }
}