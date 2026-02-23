// ============================================================================
// KELOLA TARIF CONTENT
// Halaman admin untuk mengatur tarif ojek, ongkir UMKM, dan fee platform.
// Terintegrasi langsung dengan AdminProvider — tidak butuh provider terpisah.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sidrive/providers/admin_provider.dart';

class KelolaTarifContent extends StatefulWidget {
  const KelolaTarifContent({super.key});

  @override
  State<KelolaTarifContent> createState() => _KelolaTarifContentState();
}

class _KelolaTarifContentState extends State<KelolaTarifContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _pendingChanges = {};

  static const _tabs = [
    _TabDef('Tarif Ojek', Icons.two_wheeler_outlined, 'tarif_ojek'),
    _TabDef('Tarif UMKM', Icons.store_outlined, 'tarif_umkm'),
    _TabDef('Fee Platform', Icons.percent_outlined, 'fee_platform'),
  ];

  bool get _hasChanges => _pendingChanges.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      if (provider.tarifConfigs.isEmpty) {
        provider.loadTarifConfigs();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<Map<String, dynamic>> configs) {
    for (final item in configs) {
      final key = item['config_key'] as String;
      if (!_controllers.containsKey(key)) {
        _controllers[key] = TextEditingController(
          text: item['config_value']?.toString() ?? '0',
        );
      }
    }
  }

  void _onFieldChanged(String key, String value) {
    setState(() => _pendingChanges[key] = value);
  }

  Future<void> _saveAll() async {
    // Validasi semua angka
    for (final entry in _pendingChanges.entries) {
      final val = double.tryParse(entry.value);
      if (val == null || val < 0) {
        _snackbar('Nilai tidak valid — harus angka positif.', isError: true);
        return;
      }
    }

    // Validasi fee ojek + driver earning = 100
    final adminFee = double.tryParse(
          _pendingChanges['ojek_admin_fee_percent'] ??
              _existingVal('ojek_admin_fee_percent'),
        ) ??
        0;
    final driverEarning = double.tryParse(
          _pendingChanges['driver_earning_percent'] ??
              _existingVal('driver_earning_percent'),
        ) ??
        0;

    if (adminFee + driverEarning != 100) {
      _snackbar(
        'Fee Admin Ojek + Pendapatan Driver harus = 100%.\nSaat ini = ${(adminFee + driverEarning).toInt()}%',
        isError: true,
      );
      return;
    }

    final provider = context.read<AdminProvider>();
    final success = await provider.saveTarifConfigs(Map.from(_pendingChanges));

    if (success) {
      setState(() => _pendingChanges.clear());
      _snackbar('Konfigurasi tarif berhasil disimpan ✓');
    } else {
      _snackbar(provider.tarifErrorMessage ?? 'Gagal menyimpan', isError: true);
    }
  }

  void _discardChanges(List<Map<String, dynamic>> configs) {
    setState(() {
      for (final item in configs) {
        final key = item['config_key'] as String;
        if (_pendingChanges.containsKey(key)) {
          _controllers[key]?.text = item['config_value']?.toString() ?? '0';
        }
      }
      _pendingChanges.clear();
    });
  }

  String _existingVal(String key) {
    final configs = context.read<AdminProvider>().tarifConfigs;
    final item = configs.firstWhere(
      (e) => e['config_key'] == key,
      orElse: () => {'config_value': '0'},
    );
    return item['config_value']?.toString() ?? '0';
  }

  void _snackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: Colors.white,
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (context, provider, _) {
      if (provider.isLoadingTarif && provider.tarifConfigs.isEmpty) {
        return _buildLoading();
      }
      if (provider.tarifErrorMessage != null && provider.tarifConfigs.isEmpty) {
        return _buildError(provider);
      }

      _syncControllers(provider.tarifConfigs);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(provider),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final items = provider.getTarifByCategory(tab.category);
                return _buildTabView(tab, items, provider);
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader(AdminProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Tarif',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Tarif ojek, ongkir UMKM, dan fee platform',
                  style:
                      TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (_hasChanges) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_pendingChanges.length} diubah',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _discardChanges(provider.tarifConfigs),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
              ),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton.icon(
            onPressed:
                _hasChanges && !provider.isSavingTarif ? _saveAll : null,
            icon: provider.isSavingTarif
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 15),
            label: Text(
                provider.isSavingTarif ? 'Menyimpan...' : 'Simpan'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB BAR
  // ============================================================================
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicator: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.all(3),
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: _tabs
              .map((tab) => Tab(
                    height: 34,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tab.icon, size: 13),
                        const SizedBox(width: 5),
                        Text(tab.label),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ============================================================================
  // TAB VIEW
  // ============================================================================
  Widget _buildTabView(
    _TabDef tab,
    List<Map<String, dynamic>> items,
    AdminProvider provider,
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada konfigurasi',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tab.category == 'fee_platform')
            _buildFeeDistributionCard(provider)
          else
            _buildSimulasiCard(tab.category, provider),
          const SizedBox(height: 16),
          _buildConfigCard(items),
          const SizedBox(height: 16),
          _buildLastUpdatedInfo(items),
        ],
      ),
    );
  }

  // ============================================================================
  // KARTU SIMULASI TARIF
  // ============================================================================
  Widget _buildSimulasiCard(String category, AdminProvider provider) {
    final isOjek = category == 'tarif_ojek';
    final prefix = isOjek ? 'ojek' : 'umkm';

    double val(String suffix) {
      final key = '${prefix}_$suffix';
      final pending = _pendingChanges[key];
      if (pending != null) return double.tryParse(pending) ?? 0;
      return provider.getTarifValue(key);
    }

    const simKm = 5.0;
    final motorTotal = val('motor_base_fare') + simKm * val('motor_per_km');
    final mobilTotal = val('mobil_base_fare') + simKm * val('mobil_per_km');

    final adminFeeKey =
        isOjek ? 'ojek_admin_fee_percent' : 'umkm_admin_fee_percent';
    final adminFee = double.tryParse(
            _pendingChanges[adminFeeKey] ?? _existingVal(adminFeeKey)) ??
        0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calculate_outlined, color: Colors.white60, size: 13),
            const SizedBox(width: 6),
            const Text(
              'Simulasi biaya untuk 5 km (real-time)',
              style: TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _simBox(Icons.two_wheeler, 'Motor', _formatRp(motorTotal))),
            const SizedBox(width: 10),
            Expanded(
                child: _simBox(Icons.directions_car_outlined, 'Mobil',
                    _formatRp(mobilTotal))),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              isOjek
                  ? 'Base Fare + (Jarak × Tarif/km) → Admin ${adminFee.toInt()}%'
                  : 'Base Fare + (Jarak × Tarif/km) → Fee UMKM ${adminFee.toInt()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white60, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ============================================================================
  // KARTU FEE DISTRIBUTION
  // ============================================================================
  Widget _buildFeeDistributionCard(AdminProvider provider) {
    double val(String key) {
      final pending = _pendingChanges[key];
      if (pending != null) return double.tryParse(pending) ?? 0;
      return provider.getTarifValue(key);
    }

    final adminOjek = val('ojek_admin_fee_percent');
    final driverEarning = val('driver_earning_percent');
    final adminUmkm = val('umkm_admin_fee_percent');
    final gwFee = val('payment_gateway_fee');
    final ojekTotal = adminOjek + driverEarning;
    final isValid = ojekTotal == 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isValid
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: Colors.white70,
              size: 13,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isValid
                    ? 'Distribusi fee ojek valid — total ${ojekTotal.toInt()}%'
                    : 'Peringatan: Fee Admin + Driver = ${ojekTotal.toInt()}% (harus 100%)',
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Bar distribusi ojek
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Distribusi ongkir ojek:',
                style: TextStyle(color: Colors.white70, fontSize: 10.5)),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Flexible(
                    flex: adminOjek.toInt().clamp(1, 99),
                    child: Container(
                        height: 10, color: Colors.white.withOpacity(0.9)),
                  ),
                  Flexible(
                    flex: driverEarning.toInt().clamp(1, 99),
                    child: Container(
                        height: 10, color: Colors.white.withOpacity(0.35)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(children: [
              _dot(Colors.white.withOpacity(0.9)),
              const SizedBox(width: 4),
              Text('Admin ${adminOjek.toInt()}%',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10.5)),
              const SizedBox(width: 12),
              _dot(Colors.white.withOpacity(0.35)),
              const SizedBox(width: 4),
              Text('Driver ${driverEarning.toInt()}%',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10.5)),
            ]),
          ]),

          const SizedBox(height: 10),
          Row(children: [
            _feeChip('Admin UMKM', '${adminUmkm.toInt()}%'),
            const SizedBox(width: 8),
            _feeChip('Payment GW', '${gwFee.toInt()}%'),
          ]),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _feeChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(width: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ============================================================================
  // KARTU INPUT CONFIG
  // ============================================================================
  Widget _buildConfigCard(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return _buildConfigRow(entry.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildConfigRow(Map<String, dynamic> item,
      {required bool isLast}) {
    final key = item['config_key'] as String;
    final controller = _controllers[key];
    if (controller == null) return const SizedBox.shrink();

    final isChanged = _pendingChanges.containsKey(key);
    final isPercent = item['config_type'] == 'percentage';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Label + description
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        item['label'] ?? key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (isChanged) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DIUBAH',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ]),
                    if (item['description'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item['description'],
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Input field
              SizedBox(
                width: 118,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  onChanged: (v) => _onFieldChanged(key, v),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isChanged
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    filled: true,
                    fillColor: isChanged
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF9FAFB),
                    suffix: Text(
                      isPercent ? '%' : 'Rp',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                        color: isChanged
                            ? const Color(0xFFC4B5FD)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                        color: isChanged
                            ? const Color(0xFFC4B5FD)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(
                          color: Color(0xFF6366F1), width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              color: Color(0xFFF3F4F6),
              indent: 16,
              endIndent: 16),
      ],
    );
  }

  // ============================================================================
  // LAST UPDATED INFO
  // ============================================================================
  Widget _buildLastUpdatedInfo(List<Map<String, dynamic>> items) {
    Map<String, dynamic>? latestItem;
    DateTime? latestDate;

    for (final item in items) {
      if (item['updated_at'] != null) {
        try {
          final dt = DateTime.parse(item['updated_at'].toString());
          if (latestDate == null || dt.isAfter(latestDate)) {
            latestDate = dt;
            latestItem = item;
          }
        } catch (_) {}
      }
    }

    if (latestDate == null) return const SizedBox.shrink();

    final updatedBy = latestItem?['updated_by_name'] ?? 'Admin';
    final formatted =
        DateFormat('dd MMM yyyy, HH:mm').format(latestDate.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(children: [
        const Icon(Icons.history_rounded, size: 14, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 7),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
              children: [
                const TextSpan(text: 'Terakhir diubah: '),
                TextSpan(
                  text: formatted,
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' oleh $updatedBy'),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.read<AdminProvider>().loadTarifConfigs(),
          child: const Icon(Icons.refresh_rounded,
              size: 14, color: Color(0xFF9CA3AF)),
        ),
      ]),
    );
  }

  // ============================================================================
  // LOADING & ERROR
  // ============================================================================
  Widget _buildLoading() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF6366F1)),
        ),
        SizedBox(height: 12),
        Text('Memuat konfigurasi tarif...',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      ]),
    );
  }

  Widget _buildError(AdminProvider provider) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 26),
        ),
        const SizedBox(height: 12),
        const Text('Gagal memuat konfigurasi tarif',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827))),
        const SizedBox(height: 4),
        Text(
          provider.tarifErrorMessage ?? '',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => provider.loadTarifConfigs(),
          icon: const Icon(Icons.refresh_rounded, size: 15),
          label: const Text('Coba Lagi'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9)),
          ),
        ),
      ]),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================
  String _formatRp(double value) {
    final rounded = (value / 500).round() * 500;
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(rounded)}';
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final String category;
  const _TabDef(this.label, this.icon, this.category);
}