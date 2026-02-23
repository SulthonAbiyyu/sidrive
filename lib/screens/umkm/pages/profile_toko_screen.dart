// ============================================================================
// PROFIL_TOKO_SCREEN.DART
// Screen untuk lihat & edit info toko
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/models/umkm_model.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/rating_ulasan_service.dart';
import 'package:sidrive/core/widgets/rating_widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:sidrive/screens/umkm/pages/umkm_set_location_screen.dart';


class ProfilTokoScreen extends StatefulWidget {
  const ProfilTokoScreen({super.key});

  @override
  State<ProfilTokoScreen> createState() => _ProfilTokoScreenState();
}

class _ProfilTokoScreenState extends State<ProfilTokoScreen> {
  final _umkmService = UmkmService();
  final _supabase = Supabase.instance.client;
  final _ratingService = RatingUlasanService();
  Map<String, dynamic>? _ratingBreakdown;
  List<Map<String, dynamic>>? _reviews;
  bool _isLoadingRating = false;
  LatLng? _currentLokasiToko;
  String? _currentAlamatLengkap;


  UmkmModel? _umkmData;
  bool _isLoading = true;
  bool _isEditMode = false;

  // Controllers
  final _namaTokoController = TextEditingController();
  final _alamatTokoController = TextEditingController();
  final _deskripsiTokoController = TextEditingController();
  final _namaBankController = TextEditingController();
  final _namaRekeningController = TextEditingController();
  final _nomorRekeningController = TextEditingController();

  File? _newFotoToko;
  TimeOfDay? _jamBuka;
  TimeOfDay? _jamTutup;

  @override
  void initState() {
    super.initState();
    _loadUmkmData();
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    _deskripsiTokoController.dispose();
    _namaBankController.dispose();
    _namaRekeningController.dispose();
    _nomorRekeningController.dispose();
    super.dispose();
  }

  Future<void> _loadUmkmData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;

