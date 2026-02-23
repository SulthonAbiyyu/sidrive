// lib/pages/umkm/pendapatan_umkm_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/pendapatan_umkm_service.dart';
import 'package:sidrive/services/umkm_service.dart';
import 'package:sidrive/models/pendapatan_umkm_model.dart';
import 'package:sidrive/core/widgets/pendapatan_umkm_card_widget.dart';
import 'package:sidrive/core/widgets/periode_selector_widget.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';

class PendapatanUmkmPage extends StatefulWidget {
  const PendapatanUmkmPage({Key? key}) : super(key: key);

  @override
  State<PendapatanUmkmPage> createState() => _PendapatanUmkmPageState();
}

class _PendapatanUmkmPageState extends State<PendapatanUmkmPage> {
  final _pendapatanService = PendapatanUmkmService();
  final _umkmService = UmkmService();
  
  String _selectedPeriode = 'hari';
  bool _isLoading = true;
  String? _umkmId;
  
  PendapatanUmkmModel _dataPendapatan = PendapatanUmkmModel.empty();

  @override
  void initState() {
    super.initState();
    _loadUmkmAndPendapatan();
  }

  Future<void> _loadUmkmAndPendapatan() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.idUser;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Get UMKM ID dari user
      final umkm = await _umkmService.getUmkmByUserId(userId);
      
      if (umkm == null) {
        throw Exception('UMKM tidak ditemukan');
      }

      _umkmId = umkm.idUmkm;

      // 2. Load pendapatan
      await _loadPendapatan();

    } catch (e) {
      print('❌ Error load UMKM: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Gagal memuat data UMKM. $e',
        );
      }
    }
  }

  Future<void> _loadPendapatan() async {
    if (_umkmId == null) return;

    setState(() => _isLoading = true);

    try {
      PendapatanUmkmModel result;

      if (_selectedPeriode == 'hari') {
        result = await _pendapatanService.getPendapatanHariIni(_umkmId!);
      } else if (_selectedPeriode == 'minggu') {
        result = await _pendapatanService.getPendapatanMingguIni(_umkmId!);
      } else {
        result = await _pendapatanService.getPendapatanBulanIni(_umkmId!);
      }

      if (mounted) {
        setState(() {
          _dataPendapatan = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error load pendapatan: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ErrorDialogUtils.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Gagal memuat data pendapatan. Coba lagi nanti.',
        );
      }
    }
  }

  void _onPeriodeChanged(String newPeriode) {
    setState(() => _selectedPeriode = newPeriode);
    _loadPendapatan();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.nama ?? 'Pemilik Toko';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadPendapatan,
                color: Color(0xFFF59E0B),
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(userName),
                        SizedBox(height: ResponsiveMobile.scaledH(14)),
                        PendapatanUmkmCardWidget(
                          totalPenjualan: _dataPendapatan.totalPenjualan,
                          totalPendapatan: _dataPendapatan.totalPendapatan,
                          totalPesanan: _dataPendapatan.totalPesanan,
                          totalProdukTerjual: _dataPendapatan.totalProdukTerjual,
                          periode: _getPeriodeLabel(),
                        ),
                        SizedBox(height: ResponsiveMobile.scaledH(12)),
                        PeriodeSelectorWidget(
                          selectedPeriode: _selectedPeriode,
                          onPeriodeChanged: _onPeriodeChanged,
                        ),
                        SizedBox(height: ResponsiveMobile.scaledH(16)),
                        _buildBreakdownSection(),
                        SizedBox(height: ResponsiveMobile.scaledH(16)),
                        _buildInfoSection(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendapatan UMKM',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(22),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveMobile.scaledH(3)),
        Text(
          'Halo, $userName! 👋',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(12),
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Pendapatan',
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(13),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveMobile.scaledH(10)),
          
          _buildBreakdownItem(
            icon: Icons.shopping_cart,
            label: 'Total Penjualan Produk',
            value: 'Rp ${_formatCurrency(_dataPendapatan.totalPenjualan)}',
            color: Color(0xFF66BB6A),
          ),
          
          Divider(height: ResponsiveMobile.scaledH(18), color: Colors.grey.shade200),
          
          _buildBreakdownItem(
            icon: Icons.local_shipping,
            label: 'Total Ongkir',
            value: 'Rp ${_formatCurrency(_dataPendapatan.totalOngkir)}',
            color: Color(0xFF42A5F5),
            subtitle: 'Dibayar customer untuk delivery',
          ),
          
          Divider(height: ResponsiveMobile.scaledH(18), color: Colors.grey.shade200),
          
          _buildBreakdownItem(
            icon: Icons.info_outline,
            label: 'Potongan Platform (10%)',
            value: '- Rp ${_formatCurrency(_dataPendapatan.totalFeeAdmin)}',
            color: Color(0xFFEF5350),
            isInfo: true,
          ),
          
          Divider(height: ResponsiveMobile.scaledH(18), color: Colors.grey.shade200),
          
          _buildBreakdownItem(
            icon: Icons.account_balance_wallet,
            label: 'Pendapatan Bersih Anda',
            value: 'Rp ${_formatCurrency(_dataPendapatan.totalPendapatan)}',
            color: Color(0xFFF59E0B),
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
    bool isInfo = false,
    bool isHighlight = false,
  }) {
    return Container(
      padding: isHighlight ? EdgeInsets.all(ResponsiveMobile.scaledW(8)) : null,
      decoration: isHighlight
          ? BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(8)),
            )
          : null,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveMobile.scaledW(7)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(7)),
            ),
            child: Icon(icon, color: color, size: ResponsiveMobile.scaledFont(16)),
          ),
          SizedBox(width: ResponsiveMobile.scaledW(9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(11),
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(8),
                      color: Colors.grey.shade500,
                    ),
                  ),
                if (isInfo)
                  Text(
                    'Sudah dipotong otomatis',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(8),
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(isHighlight ? 14 : 12),
              fontWeight: FontWeight.bold,
              color: value.startsWith('-') ? Color(0xFFEF5350) : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveMobile.scaledW(12)),
      decoration: BoxDecoration(
        color: Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
        border: Border.all(
          color: Color(0xFFF59E0B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFFF59E0B),
            size: ResponsiveMobile.scaledFont(16),
          ),
          SizedBox(width: ResponsiveMobile.scaledW(8)),
          Expanded(
            child: Text(
              'Pendapatan yang ditampilkan adalah 90% dari total penjualan (setelah potongan platform 10%). Ongkir delivery ditanggung customer, bukan dari potongan Anda.',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(10),
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodeLabel() {
    switch (_selectedPeriode) {
      case 'hari':
        return 'Hari Ini';
      case 'minggu':
        return 'Minggu Ini';
      case 'bulan':
        return 'Bulan Ini';
      default:
        return 'Hari Ini';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}