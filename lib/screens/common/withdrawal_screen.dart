// lib/screens/common/withdrawal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/services/wallet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final WalletService _walletService = WalletService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  bool _isLoading = false;
  double _currentBalance = 0;
  int _dailyWithdrawalCount = 0;
  String? _selectedBank;

  final List<int> _quickAmounts = [
    50000, 100000, 250000, 500000, 1000000, 2000000,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load balance
      final balance = await _walletService.getBalance(userId);
      
      // Load daily withdrawal count
      final count = await _walletService.getPendingWithdrawalCountToday(userId);

      // Load saved bank info dari users table
      final userData = await Supabase.instance.client
          .from('users')
          .select('nama, nama_bank, nama_rekening, nomor_rekening')
          .eq('id_user', userId)
          .single();

      setState(() {
        _currentBalance = balance;
        _dailyWithdrawalCount = count;
        
        // Auto-fill jika ada data tersimpan
        if (userData['nama_bank'] != null) {
          _selectedBank = userData['nama_bank'];
        }
        if (userData['nama_rekening'] != null) {
          _accountNameController.text = userData['nama_rekening'];
        }
        if (userData['nomor_rekening'] != null) {
          _accountNumberController.text = userData['nomor_rekening'];
        }
      });

    } catch (e) {
      print('❌ Error load data: $e');
      _showSnackBar('Gagal memuat data', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      _showSnackBar('Pilih bank terlebih dahulu', Colors.orange);
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penarikan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah: ${CurrencyFormatter.format(double.parse(_amountController.text))}'),
            const SizedBox(height: 8),
            Text('Bank: $_selectedBank'),
            Text('Rekening: ${_accountNumberController.text}'),
            Text('Atas Nama: ${_accountNameController.text}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text('Catatan Penting:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Saldo akan dipotong terlebih dahulu\n'
                    '• Proses transfer 1-3 hari kerja\n'
                    '• Pastikan data rekening benar',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ],
              ),
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
              backgroundColor: const Color(0xFF00880F),
            ),
            child: const Text('Ya, Proses'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showSnackBar('User tidak ditemukan', Colors.red);
        return;
      }

      final amount = double.parse(_amountController.text);

      final result = await _walletService.requestWithdrawal(
        userId: userId,
        amount: amount,
        bankName: _selectedBank!,
        accountName: _accountNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog(result);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal mengajukan penarikan', Colors.red);
      }

    } catch (e) {
      print('❌ Error process withdrawal: $e');
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
            ),
            const SizedBox(width: 12),
            const Text('Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengajuan penarikan berhasil diproses!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('ID Penarikan', result['withdrawal_id']?.toString().substring(0, 8) ?? '-'),
                  const Divider(),
                  _buildInfoRow('Saldo Lama', CurrencyFormatter.format(result['old_balance'] ?? 0)),
                  _buildInfoRow('Saldo Baru', CurrencyFormatter.format(result['new_balance'] ?? 0)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dana akan ditransfer dalam 1-3 hari kerja.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00880F),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarik Saldo'),
        elevation: 0,
        backgroundColor: const Color(0xFF00880F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    ResponsiveMobile.vSpace(24),
                    _buildAmountSection(),
                    ResponsiveMobile.vSpace(24),
                    _buildBankSection(),
                    ResponsiveMobile.vSpace(24),
                    _buildAccountSection(),
                    ResponsiveMobile.vSpace(32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final canWithdraw = _dailyWithdrawalCount < 3;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00880F), Color(0xFF00AA13)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00880F).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withOpacity(0.9),
                size: ResponsiveMobile.scaledW(20),
              ),
              ResponsiveMobile.hSpace(8),
              Text(
                'Saldo Tersedia',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: ResponsiveMobile.scaledSP(14),
                ),
              ),
            ],
          ),
          ResponsiveMobile.vSpace(8),
          Text(
            CurrencyFormatter.format(_currentBalance),
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveMobile.scaledSP(32),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveMobile.vSpace(12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveMobile.scaledW(12),
              vertical: ResponsiveMobile.scaledH(6),
            ),
            decoration: BoxDecoration(
              color: canWithdraw
                  ? Colors.white.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  canWithdraw ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  canWithdraw
                      ? 'Penarikan hari ini: $_dailyWithdrawalCount/3'
                      : 'Limit penarikan harian tercapai',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah Penarikan',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledSP(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        ResponsiveMobile.vSpace(12),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: 'Rp ',
            hintText: '50.000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Masukkan jumlah';
            final amount = double.tryParse(value);
            if (amount == null) return 'Jumlah tidak valid';
            if (amount < 50000) return 'Minimal Rp 50.000';
            if (amount > 5000000) return 'Maksimal Rp 5.000.000';
            if (amount > _currentBalance) return 'Saldo tidak cukup';
            return null;
          },
        ),
        ResponsiveMobile.vSpace(12),
        // Quick amount buttons
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: ResponsiveMobile.scaledW(10),
            mainAxisSpacing: ResponsiveMobile.scaledH(10),
            childAspectRatio: 2.5,
          ),
          itemCount: _quickAmounts.length,
          itemBuilder: (context, index) {
            final amount = _quickAmounts[index];
            return GestureDetector(
              onTap: () {
                if (amount <= _currentBalance) {
                  _amountController.text = amount.toString();
                  _formKey.currentState?.validate();
                } else {
                  _showSnackBar('Saldo tidak cukup', Colors.orange);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
                  color: amount <= _currentBalance ? Colors.white : Colors.grey.shade100,
                ),
                child: Center(
                  child: Text(
                    CurrencyFormatter.formatCompact(amount.toDouble()),
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(13),
                      fontWeight: FontWeight.w600,
                      color: amount <= _currentBalance ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBankSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Bank',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledSP(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        ResponsiveMobile.vSpace(12),
        Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance, color: Colors.grey.shade600),
              ResponsiveMobile.hSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Bank',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedBank ?? 'Belum diatur',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Rekening',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledSP(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        ResponsiveMobile.vSpace(12),
        // Nomor Rekening
        Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.grey.shade600),
              ResponsiveMobile.hSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Rekening',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _accountNumberController.text.isEmpty 
                          ? 'Belum diatur' 
                          : _accountNumberController.text,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ResponsiveMobile.vSpace(12),
        // Nama Pemilik Rekening
        Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.grey.shade600),
              ResponsiveMobile.hSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Pemilik Rekening',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _accountNameController.text.isEmpty 
                          ? 'Belum diatur' 
                          : _accountNameController.text,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledSP(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canWithdraw = _dailyWithdrawalCount < 3;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !canWithdraw) ? null : _processWithdrawal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00880F),
          padding: EdgeInsets.symmetric(vertical: ResponsiveMobile.scaledH(16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ajukan Penarikan',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledSP(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}