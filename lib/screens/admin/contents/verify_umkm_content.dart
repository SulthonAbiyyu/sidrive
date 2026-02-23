import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';

// Import widgets
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_list_header.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_empty_state.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_card_item.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_detail_header.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_detail_section.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_documents_section.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_action_buttons.dart';
import 'package:sidrive/screens/admin/contents/widgets/verify_umkm/umkm_location_map_viewer.dart';

/// ============================================================================
/// VERIFY UMKM CONTENT - REFACTORED VERSION 🔥
/// File utama yang lebih clean, UI components dipecah ke widgets
/// ============================================================================

class VerifyUmkmContent extends StatefulWidget {
  final String? selectedUmkmId;
  final Function(String) onUmkmSelected;
  final VoidCallback onBackToList;

  const VerifyUmkmContent({
    super.key,
    this.selectedUmkmId,
    required this.onUmkmSelected,
    required this.onBackToList,
  });

  @override
  State<VerifyUmkmContent> createState() => _VerifyUmkmContentState();
}

class _VerifyUmkmContentState extends State<VerifyUmkmContent> {
  UmkmVerification? _detailUmkm;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadDetailIfNeeded();
  }

  @override
  void didUpdateWidget(VerifyUmkmContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUmkmId != widget.selectedUmkmId) {
      _loadDetailIfNeeded();
    }
  }

  Future<void> _loadDetailIfNeeded() async {
    if (widget.selectedUmkmId != null) {
      setState(() => _isLoadingDetail = true);
      try {
        final adminProvider = context.read<AdminProvider>();
        final umkm = await adminProvider.getUmkmDetail(widget.selectedUmkmId!);
        if (mounted) {
          setState(() {
            _detailUmkm = umkm;
            _isLoadingDetail = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingDetail = false);
          debugPrint('❌ Error loading UMKM detail: $e');
        }
      }
    } else {
      setState(() {
        _detailUmkm = null;
        _isLoadingDetail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika ada selected UMKM, tampilkan detail
    if (widget.selectedUmkmId != null) {
      return _buildDetailView();
    }

    // Jika tidak, tampilkan list
    return _buildListView();
  }

  // ========================================================================
  // LIST VIEW
  // ========================================================================

  Widget _buildListView() {
    final adminProvider = context.watch<AdminProvider>();
    final pendingUmkm = adminProvider.pendingUmkm;

    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          UmkmListHeader(
            provider: adminProvider,
            onRefresh: () => context.read<AdminProvider>().loadPendingUmkm(),
          ),
          const Divider(height: 1),
          Expanded(
            child: pendingUmkm.isEmpty
                ? const UmkmEmptyState()
                : RefreshIndicator(
                    onRefresh: () => context.read<AdminProvider>().loadPendingUmkm(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingUmkm.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final umkm = pendingUmkm[index];
                        return UmkmCardItem(
                          umkm: umkm,
                          onTap: () => widget.onUmkmSelected(umkm.idUmkm),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // DETAIL VIEW
  // ========================================================================

  Widget _buildDetailView() {
    if (_isLoadingDetail) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_detailUmkm == null) {
      return _buildDetailErrorState();
    }

    return _buildDetailContent(_detailUmkm!);
  }

  Widget _buildDetailErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Data Tidak Ditemukan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data UMKM tidak tersedia',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onBackToList,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Kembali'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(UmkmVerification umkm) {
    return Column(
      children: [
        // Header
        UmkmDetailHeader(
          umkm: umkm,
          onBack: widget.onBackToList,
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data Pemilik
                UmkmDetailSection(
                  title: 'Pemilik',
                  icon: Icons.person_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  child: Column(
                    children: [
                      UmkmDetailRow(label: 'Nama', value: umkm.nama),
                      UmkmDetailRow(label: 'NIM', value: umkm.nim),
                      UmkmDetailRow(label: 'No. Telp', value: umkm.noTelp),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Data Toko
                UmkmDetailSection(
                  title: 'Informasi Toko',
                  icon: Icons.store_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                  ),
                  child: Column(
                    children: [
                      UmkmDetailRow(label: 'Nama Toko', value: umkm.namaToko),
                      if (umkm.kategoriToko != null)
                        UmkmDetailRow(label: 'Kategori', value: umkm.kategoriToko!),
                      UmkmDetailRow(label: 'Alamat', value: umkm.alamatToko),
                      if (umkm.deskripsiToko != null)
                        UmkmDetailRow(label: 'Deskripsi', value: umkm.deskripsiToko!),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Lokasi Toko
                if (umkm.lokasiToko != null || umkm.alamatTokoLengkap != null)
                  UmkmDetailSection(
                    title: 'Lokasi Toko',
                    icon: Icons.place,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (umkm.lokasiToko != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCE7F3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFBCFE8)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.pin_drop_rounded, color: Color(0xFFDB2777), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Koordinat GPS',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFDB2777),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              umkm.lokasiToko!,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontFamily: 'monospace',
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Tombol Lihat di Peta - Compact & Modern
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showLocationOnMap(umkm),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.map_rounded, size: 16, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Lihat Peta',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (umkm.alamatTokoLengkap != null)
                          UmkmDetailRow(
                            label: 'Alamat Lengkap',
                            value: umkm.alamatTokoLengkap!,
                          )
                        else
                          UmkmDetailRow(
                            label: 'Alamat',
                            value: umkm.alamatToko,
                          ),
                      ],
                    ),
                  ),

                // Dokumen
                UmkmDetailSection(
                  title: 'Dokumen',
                  icon: Icons.description_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                  child: UmkmDocumentsSection(
                    fotoToko: umkm.fotoToko,
                    fotoProdukSample: umkm.fotoProdukSample,
                    onShowImage: _showImageDialog,
                  ),
                ),

                const SizedBox(height: 24),

                // Rekening Bank
                if (umkm.namaBank != null && umkm.nomorRekening != null)
                  UmkmDetailSection(
                    title: 'Rekening Bank',
                    icon: Icons.account_balance_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    child: Column(
                      children: [
                        UmkmDetailRow(label: 'Bank', value: umkm.namaBank ?? '-'),
                        UmkmDetailRow(label: 'No. Rekening', value: umkm.nomorRekening ?? '-'),
                        UmkmDetailRow(label: 'Atas Nama', value: umkm.namaRekening ?? '-'),
                      ],
                    ),
                  ),

                const SizedBox(height: 120), // Extra space untuk action buttons
              ],
            ),
          ),
        ),

        // Action Buttons
        UmkmActionButtons(
          umkm: umkm,
          onApprove: _approveUmkm,
          onReject: _rejectUmkm,
        ),
      ],
    );
  }

  // ========================================================================
  // SHOW LOCATION ON MAP
  // ========================================================================

  void _showLocationOnMap(UmkmVerification umkm) {
    if (umkm.lokasiToko == null || umkm.lokasiToko!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi toko tidak tersedia'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      debugPrint('🗺️ Parsing location: ${umkm.lokasiToko}');
      
      // Format dari database: POINT(lng lat) atau "lng lat" atau "lat,lng"
      String cleanedLocation = umkm.lokasiToko!.trim();
      
      double latitude;
      double longitude;
      
      // Check if it's POINT format: POINT(112.123 -7.456)
      if (cleanedLocation.toUpperCase().startsWith('POINT')) {
        // Extract coordinates from POINT(lng lat)
        // Pattern yang benar: support +/- prefix dan decimal numbers
        final pointPattern = RegExp(
          r'POINT\s*\(\s*([+-]?[0-9.]+)\s+([+-]?[0-9.]+)\s*\)',
          caseSensitive: false,
        );
        final match = pointPattern.firstMatch(cleanedLocation);
        
        if (match == null || match.groupCount < 2) {
          throw Exception('Format POINT tidak valid: $cleanedLocation');
        }
        
        // IMPORTANT: POINT format is (longitude latitude) - NOT (lat lng)!
        final lng = match.group(1);
        final lat = match.group(2);
        
        if (lng == null || lat == null) {
          throw Exception('Koordinat tidak bisa di-parse dari: $cleanedLocation');
        }
        
        longitude = double.parse(lng);
        latitude = double.parse(lat);
        
        debugPrint('✅ Parsed POINT format: lng=$longitude, lat=$latitude');
      } 
      // Check if comma-separated: "lat,lng"
      else if (cleanedLocation.contains(',')) {
        final parts = cleanedLocation.split(',');
        if (parts.length != 2) {
          throw Exception('Format koordinat tidak valid: $cleanedLocation');
        }
        latitude = double.parse(parts[0].trim());
        longitude = double.parse(parts[1].trim());
        
        debugPrint('✅ Parsed comma format: lat=$latitude, lng=$longitude');
      }
      // Space-separated: "lng lat" or "lat lng"
      else if (cleanedLocation.contains(' ')) {
        final parts = cleanedLocation.trim().split(RegExp(r'\s+'));
        if (parts.length != 2) {
          throw Exception('Format koordinat tidak valid: $cleanedLocation');
        }
        
        final first = double.parse(parts[0]);
        final second = double.parse(parts[1]);
        
        // Determine which is lat and which is lng based on ranges
        // Latitude: -90 to 90, Longitude: -180 to 180
        // Indonesia: lat around -11 to 6, lng around 95 to 141
        if (first.abs() <= 90 && second.abs() > 90) {
          latitude = first;
          longitude = second;
        } else if (second.abs() <= 90 && first.abs() > 90) {
          latitude = second;
          longitude = first;
        } else {
          // Both could be valid, assume "lng lat" format (PostGIS default)
          longitude = first;
          latitude = second;
        }
        
        debugPrint('✅ Parsed space format: lat=$latitude, lng=$longitude');
      }
      else {
        throw Exception('Format koordinat tidak dikenali: $cleanedLocation');
      }
      
      // Validate coordinates
      if (latitude < -90 || latitude > 90) {
        throw Exception('Latitude tidak valid: $latitude (harus antara -90 dan 90)');
      }
      
      if (longitude < -180 || longitude > 180) {
        throw Exception('Longitude tidak valid: $longitude (harus antara -180 dan 180)');
      }
      
      final tokoLocation = LatLng(latitude, longitude);
      
      debugPrint('✅ Final location: Lat=$latitude, Lng=$longitude');

      // Navigate ke map viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UmkmLocationMapViewer(
            tokoLocation: tokoLocation,
            tokoName: umkm.namaToko,
            tokoAddress: umkm.alamatTokoLengkap ?? umkm.alamatToko,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error parsing location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Gagal Membuka Peta',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.toString(),
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ========================================================================
  // IMAGE DIALOG
  // ========================================================================

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // APPROVE & REJECT
  // ========================================================================

  Future<void> _approveUmkm(UmkmVerification umkm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menerima UMKM ${umkm.namaToko}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await context.read<AdminProvider>().approveUmkm(
          umkm.idUser,
          umkm.idUmkm,
        );
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('UMKM ${umkm.namaToko} berhasil diverifikasi'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            widget.onBackToList();
            context.read<AdminProvider>().loadPendingUmkm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menyetujui UMKM'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectUmkm(UmkmVerification umkm) async {
    final TextEditingController reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Verifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menolak UMKM ${umkm.namaToko}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan (opsional)',
                border: OutlineInputBorder(),
                hintText: 'Masukkan alasan penolakan',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await context.read<AdminProvider>().rejectUmkm(
          umkm.idUser,
          umkm.idUmkm,
          reasonController.text.trim(),
        );
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('UMKM ${umkm.namaToko} ditolak'),
                backgroundColor: const Color(0xFFF59E0B),
              ),
            );
            widget.onBackToList();
            context.read<AdminProvider>().loadPendingUmkm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menolak UMKM'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}