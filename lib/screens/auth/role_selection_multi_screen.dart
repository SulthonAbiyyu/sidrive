import 'package:flutter/material.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/services/ktm_verification_service.dart';
import 'package:sidrive/services/storage_service.dart';

class RoleSelectionScreenMulti extends StatefulWidget {
  const RoleSelectionScreenMulti({super.key});
  
  @override
  State<RoleSelectionScreenMulti> createState() => _RoleSelectionScreenMultiState();
}

class _RoleSelectionScreenMultiState extends State<RoleSelectionScreenMulti> {
  final Set<String> _selectedRoles = {};

  void _toggleRole(String role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ============================================================
            // BACKGROUND IMAGE FULLSCREEN (3 karakter vertikal)
            // ============================================================
            Positioned.fill(
              child: Image.asset(
                AssetPaths.pilihRoleBackground,
                fit: BoxFit.cover,
              ),
            ),

            // ============================================================
            // BACK BUTTON (TOP LEFT)
            // ============================================================
            Positioned(
              top: ResponsiveMobile.scaledH(16),
              left: ResponsiveMobile.scaledW(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: ResponsiveMobile.scaledSP(24),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // ============================================================
            // TITLE (TOP CENTER)
            // ============================================================
            Positioned(
              top: ResponsiveMobile.scaledH(24),
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Pilih Role',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(26),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveMobile.scaledH(8)),
                  Text(
                    'Pilih 1 atau lebih role',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(14),
                      color: Colors.white.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // 3 KOLOM VERTIKAL - DRIVER | CUSTOMER | UMKM
            // ============================================================
            Positioned.fill(
              top: ResponsiveMobile.scaledH(120), // Beri space untuk title
              bottom: ResponsiveMobile.scaledH(100), // Beri space untuk button lanjut
              child: Row(
                children: [
                  // ================================================
                  // KOLOM 1: DRIVER (KIRI)
                  // ================================================
                  Expanded(
                    child: _buildRoleColumn(
                      role: 'driver',
                      label: 'Driver',
                      icon: Icons.motorcycle,
                      // Warna button: Putih dengan teks gelap (karena background gelap di kiri)
                      buttonColor: Colors.white,
                      textColor: Colors.black87,
                      isSelected: _selectedRoles.contains('driver'),
                      onTap: () => _toggleRole('driver'),
                    ),
                  ),

                  // ================================================
                  // KOLOM 2: CUSTOMER (TENGAH)
                  // ================================================
                  Expanded(
                    child: _buildRoleColumn(
                      role: 'customer',
                      label: 'Customer',
                      icon: Icons.person,
                      // Warna button: Putih dengan teks oranye (background oranye terang)
                      buttonColor: Colors.white,
                      textColor: const Color(0xFFFF6B35),
                      isSelected: _selectedRoles.contains('customer'),
                      onTap: () => _toggleRole('customer'),
                    ),
                  ),

                  // ================================================
                  // KOLOM 3: UMKM (KANAN)
                  // ================================================
                  Expanded(
                    child: _buildRoleColumn(
                      role: 'umkm',
                      label: 'UMKM',
                      icon: Icons.store,
                      // Warna button: Biru gelap dengan teks putih (background biru terang)
                      buttonColor: const Color(0xFF1E3A8A),
                      textColor: Colors.white,
                      isSelected: _selectedRoles.contains('umkm'),
                      onTap: () => _toggleRole('umkm'),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // BUTTON LANJUT - TENGAH BAWAH
            // ============================================================
            Positioned(
              bottom: ResponsiveMobile.scaledH(32),
              left: ResponsiveMobile.scaledW(40),
              right: ResponsiveMobile.scaledW(40),
              child: ElevatedButton(
                  onPressed: _selectedRoles.isEmpty
                      ? null
                      : () async {
                          debugPrint('✅ [ROLE] User selected: ${_selectedRoles.toList()}');
                          
                          // Save roles ke storage
                          await StorageService.setString(
                            'pending_ktm_roles', 
                            _selectedRoles.join(','),
                          );
                          
                          // CEK: Apakah user sudah approved sebelumnya?
                          final ktmService = KtmVerificationService();
                          final storedNim = StorageService.getString('pending_ktm_nim');
                          
                          if (storedNim != null && storedNim.isNotEmpty) {
                            final status = await ktmService.checkStatusByNim(storedNim);
                            
                            if (status != null && status['status'] == 'approved') {
                              // User approved, SKIP verification, langsung form!
                              debugPrint('✅ [ROLE] User has approved KTM, skip verification');
                              
                              if (!mounted) return;
                              Navigator.pushNamed(
                                context,
                                '/register/form-multi',
                                arguments: _selectedRoles.toList(),
                              );
                              return;
                            }
                          }
                          
                          // User belum approved/baru, ke verification dulu
                          debugPrint('➡️ [ROLE] User needs verification');
                          Navigator.pushNamed(
                            context,
                            '/register/nim-multi',
                            arguments: _selectedRoles.toList(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRoles.isEmpty
                        ? Colors.grey
                        : Colors.white,
                    foregroundColor: _selectedRoles.isEmpty
                        ? Colors.white70
                        : Colors.black87,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveMobile.scaledR(16),
                      ),
                    ),
                    elevation: _selectedRoles.isEmpty ? 0 : 8,
                    shadowColor: Colors.black.withOpacity(0.4),
                  ),
                  child: Text(
                    _selectedRoles.isEmpty
                        ? 'Pilih minimal 1 role'
                        : 'Lanjut (${_selectedRoles.length} role)',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(16),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD ROLE COLUMN - BUTTON DI DALAM BATAS KOLOM
  // ==========================================================================
  Widget _buildRoleColumn({
    required String role,
    required String label,
    required IconData icon,
    required Color buttonColor,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end, // Button di bawah animasi
      children: [
        // Spacer - Biarkan animasi tampil di atas
        const Spacer(),

        // ================================================================
        // BUTTON ROLE (DALAM BATAS KOLOM)
        // ================================================================
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveMobile.scaledW(8), // Padding kiri-kanan agar tidak mepet
          ),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveMobile.scaledH(16),
                horizontal: ResponsiveMobile.scaledW(8),
              ),
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(isSelected ? 1.0 : 0.85),
                borderRadius: BorderRadius.circular(
                  ResponsiveMobile.scaledR(16),
                ),
                border: Border.all(
                  color: isSelected
                      ? textColor.withOpacity(0.8)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: textColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Icon(
                    icon,
                    size: ResponsiveMobile.scaledSP(32),
                    color: textColor,
                  ),

                  SizedBox(height: ResponsiveMobile.scaledH(8)),

                  // Label
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(14),
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: ResponsiveMobile.scaledH(8)),

                  // Checkbox Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: ResponsiveMobile.scaledW(20),
                    height: ResponsiveMobile.scaledH(20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? textColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: textColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: ResponsiveMobile.scaledSP(14),
                            color: buttonColor,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: ResponsiveMobile.scaledH(24)), // Space sebelum button lanjut
      ],
    );
  }
}