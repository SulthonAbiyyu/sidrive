// lib/screens/page/profile_tab.dart
// ============================================================================
// PROFILE TAB - DYNAMIC FOR 3 ROLES (Customer, Driver, UMKM)
// ✅ REFACTORED & WITH DRIVER VEHICLE MANAGEMENT
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/screens/customer/pages/riwayat_customer.dart';
import 'package:sidrive/screens/driver/pages/riwayat_page.dart';
import 'package:sidrive/screens/profile/help_faq_page.dart';
import 'profile_driver_utils.dart';
import 'profile_widgets.dart';
import 'profile_photo_dialog.dart';

class ProfileTab extends StatelessWidget {
  final bool isInsideTab;
  const ProfileTab({super.key, this.isInsideTab = false});

  // =========================================================================
  // ✅ NEW: GET ROLE ACTION STATUS
  // =========================================================================
  Future<Map<String, dynamic>> _getRoleActionStatus(
    BuildContext context,
    String role,
    String status,
    String userId,
  ) async {
    debugPrint('🔍 [ProfileTab] Checking action for role: $role, status: $status');
    
    if (role == 'customer') {
      if (status == 'active') {
        return {
          'label': 'Gunakan',
          'callback': () => _confirmSwitchRole(context, role),
          'showPending': false,
          'showUploadButton': false,
          'uploadButtonLabel': null,
          'pendingMessage': null,
        };
      }
      debugPrint('⚠️ [ProfileTab] Customer with pending status - backend issue!');
      return {
        'label': 'Menunggu Verifikasi',
        'callback': null,
        'showPending': true,
        'showUploadButton': false,
        'uploadButtonLabel': null,
        'pendingMessage': null,
      };
    }
    
    if (role == 'driver' || role == 'umkm') {
      // ✅ PRIORITAS: Selalu bisa "Gunakan" dashboard
      final baseAction = {
        'label': 'Gunakan',
        'callback': () => _confirmSwitchRole(context, role),
      };
      
      if (status == 'active') {
        return {
          ...baseAction,
          'showPending': false,
          'showUploadButton': false,
          'uploadButtonLabel': null,
          'pendingMessage': null,
        };
      }
      
      if (status == 'rejected') {
        return {
          ...baseAction,
          'showPending': false,
          'showUploadButton': true, // ✅ Show upload button karena ditolak
          'uploadButtonLabel': 'Upload Ulang Dokumen',
          'pendingMessage': 'Dokumen Anda ditolak. Silakan upload ulang.',
        };
      }
      
      if (status == 'pending_verification') {
        final hasDocument = await _checkIfDocumentUploaded(userId, role);
        
        if (hasDocument) {
          // ✅ Sudah upload, sedang menunggu verifikasi
          return {
            ...baseAction,
            'showPending': true,
            'showUploadButton': false, // ✅ HIDE button upload
            'uploadButtonLabel': null,
            'pendingMessage': 'Dokumen sedang diverifikasi admin. Mohon cek secara berkala.',
          };
        } else {
          // ✅ Belum upload dokumen
          return {
            ...baseAction,
            'showPending': false,
            'showUploadButton': true, // ✅ Show upload button
            'uploadButtonLabel': 'Upload Dokumen',
            'pendingMessage': 'Silakan upload dokumen untuk verifikasi.',
          };
        }
      }
    }
    
    return {
      'label': null,
      'callback': null,
      'showPending': false,
      'showUploadButton': false,
      'uploadButtonLabel': null,
      'pendingMessage': null,
    };
  }

