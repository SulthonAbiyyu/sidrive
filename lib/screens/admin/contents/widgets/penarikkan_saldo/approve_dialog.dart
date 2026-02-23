// lib/screens/admin/contents/widgets/approve_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// APPROVE DIALOG - FIXED UI/UX VERSION
/// ✅ Light mode (background putih)
/// ✅ No rekening TIDAK disamarkan
/// ✅ Karakter encoding dihilangkan
/// ✅ Content responsive, tidak jumbo
/// ✅ Font input terlihat jelas (hitam)
/// ============================================================================

class ApproveDialog extends StatefulWidget {
  final dynamic penarikan;

  const ApproveDialog({
    super.key,
    required this.penarikan,
  });

  @override
  State<ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<ApproveDialog> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  bool _isProcessing = false;
  String? _uploadedFileUrl;
  XFile? _selectedFile;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Dialog(
      backgroundColor: Colors.white, // ✅ LIGHT MODE
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500), // ✅ Max width responsive
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4), // Light green background
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Setujui Penarikan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: (_isUploading || _isProcessing) 
                        ? null 
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info penarikan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama user
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.penarikan.nama ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Amount (BIG)
                          Text(
                            currencyFormat.format(widget.penarikan.jumlah ?? 0),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          
                          // Bank info - ✅ NO REKENING TIDAK DISAMARKAN
                          _buildInfoRow('Bank', widget.penarikan.namaBank ?? '-'),
                          const SizedBox(height: 8),
                          _buildInfoRow('No. Rekening', widget.penarikan.nomorRekening ?? '-'), // ✅ FULL NUMBER
                          const SizedBox(height: 8),
                          _buildInfoRow('Atas Nama', widget.penarikan.namaRekening ?? '-'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Upload section
                    const Text(
                      'Upload Bukti Transfer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_selectedFile == null)
                      _buildUploadButton()
                    else
                      _buildFilePreview(),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Info box - ✅ TANPA KARAKTER ANEH
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE047)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFFCA8A04), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Format: JPG, PNG, atau PDF\n'
                              'Maksimal ukuran: 5 MB\n'
                              'Pastikan bukti transfer jelas dan valid',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (_isUploading || _isProcessing) 
                        ? null 
                        : () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_isUploading || _isProcessing || _uploadedFileUrl == null)
                        ? null
                        : _processApproval,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 18),
                    label: Text(_isProcessing ? 'Memproses...' : 'Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
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
        const Text(': ', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return InkWell(
      onTap: _isUploading ? null : _pickAndUploadFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFFAFAFA),
        ),
        child: Column(
          children: [
            if (_isUploading)
              const CircularProgressIndicator()
            else
              const Icon(
                Icons.cloud_upload_rounded,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            const SizedBox(height: 12),
            Text(
              _isUploading ? 'Mengupload...' : 'Klik untuk upload bukti transfer',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'JPG, PNG, atau PDF (max 5MB)',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFD1FAE5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File berhasil diupload',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedFile!.name,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF047857),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeFile,
            icon: const Icon(Icons.close, color: Color(0xFF059669), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (file == null) {
        setState(() => _isUploading = false);
        return;
      }

      // Validasi ukuran
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar (max 5MB)');
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = widget.penarikan.idUser;
      final extension = file.name.split('.').last;
      final filename = '$userId/${timestamp}_proof.$extension';

      // Upload
      final bytes = await file.readAsBytes();
      await _supabase.storage.from('withdrawal-proofs').uploadBinary(
        filename,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: false,
        ),
      );

      final publicUrl = _supabase.storage
          .from('withdrawal-proofs')
          .getPublicUrl(filename);

      setState(() {
        _selectedFile = file;
        _uploadedFileUrl = publicUrl;
        _isUploading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isUploading = false;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _uploadedFileUrl = null;
      _errorMessage = null;
    });
  }

  Future<void> _processApproval() async {
    if (_uploadedFileUrl == null) return;

    setState(() => _isProcessing = true);

    try {
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.approveWithdrawalWithProof(
        withdrawalId: widget.penarikan.idPenarikan,
        proofUrl: _uploadedFileUrl!,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, {
          'success': true,
          'message': 'Penarikan berhasil disetujui',
        });
      } else {
        throw Exception(adminProvider.errorMessage ?? 'Gagal menyetujui penarikan');
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}