      if (userId != null) {
        // Load UMKM data
        final umkm = await _umkmService.getUmkmByUserId(userId);

        // Load bank info
        final userData = await _supabase
            .from('users')
            .select('nama_bank, nomor_rekening, nama_rekening')
            .eq('id_user', userId)
            .single();

        if (umkm != null && mounted) {
          setState(() {
            _umkmData = umkm;
            _namaTokoController.text = umkm.namaToko;
            _alamatTokoController.text = umkm.alamatToko;
            _deskripsiTokoController.text = umkm.deskripsiToko ?? '';
            
            // SET BANK INFO
            _namaBankController.text = userData['nama_bank'] ?? '';
            _nomorRekeningController.text = userData['nomor_rekening'] ?? '';
            _namaRekeningController.text = userData['nama_rekening'] ?? '';

            // ✅ LOAD LOKASI TOKO
            _currentLokasiToko = umkm.lokasiTokoLatLng;
            _currentAlamatLengkap = umkm.alamatTokoLengkap;

            // Parse jam operasional
            if (umkm.jamBuka != null) {
              final parts = umkm.jamBuka!.split(':');
              if (parts.length >= 2) {
                _jamBuka = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }
            }
            if (umkm.jamTutup != null) {
              final parts = umkm.jamTutup!.split(':');
              if (parts.length >= 2) {
                _jamTutup = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }
            }
          });

          _loadRatingData(umkm.idUmkm);
          debugPrint('✅ Bank info loaded: ${_namaBankController.text}');
          debugPrint('✅ Lokasi toko loaded: $_currentLokasiToko');
        }
      }
    } catch (e) {
      print('❌ Error load UMKM data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _setLokasiToko() async {
    if (_umkmData == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => UmkmSetLocationScreen(
          idUmkm: _umkmData!.idUmkm,
          currentAddress: _currentAlamatLengkap ?? _umkmData!.alamatToko,
          currentLocation: _currentLokasiToko,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentLokasiToko = result['location'] as LatLng?;
        _currentAlamatLengkap = result['address'] as String?;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Lokasi toko berhasil diperbarui'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload data untuk refresh tampilan
      await _loadUmkmData();
    }
  }


  Future<void> _loadRatingData(String idUmkm) async {
    setState(() => _isLoadingRating = true);
    
    try {
      final breakdown = await _ratingService.getRatingBreakdown(
        targetType: 'umkm',
        targetId: idUmkm,
      );
      
      final reviews = await _ratingService.getUmkmReviews(
        idUmkm: idUmkm,
        limit: 5,
      );
      
      if (mounted) {
        setState(() {
          _ratingBreakdown = breakdown;
          _reviews = reviews;
          _isLoadingRating = false;
        });
      }
    } catch (e) {
      print('❌ Error load rating: $e');
      setState(() => _isLoadingRating = false);
    }
  }


  Future<void> _toggleTokoStatus() async {
    if (_umkmData == null) return;

    final newStatus = _umkmData!.isBuka ? 'tutup' : 'buka';

    final success = await _umkmService.updateStatusToko(
      _umkmData!.idUmkm,
      newStatus,
    );

    if (success) {
      setState(() {
        _umkmData = _umkmData!.copyWith(statusToko: newStatus);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'buka'
                ? '✅ Toko dibuka'
                : '⏸️ Toko ditutup sementara',
          ),
          backgroundColor:
              newStatus == 'buka' ? Colors.green : Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickTokoImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newFotoToko = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  Future<void> _selectTime(BuildContext context, bool isJamBuka) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isJamBuka ? _jamBuka ?? TimeOfDay.now() : _jamTutup ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isJamBuka) {
          _jamBuka = picked;
        } else {
          _jamTutup = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '-';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveChanges() async {
    if (_umkmData == null) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Upload foto baru jika ada
      String? fotoTokoUrl = _umkmData!.fotoToko;
      if (_newFotoToko != null) {
        // fotoTokoUrl = await StorageService.uploadTokoPhoto(_newFotoToko!);
        fotoTokoUrl = 'https://via.placeholder.com/400x200'; // Dummy
      }

      final jamBukaStr = _jamBuka != null
          ? '${_jamBuka!.hour.toString().padLeft(2, '0')}:${_jamBuka!.minute.toString().padLeft(2, '0')}:00'
          : null;
      final jamTutupStr = _jamTutup != null
          ? '${_jamTutup!.hour.toString().padLeft(2, '0')}:${_jamTutup!.minute.toString().padLeft(2, '0')}:00'
          : null;

      // 🔥 TAMBAHKAN INI - Update bank info di tabel users
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId != null && 
          _namaBankController.text.trim().isNotEmpty && 
          _nomorRekeningController.text.trim().isNotEmpty) {
        await _supabase.from('users').update({
          'nama_bank': _namaBankController.text.trim(),
          'nomor_rekening': _nomorRekeningController.text.trim(),
          'nama_rekening': _namaRekeningController.text.trim().isEmpty 
              ? authProvider.currentUser?.nama 
              : _namaRekeningController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_user', userId);
        
        debugPrint('✅ Bank info updated in users table');
      }

      final success = await _umkmService.updateInfoToko(
        idUmkm: _umkmData!.idUmkm,
        namaToko: _namaTokoController.text.trim(),
        alamatToko: _alamatTokoController.text.trim(),
        deskripsiToko: _deskripsiTokoController.text.trim(),
        fotoToko: fotoTokoUrl,
        jamBuka: jamBukaStr,
        jamTutup: jamTutupStr,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil toko berhasil diperbarui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _isEditMode = false;
          _newFotoToko = null;
        });

        await _loadUmkmData();
      }
    } catch (e) {
      _showError('Gagal update profil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profil Toko'),
        backgroundColor: Colors.orange.shade600,
        actions: [
          if (!_isEditMode && _umkmData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditMode = true);
              },
              tooltip: 'Edit Profil',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.orange),
              ),
            )
          : _umkmData == null
              ? _buildEmptyState()
              : _isEditMode
                  ? _buildEditMode()
                  : _buildViewMode(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ResponsiveMobile.horizontalPadding(context, 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: ResponsiveMobile.scaledFont(64),
              color: Colors.grey.shade400,
            ),
            ResponsiveMobile.vSpace(16),
            Text(
              'Toko Belum Dibuat',
              style: TextStyle(
                fontSize: ResponsiveMobile.titleSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveMobile.vSpace(8),
            Text(
              'Silakan setup toko terlebih dahulu',
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header dengan foto toko
          Stack(
            children: [
              // Foto Toko
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  image: _umkmData!.fotoToko != null
                      ? DecorationImage(
                          image: NetworkImage(_umkmData!.fotoToko!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _umkmData!.fotoToko == null
                    ? Center(
                        child: Icon(
                          Icons.store,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : null,
              ),

              // Gradient overlay
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Nama Toko
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _umkmData!.namaToko,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _umkmData!.isBuka
                                ? Colors.green
                                : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _umkmData!.isBuka ? 'BUKA' : 'TUTUP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _umkmData!.jamOperasional,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Buka/Tutup Toko
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Status Toko',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _umkmData!.isBuka
                          ? 'Toko sedang buka, customer bisa pesan'
                          : 'Toko ditutup sementara',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    value: _umkmData!.isBuka,
                    activeColor: Colors.green,
                    onChanged: (value) => _toggleTokoStatus(),
                  ),
                ),

                const SizedBox(height: 20),

                // Info Toko
                const Text(
                  'Informasi Toko',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.category,
                  title: 'Kategori',
                  content: _umkmData!.kategoriToko ?? '-',
                ),
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Alamat',
                  content: _umkmData!.alamatToko,
                ),
                if (_umkmData!.deskripsiToko != null &&
                    _umkmData!.deskripsiToko!.isNotEmpty)
                  _buildInfoCard(
                    icon: Icons.description,
                    title: 'Deskripsi',
                    content: _umkmData!.deskripsiToko!,
                  ),

                const SizedBox(height: 20),

                // Statistik
                const Text(
                  'Statistik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.star,
                        title: 'Rating',
                        value: _umkmData!.ratingToko.toStringAsFixed(1),
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_bag,
                        title: 'Terjual',
                        value: '${_umkmData!.jumlahProdukTerjual}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Lokasi Toko
                const Text(
                  'Lokasi Toko',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (_currentLokasiToko != null) ...[
                        // Lokasi sudah ada
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lokasi Terpasang',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentAlamatLengkap ?? _umkmData!.alamatToko,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Lat: ${_currentLokasiToko!.latitude.toStringAsFixed(6)}, Lng: ${_currentLokasiToko!.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _setLokasiToko,
                            icon: const Icon(Icons.edit_location, size: 18),
                            label: const Text(
                              'Ubah Lokasi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade700,
                              side: BorderSide(color: Colors.orange.shade700),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Belum ada lokasi
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_off,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lokasi Belum Dipasang',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pasang lokasi toko agar customer mudah menemukan Anda',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _setLokasiToko,
                            icon: const Icon(Icons.add_location, size: 18),
                            label: const Text(
                              'Pasang Lokasi Toko',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Rating & Ulasan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _isLoadingRating? 
                const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.orange),
                      ),
                    ),
                  )
                : _ratingBreakdown != null && _ratingBreakdown!['total_reviews'] > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RatingWidgets.buildRatingSummaryCard(
                            averageRating: _ratingBreakdown!['average_rating'],
                            totalReviews: _ratingBreakdown!['total_reviews'],
                            isNewDriver: false,
                          ),
                          const SizedBox(height: 16),
                          RatingWidgets.buildRatingBreakdown(
                            breakdown: _ratingBreakdown!,
                          ),
                          if (_reviews != null && _reviews!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Ulasan Terbaru',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_reviews!.map((review) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: RatingWidgets.buildReviewCard(review: review),
                              );
                            }).toList()),
                          ],
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada ulasan',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),

                const SizedBox(height: 20),

                // Info Bank
                const Text(
                  'Informasi Bank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.account_balance,
                  title: 'Bank',
                  content: _namaBankController.text.isEmpty ? '-' : _namaBankController.text, // 🔥 UBAH INI
                ),
                _buildInfoCard(
                  icon: Icons.person,
                  title: 'Nama Rekening',
                  content: _namaRekeningController.text.isEmpty ? '-' : _namaRekeningController.text, // 🔥 UBAH INI
                ),
                _buildInfoCard(
                  icon: Icons.credit_card,
                  title: 'Nomor Rekening',
                  content: _nomorRekeningController.text.isEmpty ? '-' : _nomorRekeningController.text, // 🔥 UBAH INI
                  obscured: false,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto Toko
          const Text(
            'Foto Toko',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickTokoImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                image: _newFotoToko != null
                    ? DecorationImage(
                        image: FileImage(_newFotoToko!),
                        fit: BoxFit.cover,
                      )
                    : _umkmData!.fotoToko != null
                        ? DecorationImage(
                            image: NetworkImage(_umkmData!.fotoToko!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _newFotoToko == null && _umkmData!.fotoToko == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Foto Toko',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // Nama Toko
          TextField(
            controller: _namaTokoController,
            decoration: InputDecoration(
              labelText: 'Nama Toko',
              prefixIcon: const Icon(Icons.store),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Alamat
          TextField(
            controller: _alamatTokoController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Alamat',
              prefixIcon: const Icon(Icons.location_on),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Deskripsi
          TextField(
            controller: _deskripsiTokoController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              prefixIcon: const Icon(Icons.description),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Jam Operasional
          const Text(
            'Jam Operasional',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Buka',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimeOfDay(_jamBuka),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Tutup',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimeOfDay(_jamTutup),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info Bank
          const Text(
            'Informasi Bank',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _namaBankController,
            decoration: InputDecoration(
              labelText: 'Nama Bank',
              prefixIcon: const Icon(Icons.account_balance),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _namaRekeningController,
            decoration: InputDecoration(
              labelText: 'Nama Rekening',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomorRekeningController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Nomor Rekening',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditMode = false;
                      _newFotoToko = null;
                      // Reset controllers
                      _namaTokoController.text = _umkmData!.namaToko;
                      _alamatTokoController.text = _umkmData!.alamatToko;
                      _deskripsiTokoController.text =
                          _umkmData!.deskripsiToko ?? '';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    bool obscured = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  obscured && content != '-'
                      ? content.replaceRange(
                          content.length - 4, content.length, '****')
                      : content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}