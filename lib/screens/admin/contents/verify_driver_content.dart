import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VerifyDriverContent extends StatefulWidget {
  final String? selectedDriverId;
  final Function(String) onDriverSelected;
  final VoidCallback onBackToList;

  const VerifyDriverContent({
    super.key,
    this.selectedDriverId,
    required this.onDriverSelected,
    required this.onBackToList,
  });

  @override
  State<VerifyDriverContent> createState() => _VerifyDriverContentState();
}

class _VerifyDriverContentState extends State<VerifyDriverContent> {
  DriverVerification? _detailDriver;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [VerifyDriver] Screen initialized');
    _loadDetailIfNeeded();
  }

  @override
  void didUpdateWidget(VerifyDriverContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDriverId != widget.selectedDriverId) {
      debugPrint('🔄 [VerifyDriver] Selected driver changed: ${widget.selectedDriverId}');
      _loadDetailIfNeeded();
    }
  }

  Future<void> _loadDetailIfNeeded() async {
    if (widget.selectedDriverId != null) {
      setState(() => _isLoadingDetail = true);
      debugPrint('📥 [VerifyDriver] Loading detail for: ${widget.selectedDriverId}');
      
      try {
        final adminProvider = context.read<AdminProvider>();
        final driver = await adminProvider.getDriverDetail(widget.selectedDriverId!);
        
        if (mounted) {
          setState(() {
            _detailDriver = driver;
            _isLoadingDetail = false;
          });
          
          if (driver != null) {
            debugPrint('✅ [VerifyDriver] Detail loaded: ${driver.nama} - ${driver.jenisKendaraan}');
          } else {
            debugPrint('⚠️ [VerifyDriver] Driver not found');
          }
        }
      } catch (e) {
        debugPrint('❌ [VerifyDriver] Error loading detail: $e');
        if (mounted) {
          setState(() => _isLoadingDetail = false);
          _showErrorToast('Gagal memuat data driver');
        }
      }
    } else {
      setState(() {
        _detailDriver = null;
        _isLoadingDetail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDriverId != null) {
      return _buildDetailView();
    }
    return _buildListView();
  }

  // ========================================================================
  // LIST VIEW
  // ========================================================================
  
  Widget _buildListView() {
    final adminProvider = context.watch<AdminProvider>();
    final pendingDrivers = adminProvider.pendingDrivers;

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
          _buildListHeader(context, adminProvider),
          const Divider(height: 1),
          Expanded(
            child: pendingDrivers.isEmpty
                ? _buildEmptyState(context)
                : RefreshIndicator(
                    onRefresh: () async {
                      debugPrint('🔄 [VerifyDriver] Refreshing list...');
                      await context.read<AdminProvider>().loadPendingDrivers();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingDrivers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final driver = pendingDrivers[index];
                        return _buildDriverCard(context, driver);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(BuildContext context, AdminProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF3B82F6),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifikasi Kendaraan Driver',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '${provider.pendingDrivers.length} kendaraan menunggu verifikasi',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              debugPrint('🔄 [VerifyDriver] Manual refresh triggered');
              context.read<AdminProvider>().loadPendingDrivers();
            },
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh Data',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 80,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Semua Kendaraan Terverifikasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tidak ada kendaraan driver yang perlu diverifikasi',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, DriverVerification driver) {
    // Icon berdasarkan jenis kendaraan
    final isMotor = driver.jenisKendaraan.toLowerCase() == 'motor';
    final vehicleIcon = isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded;
    final vehicleColor = isMotor ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('👆 [VerifyDriver] Card tapped: ${driver.idVehicle}');
          widget.onDriverSelected(driver.idVehicle);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Vehicle icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: vehicleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: vehicleColor.withOpacity(0.2)),
                ),
                child: Icon(vehicleIcon, color: vehicleColor, size: 18),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.nama,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIM: ${driver.nim} • ${driver.platNomor}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver.merkKendaraan} • ${driver.warnaKendaraan}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(driver.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }


  // ========================================================================
  // DETAIL VIEW
  // ========================================================================
  
  Widget _buildDetailView() {
    if (_isLoadingDetail) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memuat data driver...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (_detailDriver == null) {
      return _buildDetailErrorState();
    }

    return _buildDetailContent(_detailDriver!);
  }

  Widget _buildDetailErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
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
            'Data kendaraan driver tidak tersedia',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              debugPrint('🔙 [VerifyDriver] Back to list from error state');
              widget.onBackToList();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Kembali ke Daftar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(DriverVerification driver) {
    final isMotor = driver.jenisKendaraan.toLowerCase() == 'motor';
    
    return Column(
      children: [
        _buildDetailHeader(driver),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data Pribadi
                _buildDetailSection(
                  title: 'Data Pribadi Driver',
                  icon: Icons.person_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Nama Lengkap', driver.nama),
                      _buildDetailRow('NIM', driver.nim),
                      _buildDetailRow('No. Telp', driver.noTelp),
                      _buildDetailRow('Email', driver.email),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data Kendaraan
                _buildDetailSection(
                  title: 'Data Kendaraan ${isMotor ? "Motor" : "Mobil"}',
                  icon: isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                  gradient: LinearGradient(
                    colors: isMotor 
                        ? [Color(0xFF10B981), Color(0xFF059669)]
                        : [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Jenis Kendaraan', driver.jenisKendaraan.toUpperCase()),
                      _buildDetailRow('Plat Nomor', driver.platNomor),
                      _buildDetailRow('Merk Kendaraan', driver.merkKendaraan),
                      _buildDetailRow('Warna Kendaraan', driver.warnaKendaraan),
                      _buildDetailRow('Status', 'Menunggu Verifikasi', 
                        valueColor: const Color(0xFFD97706)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dokumen Kendaraan
                _buildDocumentsSection(driver),
                const SizedBox(height: 24),

                // Info Rekening Bank (jika ada)
                if (driver.namaBank != null && 
                    driver.nomorRekening != null &&
                    driver.namaBank!.isNotEmpty &&
                    driver.nomorRekening!.isNotEmpty) ...[
                  _buildDetailSection(
                    title: 'Informasi Rekening Bank',
                    icon: Icons.account_balance_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Nama Bank', driver.namaBank ?? '-'),
                        _buildDetailRow('Nomor Rekening', driver.nomorRekening ?? '-'),
                        _buildDetailRow('Atas Nama', driver.namaRekening ?? '-'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Warning jika tidak ada rekening
                if (driver.namaBank == null || driver.namaBank!.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: const Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Driver belum menambahkan informasi rekening bank.\nBank info bisa diupdate di profil user.',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 100), // Space untuk action buttons
              ],
            ),
          ),
        ),
        _buildDetailActionButtons(driver),
      ],
    );
  }

  Widget _buildDetailHeader(DriverVerification driver) {
    final isMotor = driver.jenisKendaraan.toLowerCase() == 'motor';
    final vehicleIcon = isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded;
    final vehicleColor = isMotor ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              debugPrint('🔙 [VerifyDriver] Back to list');
              widget.onBackToList();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Kembali',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: vehicleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: vehicleColor.withOpacity(0.3)),
            ),
            child: Icon(vehicleIcon, size: 20, color: vehicleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Verifikasi Kendaraan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${driver.nama} • ${driver.jenisKendaraan.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(DriverVerification driver) {
    return _buildDetailSection(
      title: 'Dokumen Kendaraan',
      icon: Icons.description_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
      ),
      child: Column(
        children: [
          if (driver.fotoSTNK != null && driver.fotoSTNK!.isNotEmpty) ...[
            _buildDocumentItem('STNK', driver.fotoSTNK!),
            const SizedBox(height: 12),
          ],
          if (driver.fotoSIM != null && driver.fotoSIM!.isNotEmpty) ...[
            _buildDocumentItem('SIM', driver.fotoSIM!),
            const SizedBox(height: 12),
          ],
          if (driver.fotoKendaraan != null && driver.fotoKendaraan!.isNotEmpty) ...[
            _buildDocumentItem('Foto Kendaraan', driver.fotoKendaraan!),
          ],
          
          // Warning jika ada dokumen yang kosong
          if ((driver.fotoSTNK == null || driver.fotoSTNK!.isEmpty) ||
              (driver.fotoSIM == null || driver.fotoSIM!.isEmpty) ||
              (driver.fotoKendaraan == null || driver.fotoKendaraan!.isEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: const Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Beberapa dokumen belum dilengkapi!',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String label, String url) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            debugPrint('🖼️ [VerifyDriver] Opening image: $label');
            _showImageDialog(url, label);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFFEE2E2),
                      child: const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto $label',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap untuk memperbesar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.zoom_in_rounded,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () {
                  debugPrint('🔙 [VerifyDriver] Closing image dialog');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Tutup',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailActionButtons(DriverVerification driver) {
    final adminProvider = context.watch<AdminProvider>();
    final isProcessing = adminProvider.isLoading;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : () {
                debugPrint('❌ [VerifyDriver] Reject button pressed');
                _showRejectDialog(driver);
              },
              icon: const Icon(Icons.close_rounded, size: 20),
              label: const Text(
                'Tolak',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFEF4444).withOpacity(0.5),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isProcessing ? null : () {
                debugPrint('✅ [VerifyDriver] Approve button pressed');
                _showApproveDialog(driver);
              },
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                isProcessing ? 'Memproses...' : 'Setujui Kendaraan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // APPROVE DIALOG
  // ========================================================================

  Future<void> _showApproveDialog(DriverVerification driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Persetujuan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menyetujui kendaraan ini?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Driver', driver.nama),
                  const SizedBox(height: 8),
                  _buildInfoRow('Kendaraan', '${driver.jenisKendaraan.toUpperCase()} - ${driver.platNomor}'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Merk/Warna', '${driver.merkKendaraan} (${driver.warnaKendaraan})'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver akan mendapat notifikasi persetujuan dan dapat langsung menggunakan kendaraan ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔙 [VerifyDriver] Approve cancelled');
              Navigator.pop(context, false);
            },
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              debugPrint('✅ [VerifyDriver] Approve confirmed');
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Ya, Setujui'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _processApprove(driver);
    }
  }

  Future<void> _processApprove(DriverVerification driver) async {
    debugPrint('🔥🔥🔥 BEFORE APPROVE - CEK DATA DRIVER 🔥🔥🔥');
    debugPrint('   idUser: ${driver.idUser}');
    debugPrint('   idDriver: ${driver.idDriver}');
    debugPrint('   idVehicle: ${driver.idVehicle}');
    debugPrint('   nama: ${driver.nama}');
    debugPrint('   jenis_kendaraan: ${driver.jenisKendaraan}');
    debugPrint('   plat_nomor: ${driver.platNomor}');
    debugPrint('🔥🔥🔥 END DEBUG 🔥🔥🔥');
    
    try {
      final success = await context.read<AdminProvider>().approveDriver(
        driver.idUser,      // ✅ id_user dari users table
        driver.idDriver,    // ✅ id_driver dari drivers table
        driver.idVehicle,   // ✅ id_vehicle dari driver_vehicles table
      );

      if (mounted) {
        if (success) {
          debugPrint('✅ [VerifyDriver] Approval successful');
          _showSuccessToast(
            'Kendaraan ${driver.jenisKendaraan} ${driver.platNomor} berhasil disetujui!\n'
            'Driver ${driver.nama} sudah bisa menggunakan kendaraan ini untuk menerima pesanan.'
          );
          widget.onBackToList();
          await context.read<AdminProvider>().loadPendingDrivers();
        } else {
          debugPrint('❌ [VerifyDriver] Approval failed');
          final errorMsg = context.read<AdminProvider>().errorMessage;
          _showErrorToast(errorMsg ?? 'Gagal menyetujui kendaraan. Silakan coba lagi.');
        }
      }
    } catch (e) {
      debugPrint('❌ [VerifyDriver] Approval error: $e');
      if (mounted) {
        _showErrorToast('Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> _processReject(DriverVerification driver, String reason) async {
    debugPrint('📋 [VerifyDriver] Processing rejection...');
    debugPrint('   ID User: ${driver.idUser}');
    debugPrint('   ID Driver: ${driver.idDriver}');
    debugPrint('   ID Vehicle: ${driver.idVehicle}');
    debugPrint('   Reason: $reason');
    
    try {
      final success = await context.read<AdminProvider>().rejectDriver(
        driver.idUser,      // ✅ id_user dari users table
        driver.idDriver,    // ✅ id_driver dari drivers table
        driver.idVehicle,   // ✅ id_vehicle dari driver_vehicles table
        reason,
      );

      if (mounted) {
        if (success) {
          debugPrint('✅ [VerifyDriver] Rejection successful');
          _showWarningToast(
            'Kendaraan ${driver.jenisKendaraan} ${driver.platNomor} ditolak.\n'
            'Driver ${driver.nama} akan menerima notifikasi penolakan.'
          );
          widget.onBackToList();
          await context.read<AdminProvider>().loadPendingDrivers();
        } else {
          debugPrint('❌ [VerifyDriver] Rejection failed');
          final errorMsg = context.read<AdminProvider>().errorMessage;
          _showErrorToast(errorMsg ?? 'Gagal menolak kendaraan. Silakan coba lagi.');
        }
      }
    } catch (e) {
      debugPrint('❌ [VerifyDriver] Rejection error: $e');
      if (mounted) {
        _showErrorToast('Terjadi kesalahan: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // ========================================================================
  // REJECT DIALOG
  // ========================================================================

  Future<void> _showRejectDialog(DriverVerification driver) async {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tolak Verifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menolak kendaraan ini?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Driver', driver.nama),
                    const SizedBox(height: 8),
                    _buildInfoRow('Kendaraan', '${driver.jenisKendaraan.toUpperCase()} - ${driver.platNomor}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alasan Penolakan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Foto STNK tidak jelas, mohon upload ulang',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan penolakan wajib diisi';
                  }
                  if (value.trim().length < 10) {
                    return 'Alasan minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Driver akan menerima notifikasi penolakan beserta alasannya.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔙 [VerifyDriver] Reject cancelled');
              Navigator.pop(context, false);
            },
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                debugPrint('❌ [VerifyDriver] Reject confirmed');
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Ya, Tolak'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _processReject(driver, reasonController.text.trim());
    }

    reasonController.dispose();
  }

  // ========================================================================
  // HELPER WIDGETS
  // ========================================================================

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================================
  // TOAST NOTIFICATIONS - Clean UI
  // ========================================================================

  void _showSuccessToast(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showWarningToast(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}