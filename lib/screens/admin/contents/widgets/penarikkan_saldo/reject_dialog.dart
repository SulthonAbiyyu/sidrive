// lib/screens/admin/contents/widgets/reject_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// REJECT DIALOG - FIXED UI/UX VERSION
/// ✅ Light mode (background putih)
/// ✅ No rekening TIDAK disamarkan
/// ✅ Karakter encoding dihilangkan
/// ✅ Content responsive, tidak jumbo
/// ✅ Font input terlihat jelas (hitam)
/// ✅ TextFormField dengan background putih
/// ============================================================================

class RejectDialog extends StatefulWidget {
  final dynamic penarikan;

  const RejectDialog({
    super.key,
    required this.penarikan,
  });

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<RejectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

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
                color: Color(0xFFFEE2E2), // Light red background
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tolak Penarikan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
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
                child: Form(
                  key: _formKey,
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
                                color: Color(0xFFEF4444),
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

                      // Alasan penolakan
                      const Text(
                        'Alasan Penolakan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        enabled: !_isProcessing,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827), // ✅ TEXT HITAM, TERLIHAT JELAS
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan alasan penolakan...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white, // ✅ BACKGROUND PUTIH
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan penolakan wajib diisi';
                          }
                          if (value.trim().length < 10) {
                            return 'Alasan terlalu pendek (min 10 karakter)';
                          }
                          return null;
                        },
                      ),

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

                      // Warning box - ✅ TANPA KARAKTER ANEH
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
                                'PENTING:\n'
                                '• Saldo akan dikembalikan ke wallet user\n'
                                '• User akan menerima notifikasi\n'
                                '• Transaksi refund akan tercatat',
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
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processRejection,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cancel, size: 18),
                    label: Text(_isProcessing ? 'Memproses...' : 'Ya, Tolak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
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

  Future<void> _processRejection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final reason = _reasonController.text.trim();
      
      final adminProvider = context.read<AdminProvider>();
      final success = await adminProvider.rejectWithdrawalWithRefund(
        withdrawalId: widget.penarikan.idPenarikan,
        reason: reason,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, {
          'success': true,
          'message': 'Penarikan ditolak & saldo dikembalikan',
        });
      } else {
        throw Exception(adminProvider.errorMessage ?? 'Gagal menolak penarikan');
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
}