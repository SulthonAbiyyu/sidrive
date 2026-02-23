import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/models/saved_bank_account_model.dart';

/// MODERN & CLEAN WITHDRAW DIALOG
/// Features:
/// - Pilih rekening tersimpan (1 klik)
/// - Tambah rekening baru
/// - Simpan rekening untuk nanti
/// - Set default account
class WithdrawDialog extends StatefulWidget {
  final double availableBalance;
  final List<SavedBankAccount> savedAccounts;
  final Function(double amount, String bankCode, String bankName, String accountNumber, String accountHolderName, String notes, bool saveAccount, bool setAsDefault) onSubmit;

  const WithdrawDialog({
    super.key,
    required this.availableBalance,
    required this.savedAccounts,
    required this.onSubmit,
  });

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  SavedBankAccount? _selectedSavedAccount;
  String? _selectedBankCode;
  String? _selectedBankName;
  bool _isSubmitting = false;
  bool _saveAccount = false;
  bool _setAsDefault = false;

  static const double _minAmount = 100000;

  final List<Map<String, String>> _banks = [
    {'code': 'bca', 'name': 'BCA'},
    {'code': 'mandiri', 'name': 'Mandiri'},
    {'code': 'bni', 'name': 'BNI'},
    {'code': 'bri', 'name': 'BRI'},
    {'code': 'permata', 'name': 'Permata'},
    {'code': 'cimb', 'name': 'CIMB Niaga'},
    {'code': 'danamon', 'name': 'Danamon'},
    {'code': 'btn', 'name': 'BTN'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.savedAccounts.isEmpty ? 1 : 2,
      vsync: this,
    );
    
    // Set default account jika ada
    if (widget.savedAccounts.isNotEmpty) {
      final defaultAccount = widget.savedAccounts.firstWhere(
        (acc) => acc.isDefault,
        orElse: () => widget.savedAccounts.first,
      );
      _selectedSavedAccount = defaultAccount;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine which data to use
    final bankCode = _tabController.index == 0 && _selectedSavedAccount != null
        ? _selectedSavedAccount!.bankCode
        : _selectedBankCode;

    final bankName = _tabController.index == 0 && _selectedSavedAccount != null
        ? _selectedSavedAccount!.bankName
        : _selectedBankName;

    final accountNumber = _tabController.index == 0 && _selectedSavedAccount != null
        ? _selectedSavedAccount!.accountNumber
        : _accountNumberController.text.trim();

    final accountHolder = _tabController.index == 0 && _selectedSavedAccount != null
        ? _selectedSavedAccount!.accountHolderName
        : _accountHolderController.text.trim();

    if (bankCode == null || bankName == null) {
      _showError('Pilih bank terlebih dahulu');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));

      await widget.onSubmit(
        amount,
        bankCode,
        bankName,
        accountNumber,
        accountHolder,
        _notesController.text.trim(),
        _saveAccount && _tabController.index == 1, // Only save if new account
        _setAsDefault && _tabController.index == 1,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Gagal memproses penarikan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            if (widget.savedAccounts.isNotEmpty) _buildTabs(),
            Expanded(
              child: widget.savedAccounts.isEmpty
                  ? _buildNewAccountForm()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSavedAccountsTab(),
                        _buildNewAccountForm(),
                      ],
                    ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarik Saldo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Transfer ke rekening bank',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            color: const Color(0xFF9CA3AF),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Tersedia',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 2),
            ],
          ),
          Text(
            CurrencyFormatter.format(widget.availableBalance),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(3),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Rekening Tersimpan'),
          Tab(text: 'Rekening Baru'),
        ],
      ),
    );
  }

  Widget _buildSavedAccountsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            _buildLabel('Jumlah Penarikan'),
            const SizedBox(height: 6),
            _buildAmountField(),
            
            const SizedBox(height: 16),
            
            // Saved accounts list
            _buildLabel('Pilih Rekening'),
            const SizedBox(height: 8),
            ...widget.savedAccounts.map((account) => _buildAccountCard(account)),
            
            const SizedBox(height: 16),
            
            // Notes (optional)
            _buildLabel('Catatan (Opsional)'),
            const SizedBox(height: 6),
            _buildNotesField(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAccountForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            _buildLabel('Jumlah Penarikan'),
            const SizedBox(height: 6),
            _buildAmountField(),
            
            const SizedBox(height: 14),
            
            // Bank
            _buildLabel('Bank Tujuan'),
            const SizedBox(height: 6),
            _buildBankDropdown(),
            
            const SizedBox(height: 14),
            
            // Account number
            _buildLabel('Nomor Rekening'),
            const SizedBox(height: 6),
            _buildAccountNumberField(),
            
            const SizedBox(height: 14),
            
            // Account holder
            _buildLabel('Nama Pemegang Rekening'),
            const SizedBox(height: 6),
            _buildAccountHolderField(),
            
            const SizedBox(height: 14),
            
            // Notes
            _buildLabel('Catatan (Opsional)'),
            const SizedBox(height: 6),
            _buildNotesField(),
            
            const SizedBox(height: 14),
            
            // Save options
            _buildSaveOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        height: 1.2,
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CurrencyInputFormatter(),
      ],
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827), // ✅ Text color hitam agar terlihat
      ),
      decoration: InputDecoration(
        hintText: '100.000',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        filled: true,
        fillColor: Colors.white, // ✅ Background putih agar text terlihat jelas
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Masukkan jumlah';
        final amount = double.tryParse(value.replaceAll('.', ''));
        if (amount == null) return 'Jumlah tidak valid';
        if (amount < _minAmount) return 'Min ${CurrencyFormatter.format(_minAmount)}';
        if (amount > widget.availableBalance) return 'Saldo tidak cukup';
        return null;
      },
    );
  }

  Widget _buildAccountCard(SavedBankAccount account) {
    final isSelected = _selectedSavedAccount?.id == account.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedSavedAccount = account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.bankName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      if (account.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${account.maskedAccountNumber} • ${account.accountHolderName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: Color(0xFF6366F1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBankCode,
      dropdownColor: Colors.white, // ✅ Background dropdown putih, bukan hitam!
      decoration: InputDecoration(
        hintText: 'Pilih bank',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      items: _banks.map((bank) {
        return DropdownMenuItem<String>(
          value: bank['code'],
          child: Text(
            bank['name']!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827), // ✅ Text item hitam
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBankCode = value;
          _selectedBankName = _banks.firstWhere((b) => b['code'] == value)['name'];
        });
      },
      validator: (value) => value == null ? 'Pilih bank' : null,
    );
  }

  Widget _buildAccountNumberField() {
    return TextFormField(
      controller: _accountNumberController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827), // ✅ Text color hitam
      ),
      decoration: InputDecoration(
        hintText: '1234567890',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
        filled: true,
        fillColor: Colors.white, // ✅ Background putih
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Masukkan nomor rekening';
        if (value.length < 8) return 'Min 8 digit';
        return null;
      },
    );
  }

  Widget _buildAccountHolderField() {
    return TextFormField(
      controller: _accountHolderController,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827), // ✅ Text color hitam
      ),
      decoration: InputDecoration(
        hintText: 'NAMA PEMEGANG REKENING',
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFD1D5DB)),
        filled: true,
        fillColor: Colors.white, // ✅ Background putih
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Masukkan nama pemegang';
        if (value.length < 3) return 'Min 3 karakter';
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF111827), // ✅ Text color hitam
      ),
      decoration: InputDecoration(
        hintText: 'Catatan untuk penarikan ini...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
        filled: true,
        fillColor: Colors.white, // ✅ Background putih
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  Widget _buildSaveOptions() {
    return Column(
      children: [
        // Checkbox: Save account
        InkWell(
          onTap: () => setState(() => _saveAccount = !_saveAccount),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _saveAccount ? const Color(0xFFF0F4FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _saveAccount ? const Color(0xFF6366F1) : Colors.white,
                    border: Border.all(
                      color: _saveAccount ? const Color(0xFF6366F1) : const Color(0xFFD1D5DB),
                      width: _saveAccount ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _saveAccount
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Simpan rekening ini untuk penarikan berikutnya',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Checkbox: Set as default (only if save is checked)
        if (_saveAccount) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _setAsDefault = !_setAsDefault),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _setAsDefault ? const Color(0xFFF0F4FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _setAsDefault ? const Color(0xFF6366F1) : Colors.white,
                      border: Border.all(
                        color: _setAsDefault ? const Color(0xFF6366F1) : const Color(0xFFD1D5DB),
                        width: _setAsDefault ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _setAsDefault
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Jadikan rekening utama (default)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                foregroundColor: const Color(0xFF6B7280),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Proses Penarikan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CURRENCY INPUT FORMATTER
// ============================================================================

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '';
    final reversed = number.split('').reversed.join();
    final chunks = <String>[];
    for (var i = 0; i < reversed.length; i += 3) {
      final end = i + 3;
      chunks.add(reversed.substring(i, end > reversed.length ? reversed.length : end));
    }
    return chunks.join('.').split('').reversed.join();
  }
}