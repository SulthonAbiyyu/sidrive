// ============================================================================
// KTM_VERIFICATION_ADMIN_CONTENT.DART - REVISED
// UI/UX COMPACT & CLEAN - All elements proportional and easy to read
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/ktm_verification_model.dart';
import 'package:intl/intl.dart';

class KtmVerificationAdminContent extends StatefulWidget {
  const KtmVerificationAdminContent({super.key});

  @override
  State<KtmVerificationAdminContent> createState() => _KtmVerificationAdminContentState();
}

class _KtmVerificationAdminContentState extends State<KtmVerificationAdminContent> {
  KtmVerificationModel? _selectedRequest;
  bool _isLoadingDetail = false;
  final TextEditingController _rejectionReasonController = TextEditingController();

  // ✅ Track jumlah KTM pending untuk detect perubahan realtime dari provider
  int _lastKtmCount = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  /// ✅ AUTO-RELOAD: AdminProvider.startRealtimeBadges() subscribe 'ktm_verification_requests'.
  /// Saat ada pendaftaran KTM baru, pendingKtmVerifications.length berubah →
  /// widget ini detect perubahan dan rebuild otomatis via context.watch di build().
  /// Tidak perlu subscription lokal sama sekali.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCount = context.read<AdminProvider>().pendingKtmVerifications.length;
    if (_lastKtmCount != -1 && currentCount != _lastKtmCount) {
      debugPrint('🔴 [KTM] Count berubah ($currentCount) → data sudah diupdate provider');
      // Data sudah ada di provider (context.watch di build() akan rebuild otomatis)
    }
    _lastKtmCount = currentCount;
  }

  Future<void> _loadData() async {
    final provider = context.read<AdminProvider>();
    await provider.loadPendingKtmVerifications();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

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
          _buildHeader(provider),
          const Divider(height: 1),
          Expanded(
            child: _selectedRequest == null
                ? _buildListView(provider)
                : _buildDetailView(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HEADER - COMPACT VERSION
  // ============================================================================
  Widget _buildHeader(AdminProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_selectedRequest != null)
            IconButton(
              onPressed: () => setState(() => _selectedRequest = null),
              icon: const Icon(Icons.arrow_back, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),
          if (_selectedRequest != null) const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF5DADE2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: Color(0xFF5DADE2),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedRequest == null ? 'Verifikasi KTM' : 'Detail Verifikasi',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  _selectedRequest == null
                      ? '${provider.pendingKtmVerifications.length} pending'
                      : 'NIM: ${_selectedRequest!.nim}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
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

  // ============================================================================
  // LIST VIEW - COMPACT VERSION
  // ============================================================================
  Widget _buildListView(AdminProvider provider) {
    if (provider.isLoadingKtmVerifications) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (provider.pendingKtmVerifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'Tidak ada verifikasi pending',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.pendingKtmVerifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final request = provider.pendingKtmVerifications[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  // ============================================================================
  // REQUEST CARD - COMPACT VERSION
  // ============================================================================
  Widget _buildRequestCard(KtmVerificationModel request) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedRequest = request),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Photo preview - SMALL
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  request.fotoKtmUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NIM: ${request.nim}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (request.extractedName != null)
                      Text(
                        request.extractedName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(request.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // PHOTO ZOOM VIEWER - Full screen dialog dengan InteractiveViewer
  // ============================================================================
  void _openPhotoZoom(String imageUrl) {
    final TransformationController transformController = TransformationController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // ── Foto interaktif (pinch zoom + pan + double-tap) ──
            GestureDetector(
              onDoubleTapDown: (details) {
                final position = details.localPosition;
                final isZoomed = transformController.value.getMaxScaleOnAxis() > 1.5;
                if (isZoomed) {
                  // Reset ke normal
                  transformController.value = Matrix4.identity();
                } else {
                  // Zoom in ke posisi double-tap
                  final x = -position.dx * 1.5;
                  final y = -position.dy * 1.5;
                  transformController.value = Matrix4.identity()
                    ..translate(x, y)
                    ..scale(2.5);
                }
              },
              onDoubleTap: () {}, // required agar onDoubleTapDown aktif
              child: InteractiveViewer(
                transformationController: transformController,
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),

            // ── Tombol tutup ──
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),

            // ── Hint zoom ──
            Positioned(
              bottom: MediaQuery.of(ctx).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, color: Colors.white70, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Pinch / double-tap untuk zoom',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DETAIL VIEW - COMPACT VERSION
  // ============================================================================
  Widget _buildDetailView() {
    if (_selectedRequest == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto KTM - centered, clickable, zoomable ──
          Center(
            child: Column(
              children: [
                // Label hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Ketuk foto untuk memperbesar',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Foto container
                GestureDetector(
                  onTap: () => _openPhotoZoom(_selectedRequest!.fotoKtmUrl),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480, maxHeight: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            _selectedRequest!.fotoKtmUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[50],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                        // Zoom icon overlay
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Divider sebelum info ──
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 14),

          // Info - COMPACT
          _buildInfoRow('NIM', _selectedRequest!.nim),
          if (_selectedRequest!.extractedName != null)
            _buildInfoRow('Nama', _selectedRequest!.extractedName!),
          _buildInfoRow(
            'Waktu Submit',
            DateFormat('dd MMM yyyy, HH:mm').format(_selectedRequest!.createdAt),
          ),
          _buildInfoRow(
            'Status',
            _selectedRequest!.status.toUpperCase(),
          ),

          const SizedBox(height: 20),

          // Action Buttons - COMPACT
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoadingDetail ? null : _showRejectDialog,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text(
                    'Tolak',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoadingDetail ? null : _approveRequest,
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text(
                    'Setujui',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
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

  // ============================================================================
  // INFO ROW - COMPACT VERSION
  // ============================================================================
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // REJECT DIALOG
  // ============================================================================
  void _showRejectDialog() {
    _rejectionReasonController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Tolak Verifikasi KTM',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alasan penolakan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rejectionReasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Contoh: Foto KTM tidak jelas, NIM tidak terbaca',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Tolak', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // APPROVE REQUEST
  // ============================================================================
  Future<void> _approveRequest() async {
    if (_selectedRequest == null) return;

    setState(() => _isLoadingDetail = true);

    try {
      final provider = context.read<AdminProvider>();
      final success = await provider.approveKtmVerification(_selectedRequest!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verifikasi KTM disetujui'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _selectedRequest = null);
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal approve verifikasi'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  // ============================================================================
  // REJECT REQUEST
  // ============================================================================
  Future<void> _rejectRequest() async {
    if (_selectedRequest == null) return;

    final reason = _rejectionReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan penolakan harus diisi'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoadingDetail = true);

    try {
      final provider = context.read<AdminProvider>();
      final success = await provider.rejectKtmVerification(
        _selectedRequest!.id,
        reason,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Verifikasi KTM ditolak'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _selectedRequest = null);
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal reject verifikasi'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }
}