  Future<bool> _checkIfDocumentUploaded(String userId, String role) async {
    try {
      final supabase = Supabase.instance.client;
      
      if (role == 'umkm') {
        final umkmData = await supabase
            .from('umkm')
            .select('id_umkm')
            .eq('id_user', userId)
            .maybeSingle();
        
        final hasDocument = umkmData != null;
        debugPrint('✅ [ProfileTab] UMKM document check: $hasDocument');
        return hasDocument;
      }
      
      if (role == 'driver') {
        final driverData = await supabase
            .from('drivers')
            .select('id_driver')
            .eq('id_user', userId)
            .maybeSingle();
        
        final hasDocument = driverData != null;
        debugPrint('✅ [ProfileTab] Driver document check: $hasDocument');
        return hasDocument;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ [ProfileTab] Error checking document: $e');
      return false;
    }
  }

  void _navigateToRequestPage(BuildContext context, String role) {
    debugPrint('📱 [ProfileTab] Navigating to request page for: $role');
    
    if (role == 'umkm') {
      Navigator.pushNamed(context, '/request/umkm'); 
    } else if (role == 'driver') {
      Navigator.pushNamed(context, '/request/driver'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    
    final dynamic userRolesRaw = authProvider.userRoles;
    final List<dynamic> userRoles = (userRolesRaw is List) ? userRolesRaw : [];
    final activeRole = authProvider.activeRole ?? (user?.role ?? 'customer');

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final scrollContent = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Profile Header
        SliverAppBar(
          expandedHeight: _getHeaderHeight(context),
          pinned: true,
          elevation: 0,
          backgroundColor: const Color(0xFFF5F7FA),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildProfileHeader(context, user, activeRole),
          ),
        ),

        // Profile Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveMobile.wp(context, 5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ResponsiveMobile.scaledH(24)),
                
                // Role Section
                _buildSectionHeader(context, 'Role Anda', Icons.badge_outlined),
                SizedBox(height: ResponsiveMobile.scaledH(12)),

                ...userRoles.map((userRole) {
                  String role = 'unknown';
                  String status = 'unknown';

                  if (userRole is Map) {
                    role = userRole['role']?.toString() ?? 'unknown';
                    status = userRole['status']?.toString() ?? 'unknown';
                  } else {
                    try {
                      role = (userRole as dynamic).role?.toString() ?? 'unknown';
                      status = (userRole as dynamic).status?.toString() ?? 'unknown';
                    } catch (e) {
                      role = 'unknown';
                      status = 'unknown';
                    }
                  }

                  final isActive = (role == activeRole);

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getRoleActionStatus(context, role, status, user.idUser),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildModernRoleCard(
                          context,
                          role: role,
                          status: status,
                          isActive: isActive,
                          actionLabel: null,
                          onAction: null,
                          showPending: false,
                          showUploadButton: false,
                          uploadButtonLabel: null,
                          onUploadAction: null,
                          pendingMessage: null,
                        );
                      }
                      
                      final actionData = snapshot.data ?? {};
                      final actionLabel = actionData['label'] as String?;
                      final actionCallback = actionData['callback'] as VoidCallback?;
                      final showPending = actionData['showPending'] as bool? ?? false;
                      final showUploadButton = actionData['showUploadButton'] as bool? ?? false;
                      final uploadButtonLabel = actionData['uploadButtonLabel'] as String?;
                      final pendingMessage = actionData['pendingMessage'] as String?;
                      
                      return _buildModernRoleCard(
                        context,
                        role: role,
                        status: status,
                        isActive: isActive,
                        actionLabel: actionLabel,
                        onAction: actionCallback,
                        showPending: showPending,
                        showUploadButton: showUploadButton,
                        uploadButtonLabel: uploadButtonLabel,
                        onUploadAction: showUploadButton ? () => _navigateToRequestPage(context, role) : null,
                        pendingMessage: pendingMessage,
                      );
                    },
                  );
                }).toList(),
                
                SizedBox(height: ResponsiveMobile.scaledH(16)),
                
                // Add Role Button
                if (userRoles.length < 3)
                  _buildAddRoleButton(context),
                
                SizedBox(height: ResponsiveMobile.scaledH(16)),
                
                // Tambah Kendaraan Card (HANYA UNTUK DRIVER)
                if (activeRole == 'driver')
                  FutureBuilder<Map<String, bool>>(
                    future: _checkDriverVehicleStatus(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      
                      final data = snapshot.data ?? {};
                      
                      // Jika belum punya keduanya, show special card
                      if (!(data['hasMotor'] == true) || !(data['hasMobil'] == true)) {
                        return Column(
                          children: [
                            ProfileWidgets.buildAddVehicleCard(
                              context: context,
                              hasMotor: data['hasMotor'] == true,
                              hasMobil: data['hasMobil'] == true,
                            ),
                            SizedBox(height: ResponsiveMobile.scaledH(16)),
                          ],
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                
                SizedBox(height: ResponsiveMobile.scaledH(32)),
                
                // Role-Specific Menus
                _buildRoleSpecificMenus(context, activeRole, user),
                
                SizedBox(height: ResponsiveMobile.scaledH(32)),
                
                // Common Settings
                _buildSectionHeader(context, 'Pengaturan', Icons.settings_outlined),
                SizedBox(height: ResponsiveMobile.scaledH(12)),
                
                _buildCommonMenus(context),
                
                SizedBox(height: ResponsiveMobile.scaledH(24)),
                
                // Logout Button
                _buildLogoutButton(context),
                
                SizedBox(height: ResponsiveMobile.scaledH(24)),
                
                // Copyright
                _buildCopyrightWidget(context),
                
                SizedBox(height: ResponsiveMobile.scaledH(40)),
              ],
            ),
          ),
        ),
      ],
    );
    
    if (isInsideTab) {
      return Container(
        color: const Color(0xFFF5F7FA),
        child: scrollContent,
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: scrollContent,
    );
  }

  // =========================================================================
  // RESPONSIVE HELPER
  // =========================================================================
  double _getHeaderHeight(BuildContext context) {
    final screenWidth = ResponsiveMobile.screenWidth(context);
    if (screenWidth < 360) return 260;
    if (screenWidth < 400) return 280;
    if (screenWidth < 600) return 300;
    return 320;
  }
  // =========================================================================
  // PROFILE HEADER
  // =========================================================================
  Widget _buildProfileHeader(BuildContext context, user, String activeRole) {
    Color roleColor;
    IconData roleIcon;
    String roleLabel;
    
    switch (activeRole) {
      case 'driver':
        roleColor = Colors.green;
        roleIcon = Icons.motorcycle;
        roleLabel = 'Driver';
        break;
      case 'umkm':
        roleColor = Colors.orange;
        roleIcon = Icons.store;
        roleLabel = 'UMKM';
        break;
      default:
        roleColor = Colors.blue;
        roleIcon = Icons.person;
        roleLabel = 'Customer';
    }

    final bool hasPhoto = user.fotoProfil != null && user.fotoProfil!.isNotEmpty;

    return ClipPath(
      clipper: ElegantWaveClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              roleColor.withOpacity(0.7),
              roleColor.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Avatar with Edit Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Avatar - Klik untuk perbesar foto
                    GestureDetector(
                      onTap: hasPhoto 
                          ? () => ProfilePhotoDialog.showFullPhoto(
                              context: context,
                              photoUrl: user.fotoProfil!,
                            )
                          : null,
                      child: CircleAvatar(
                        radius: ResponsiveMobile.scaledW(50),
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: ResponsiveMobile.scaledW(47),
                          backgroundImage: hasPhoto
                              ? NetworkImage(user.fotoProfil!) as ImageProvider
                              : null,
                          backgroundColor: Colors.grey.shade200,
                          child: !hasPhoto
                              ? Text(
                                  user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    fontSize: ResponsiveMobile.scaledFont(36),
                                    fontWeight: FontWeight.bold,
                                    color: roleColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    
                    // Edit Button (Bottom Right) - Klik untuk edit/hapus
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ProfilePhotoDialog.showPhotoOptions(
                            context: context,
                            hasPhoto: hasPhoto,
                          );
                        },
                        child: Container(
                          width: ResponsiveMobile.scaledW(36),
                          height: ResponsiveMobile.scaledW(36),
                          decoration: BoxDecoration(
                            color: hasPhoto ? Colors.blue : Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            hasPhoto ? Icons.edit : Icons.add_a_photo,
                            size: ResponsiveMobile.scaledFont(16),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              // Role Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(16),
                  vertical: ResponsiveMobile.scaledH(6),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roleIcon,
                      size: ResponsiveMobile.scaledFont(16),
                      color: Colors.white,
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(6)),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(13),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              
              // User Name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.wp(context, 5)),
                child: Text(
                  user.nama,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION HEADER
  // =========================================================================
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveMobile.scaledFont(20),
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: ResponsiveMobile.scaledW(8)),
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MODERN ROLE CARD
  // =========================================================================
  Widget _buildModernRoleCard(
    BuildContext context, {
    required String role,
    required String status,
    required bool isActive,
    String? actionLabel,
    VoidCallback? onAction,
    bool showPending = false,
    bool showUploadButton = false,
    String? uploadButtonLabel,
    VoidCallback? onUploadAction,
    String? pendingMessage,
  }) {
    IconData icon;
    String label;
    Color color;

    switch (role) {
      case 'customer':
        icon = Icons.person;
        label = 'Customer';
        color = Colors.blue;
        break;
      case 'driver':
        icon = Icons.motorcycle;
        label = 'Driver';
        color = Colors.green;
        break;
      case 'umkm':
        icon = Icons.store;
        label = 'UMKM';
        color = Colors.orange;
        break;
      default:
        icon = Icons.help;
        label = role;
        color = Colors.grey;
    }

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'active':
        statusLabel = 'Aktif';
        statusColor = Colors.green;
        break;
      case 'pending_verification':
        statusLabel = 'Pending';
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusLabel = 'Ditolak';
        statusColor = Colors.red;
        break;
      default:
        statusLabel = status;
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(12)),
      decoration: BoxDecoration(
        color: isActive 
            ? color.withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        border: Border.all(
          color: isActive 
              ? color.withOpacity(0.5)
              : Colors.transparent,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
        child: Column(
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  width: ResponsiveMobile.scaledW(56),
                  height: ResponsiveMobile.scaledW(56),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveMobile.scaledFont(28),
                  ),
                ),
                
                SizedBox(width: ResponsiveMobile.scaledW(14)),
                
                // Role Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(16),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isActive) ...[
                            SizedBox(width: ResponsiveMobile.scaledW(8)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveMobile.scaledW(8),
                                vertical: ResponsiveMobile.scaledH(3),
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                              ),
                              child: Text(
                                'Aktif',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveMobile.scaledFont(10),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: ResponsiveMobile.scaledH(6)),
                      Row(
                        children: [
                          Container(
                            width: ResponsiveMobile.scaledW(8),
                            height: ResponsiveMobile.scaledW(8),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: ResponsiveMobile.scaledW(6)),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: ResponsiveMobile.scaledFont(13),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ✅ PRIORITAS: Button "Gunakan" dengan warna role
                if (actionLabel != null) ...[
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.grey : color, // ✅ Warna sesuai role
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveMobile.scaledW(16),
                        vertical: ResponsiveMobile.scaledH(10),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveMobile.scaledFont(13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // ✅ Pesan pending (muncul di bawah kalau ada message)
            if (showPending && pendingMessage != null) ...[
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(12),
                  vertical: ResponsiveMobile.scaledH(8),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.orange.shade700,
                      size: ResponsiveMobile.scaledFont(16),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(8)),
                    Expanded(
                      child: Text(
                        pendingMessage,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: ResponsiveMobile.scaledFont(11),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // ✅ Button Upload Dokumen (kecil, di bawah, hanya muncul kalau perlu)
            if (showUploadButton && uploadButtonLabel != null) ...[
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: status == 'rejected' 
                      ? Colors.red.withOpacity(0.05) 
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                  border: Border.all(
                    color: status == 'rejected' 
                        ? Colors.red.withOpacity(0.3) 
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onUploadAction,
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveMobile.scaledW(12),
                        vertical: ResponsiveMobile.scaledH(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: ResponsiveMobile.scaledFont(16),
                            color: status == 'rejected' ? Colors.red : Colors.grey.shade700,
                          ),
                          SizedBox(width: ResponsiveMobile.scaledW(8)),
                          Text(
                            uploadButtonLabel,
                            style: TextStyle(
                              color: status == 'rejected' ? Colors.red : Colors.grey.shade700,
                              fontSize: ResponsiveMobile.scaledFont(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Message untuk rejected
              if (status == 'rejected' && pendingMessage != null) ...[
                SizedBox(height: ResponsiveMobile.scaledH(6)),
                Text(
                  pendingMessage,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: ResponsiveMobile.scaledFont(10),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ADD ROLE BUTTON
  // =========================================================================
  Widget _buildAddRoleButton(BuildContext context) {
    return InkWell(
      onTap: () => _showAddRoleDialog(context),
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.scaledW(16),
          vertical: ResponsiveMobile.scaledH(16),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveMobile.scaledFont(22),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(10)),
            Text(
              'Tambah Role Baru',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: ResponsiveMobile.scaledFont(15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =========================================================================
  // ROLE-SPECIFIC MENUS
  // =========================================================================
  Widget _buildRoleSpecificMenus(BuildContext context, String activeRole, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          _getRoleMenuTitle(activeRole),
          _getRoleMenuIcon(activeRole),
        ),
        SizedBox(height: ResponsiveMobile.scaledH(12)),
        
        if (activeRole == 'customer') ..._buildCustomerMenus(context),
        if (activeRole == 'driver') ..._buildDriverMenus(context, user),
        if (activeRole == 'umkm') ..._buildUmkmMenus(context),
      ],
    );
  }

  String _getRoleMenuTitle(String role) {
    switch (role) {
      case 'driver':
        return 'Menu Driver';
      case 'umkm':
        return 'Menu UMKM';
      default:
        return 'Menu Customer';
    }
  }

  IconData _getRoleMenuIcon(String role) {
    switch (role) {
      case 'driver':
        return Icons.local_shipping_outlined;
      case 'umkm':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.shopping_cart_outlined;
    }
  }

  List<Widget> _buildCustomerMenus(BuildContext context) {
    return [
      _buildModernMenuTile(
        context,
        icon: Icons.history,
        title: 'Riwayat Pesanan',
        subtitle: 'Lihat riwayat transaksi Anda',
        color: Colors.blue,
        onTap: () {
          final authProvider = context.read<AuthProvider>();
          final userId = authProvider.currentUser?.idUser;
          
          if (userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User ID tidak ditemukan'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RiwayatCustomer(userId: userId),
            ),
          );
        },
      ),
      _buildModernMenuTile(
        context,
        icon: Icons.location_on_outlined,
        title: 'Alamat Tersimpan',
        subtitle: 'Kelola alamat pengiriman',
        color: Colors.orange,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur coming soon!')),
          );
        },
      ),
      _buildModernMenuTile(
        context,
        icon: Icons.payment,
        title: 'Metode Pembayaran',
        subtitle: 'Atur metode pembayaran',
        color: Colors.green,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur coming soon!')),
          );
        },
      ),
    ];
  }

  // =========================================================================
  // ✅ REVISED: BUILD DRIVER MENUS - WITH VEHICLE MANAGEMENT
  // =========================================================================
  List<Widget> _buildDriverMenus(BuildContext context, user) {
    return [
      FutureBuilder<Map<String, dynamic>>(
        future: ProfileDriverUtils.getDriverVehiclesInfo(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: ResponsiveMobile.allScaledPadding(20),
                child: const CircularProgressIndicator(),
              ),
            );
          }
          
          final Map<String, dynamic> data = snapshot.data ?? {
            'hasMotor': false,
            'hasMobil': false,
            'motorApproved': false,
            'mobilApproved': false,
            'activeVehicle': 'motor',
            'jenisKendaraan': 'Belum diatur',
          };

          final bool motorApproved = (data['motorApproved'] as bool?) ?? false;
          final bool mobilApproved = (data['mobilApproved'] as bool?) ?? false;
          final String activeVehicle = (data['activeVehicle'] as String?) ?? 'motor';
          final String jenisKendaraan = (data['jenisKendaraan'] as String?) ?? 'Belum diatur';
          
          return Column(
            children: [
              // Toggle Switch (jika punya 2 kendaraan approved)
              if (motorApproved && mobilApproved) ...[
                StatefulBuilder(
                  builder: (context, setState) {
                    return ProfileWidgets.buildVehicleToggleCard(
                      context: context,
                      activeVehicle: activeVehicle,
                      onToggle: (newVehicle) async {
                        await ProfileDriverUtils.switchActiveVehicle(context, newVehicle);
                        setState(() {}); // ✅ Force rebuild toggle card
                      },
                    );
                  },
                ),
                ResponsiveMobile.vSpace(12),
              ],
              
              // Info Kendaraan
              _buildModernMenuTile(
                context,
                icon: Icons.motorcycle,
                title: 'Info Kendaraan',
                subtitle: jenisKendaraan,
                color: Colors.green,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur coming soon!')),
                  );
                },
              ),
              ResponsiveMobile.vSpace(10),
              
              // Riwayat Perjalanan
              _buildModernMenuTile(
                context,
                icon: Icons.route,
                title: 'Riwayat Perjalanan',
                subtitle: 'Lihat riwayat trip Anda',
                color: Colors.blue,
                onTap: () async {
                  final authProvider = context.read<AuthProvider>();
                  final userId = authProvider.currentUser?.idUser;
                  
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID tidak ditemukan'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    final supabase = Supabase.instance.client;
                    final response = await supabase
                        .from('drivers')
                        .select('id_driver')
                        .eq('id_user', userId)
                        .maybeSingle();
                    
                    if (response == null || response['id_driver'] == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data driver tidak ditemukan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final driverId = response['id_driver'];
                    
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiwayatPage(driverId: driverId),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ResponsiveMobile.vSpace(10),
              
              // Statistik
              _buildModernMenuTile(
                context,
                icon: Icons.analytics_outlined,
                title: 'Statistik & Performa',
                subtitle: 'Rating, pendapatan, dan lainnya',
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur coming soon!')),
                  );
                },
              ),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _buildUmkmMenus(BuildContext context) {
    return [
      _buildModernMenuTile(
        context,
        icon: Icons.inventory_2_outlined,
        title: 'Kelola Produk',
        subtitle: 'Tambah, edit, hapus produk',
        color: Colors.orange,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur coming soon!')),
          );
        },
      ),
      _buildModernMenuTile(
        context,
        icon: Icons.store_outlined,
        title: 'Info Toko',
        subtitle: 'Atur jam buka, alamat, deskripsi',
        color: Colors.blue,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur coming soon!')),
          );
        },
      ),
      _buildModernMenuTile(
        context,
        icon: Icons.account_balance_wallet_outlined,
        title: 'Keuangan & Penarikan',
        subtitle: 'Saldo, riwayat transaksi, tarik saldo',
        color: Colors.green,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur coming soon!')),
          );
        },
      ),
      _buildModernMenuTile(
        context,
        icon: Icons.analytics_outlined,
        title: 'Laporan Penjualan',
        subtitle: 'Statistik & performa toko',
        color: Colors.purple,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur coming soon!')),
          );
        },
      ),
    ];
  }

  // =========================================================================
  // COMMON MENUS
  // =========================================================================
  Widget _buildCommonMenus(BuildContext context) {
    return Column(
      children: [
        _buildModernMenuTile(
          context,
          icon: Icons.edit_outlined,
          title: 'Edit Profil',
          subtitle: 'Ubah informasi pribadi',
          color: Colors.blue,

          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur coming soon!')),
            );
          },
        ),
        _buildModernMenuTile(
          context,
          icon: Icons.lock_outlined,
          title: 'Ubah Password',
          subtitle: 'Perbarui kata sandi akun',
          color: Colors.orange,

          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur coming soon!')),
            );
          },
        ),
        _buildModernMenuTile(
          context,
          icon: Icons.notifications_outlined,
          title: 'Notifikasi',
          subtitle: 'Atur preferensi notifikasi',
          color: Colors.purple,

          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur coming soon!')),
            );
          },
        ),
        _buildModernMenuTile(
          context,
          icon: Icons.help_outline,
          title: 'Bantuan & FAQ',
          subtitle: 'Dapatkan bantuan & Live Chat CS',
          color: Colors.teal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpFaqPage(),
              ),
            );
          },
        ),
        _buildModernMenuTile(
          context,
          icon: Icons.info_outline,
          title: 'Tentang Aplikasi',
          subtitle: 'Versi & informasi app',
          color: Colors.indigo,

          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  Widget _buildModernMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveMobile.scaledW(16),
              vertical: ResponsiveMobile.scaledH(14),
            ),
            child: Row(
              children: [
                Container(
                  width: ResponsiveMobile.scaledW(48),
                  height: ResponsiveMobile.scaledW(48),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: ResponsiveMobile.scaledFont(24),
                  ),
                ),
                SizedBox(width: ResponsiveMobile.scaledW(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(15),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: ResponsiveMobile.scaledH(3)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: ResponsiveMobile.scaledFont(24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // LOGOUT BUTTON
  // =========================================================================
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmLogout(context),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveMobile.scaledH(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: ResponsiveMobile.scaledW(10)),
                Text(
                  'Keluar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveMobile.scaledFont(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // =========================================================================
  // COPYRIGHT WIDGET
  // =========================================================================
  Widget _buildCopyrightWidget(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(12)),
              child: Icon(
                Icons.code_rounded,
                size: ResponsiveMobile.scaledFont(14),
                color: Colors.grey.shade400,
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveMobile.scaledH(10)),
        Text(
          'Muhammad Sulthon Abiyyu',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(12),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveMobile.scaledH(2)),
        Text(
          '\u00a9 2026 All rights reserved',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(11),
            color: Colors.grey.shade400,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // =========================================================================
  // DIALOG FUNCTIONS
  // =========================================================================
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        title: Text(
          'Tentang SiDrive',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SiDrive - UMSIDA App',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(15),
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveMobile.scaledH(8)),
            Text(
              'Versi 1.0.0',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(13),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveMobile.scaledH(16)),
            Text(
              'Aplikasi transportasi dan UMKM untuk civitas akademika UMSIDA.',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(13),
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoleDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final dynamic userRolesRaw = authProvider.userRoles;
    final List<dynamic> userRolesList = (userRolesRaw is List) ? userRolesRaw : [];

    final List<String> existingRoles = userRolesList.map((r) {
      if (r is Map) {
        return r['role']?.toString() ?? '';
      } else {
        try {
          return (r as dynamic).role?.toString() ?? '';
        } catch (e) {
          return '';
        }
      }
    }).where((r) => r.isNotEmpty).toList();

    final availableNewRoles = ['customer', 'driver', 'umkm']
        .where((r) => !existingRoles.contains(r))
        .toList();

    if (availableNewRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda sudah memiliki semua role!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.wp(context, 8),
          vertical: ResponsiveMobile.scaledH(24),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxWidth: ResponsiveMobile.screenWidth(context) * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveMobile.scaledR(20)),
                    topRight: Radius.circular(ResponsiveMobile.scaledR(20)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: ResponsiveMobile.scaledFont(24),
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(12)),
                    Expanded(
                      child: Text(
                        'Tambah Role Baru',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(18),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(
                        Icons.close,
                        color: Colors.black87,
                      ),
                      iconSize: ResponsiveMobile.scaledFont(22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: availableNewRoles.map((role) {
                      IconData icon;
                      String label;
                      String desc;
                      Color color;

                      switch (role) {
                        case 'customer':
                          icon = Icons.person_outline;
                          label = 'Customer';
                          desc = 'Pesan ojek & belanja';
                          color = Colors.blue;
                          break;
                        case 'driver':
                          icon = Icons.motorcycle_outlined;
                          label = 'Driver';
                          desc = 'Jadi driver ojek';
                          color = Colors.green;
                          break;
                        case 'umkm':
                          icon = Icons.store_outlined;
                          label = 'UMKM';
                          desc = 'Jual produk online';
                          color = Colors.orange;
                          break;
                        default:
                          icon = Icons.help_outline;
                          label = role;
                          desc = '';
                          color = Colors.grey;
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(10)),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              _navigateToRequestForm(context, role);
                            },
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
                            child: Padding(
                              padding: EdgeInsets.all(ResponsiveMobile.scaledW(14)),
                              child: Row(
                                children: [
                                  Container(
                                    width: ResponsiveMobile.scaledW(50),
                                    height: ResponsiveMobile.scaledW(50),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: color,
                                      size: ResponsiveMobile.scaledFont(26),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveMobile.scaledW(14)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: ResponsiveMobile.scaledFont(16),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: ResponsiveMobile.scaledH(3)),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: ResponsiveMobile.scaledFont(13),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: color,
                                    size: ResponsiveMobile.scaledFont(24),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRequestForm(BuildContext context, String role) {
    if (role == 'customer') {
      _addRoleDirectly(context, role);
    } else if (role == 'driver') {
      Navigator.pushNamed(context, '/request/driver');
    } else if (role == 'umkm') {
      Navigator.pushNamed(context, '/request/umkm');
    }
  }

  Future<void> _addRoleDirectly(BuildContext context, String role) async {
    final authProvider = context.read<AuthProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await authProvider.addRole(role);

      if (context.mounted) Navigator.pop(context);

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role $role berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Gagal menambah role'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmSwitchRole(BuildContext context, String newRole) async {
    IconData icon;
    String label;
    Color color;
    switch (newRole) {
      case 'customer':
        icon = Icons.person_outline;
        label = 'Customer';
        color = Colors.blue;
        break;
      case 'driver':
        icon = Icons.motorcycle_outlined;
        label = 'Driver';
        color = Colors.green;
        break;
      case 'umkm':
        icon = Icons.store_outlined;
        label = 'UMKM';
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        label = newRole;
        color = Colors.grey;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.wp(context, 8),
        ),
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveMobile.scaledW(60),
                height: ResponsiveMobile.scaledW(60),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveMobile.scaledFont(32),
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              Text(
                'Ganti Role',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              Text(
                'Apakah Anda ingin beralih ke role $label?',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(15),
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveMobile.scaledH(14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveMobile.scaledW(12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveMobile.scaledH(14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Ya, Ganti',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _switchRole(context, newRole);
    }
  }

  Future<void> _switchRole(BuildContext context, String newRole) async {
    final authProvider = context.read<AuthProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final success = await authProvider.switchRole(newRole);

    if (context.mounted) Navigator.pop(context);

    if (success) {
      if (context.mounted) {
        // Navigate to appropriate dashboard based on role
        String routeName;
        switch (newRole) {
          case 'driver':
            routeName = '/driver/dashboard';
            break;
          case 'umkm':
            routeName = '/umkm/dashboard';
            break;
          case 'customer':
            routeName = '/customer/dashboard';
            break;
          default:
            routeName = '/dashboard';
        }

        Navigator.pushReplacementNamed(context, routeName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Berhasil beralih ke role $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Gagal beralih role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveMobile.wp(context, 8),
        ),
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveMobile.scaledW(60),
                height: ResponsiveMobile.scaledW(60),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: ResponsiveMobile.scaledFont(32),
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              Text(
                'Apakah Anda yakin ingin keluar dari aplikasi?',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(15),
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveMobile.scaledH(14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveMobile.scaledW(12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveMobile.scaledH(14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Ya, Keluar',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirm == true) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
      }
    }
  }
  
  // =========================================================================
  // CHECK DRIVER VEHICLE STATUS
  // =========================================================================
  Future<Map<String, bool>> _checkDriverVehicleStatus(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId == null) return {};
      
      final supabase = Supabase.instance.client;
      
      final driverData = await supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (driverData == null) return {};
      
      final vehicles = await supabase
          .from('driver_vehicles')
          .select('jenis_kendaraan')
          .eq('id_driver', driverData['id_driver']);
      
      bool hasMotor = false;
      bool hasMobil = false;
      
      for (var v in vehicles) {
        if (v['jenis_kendaraan'] == 'motor') hasMotor = true;
        if (v['jenis_kendaraan'] == 'mobil') hasMobil = true;
      }
      
      return {'hasMotor': hasMotor, 'hasMobil': hasMobil};
    } catch (e) {
      return {};
    }
  }
}
  // =========================================================================
  // CUSTOM CLIPPER - untuk lengkungan tengah header
  // =========================================================================
  class ElegantWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 30);

    path.cubicTo(
      size.width * 0.3, size.height - 60,
      size.width * 0.7, size.height + 20,
      size.width, size.height - 30,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}