import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/pendapatan_service.dart';
import 'package:sidrive/core/widgets/pendapatan_card_widget.dart';
import 'package:sidrive/core/widgets/periode_selector_widget.dart';
import 'dart:math'; 


class PendapatanPage extends StatefulWidget {
  final String driverId;

  const PendapatanPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<PendapatanPage> createState() => _PendapatanPageState();
}

class _PendapatanPageState extends State<PendapatanPage> {
  final _pendapatanService = PendapatanService();
  
  String _selectedPeriode = 'hari';
  bool _isLoading = true;
  
  // Data State
  Map<String, dynamic> _dataPendapatan = {
    'total_pendapatan': 0.0,
    'total_pesanan': 0,
    'total_jarak': 0.0,
    'total_fee_admin': 0.0,
  };

  Map<String, dynamic> _settlementInfo = {
    'cash_pending': 0.0,
    'order_count': 0,
    'can_withdraw': true,
    'settlements': [],
  };

  @override
  void initState() {
    super.initState();
    _loadPendapatan();
    _loadSettlementInfo();
  }

  Future<void> _loadPendapatan() async {
    if (widget.driverId.isEmpty) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }

    if(mounted) setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_selectedPeriode == 'hari') {
        result = await _pendapatanService.getPendapatanHariIni(widget.driverId);
      } else if (_selectedPeriode == 'minggu') {
        result = await _pendapatanService.getPendapatanMingguIni(widget.driverId);
      } else {
        result = await _pendapatanService.getPendapatanBulanIni(widget.driverId);
      }

      if (mounted) {
        setState(() {
          _dataPendapatan = result;
          _isLoading = false;
        });
        _loadSettlementInfo();
      }
    } catch (e) {
      print('❌ Error load pendapatan: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSettlementInfo() async {
    if (widget.driverId.isEmpty) return;
    try {
      final settlementInfo = await _pendapatanService.getDriverSettlementInfo(widget.driverId);
      if (mounted) setState(() => _settlementInfo = settlementInfo);
    } catch (e) {
      print('❌ Error load settlement: $e');
    }
  }

  void _onPeriodeChanged(String newPeriode) {
    setState(() => _selectedPeriode = newPeriode);
    _loadPendapatan();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.nama ?? 'Driver';

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : Stack(
            children: [
              // 1. BACKGROUND (Static Full Screen)
              // Ensure consistent background even if content doesn't fill
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)], 
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 2. LAYOUT (Column: Fixed Header + Expanded Body)
              Column(
                children: [
                   // --- STATIC FIXED HEADER ---
                   SafeArea(
                     bottom: false,
                     child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Hug content
                          children: [
                             // Header Title
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text('Selamat Sore,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                     Text(userName, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                   ],
                                 ),
                                 Container(
                                   padding: EdgeInsets.all(8),
                                   decoration: BoxDecoration(
                                     color: Colors.white.withOpacity(0.2),
                                     shape: BoxShape.circle
                                   ),
                                   child: Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                                 )
                               ],
                             ),
                             
                             SizedBox(height: 24),
                             
                             // HERO CARD (Static)
                             PendapatanCardWidget(
                               totalPendapatan: _dataPendapatan['total_pendapatan'],
                               totalPesanan: _dataPendapatan['total_pesanan'],
                               totalJarak: _dataPendapatan['total_jarak'],
                               periode: _getPeriodeLabel(),
                             ),

                             SizedBox(height: 20),

                             // WEEKLY CHART (Static)
                             _buildMockActivityChart(),
                             
                             SizedBox(height: 20),
                          ],
                        ),
                     ),
                   ),

                   // --- SCROLLABLE BODY ---
                   Expanded(
                     child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))]
                        ),
                        // Refresh Indicator ONLY wraps this part
                        // So the Header (Green part) stays absolutely still!
                        child: RefreshIndicator(
                          onRefresh: _loadPendapatan,
                          color: const Color(0xFF10B981),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Drag Handle (Visual)
                                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                                SizedBox(height: 24),
                                
                                // Filter (Centered)
                                Center(
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: 340),
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16)
                                    ),
                                    child: PeriodeSelectorWidget(
                                      selectedPeriode: _selectedPeriode,
                                      onPeriodeChanged: _onPeriodeChanged,
                                      activeColor: Colors.white,
                                      activeTextColor: Colors.black87,
                                      inactiveColor: Colors.transparent,
                                      inactiveTextColor: Colors.grey,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 30),
                                
                                Text('Rincian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 16),
                                _buildDetailedList(),

                                 if (_settlementInfo['cash_pending'] > 0 || _settlementInfo['order_count'] > 0)
                                    Padding(padding: EdgeInsets.only(top: 20), child: _buildSettlementAlert()),
                                
                                SizedBox(height: 50), // Bottom Padding
                              ],
                            ),
                          ),
                        ),
                     ),
                   ),
                ],
              )
            ],
          ),
    );
  }

  // --- VISUAL WIDGETS --- //
  
  Widget _buildMockActivityChart() {
    final days = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];
    final random = Random();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas Mingguan', style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
             final height = 20.0 + random.nextInt(40); 
             final isToday = index == 4;
             
             return Column(
               children: [
                 Container(
                   width: 8,
                   height: height,
                   decoration: BoxDecoration(
                     color: isToday ? Colors.white : Colors.white.withOpacity(0.3),
                     borderRadius: BorderRadius.circular(4)
                   ),
                 ),
                 SizedBox(height: 8),
                 Text(days[index], style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10))
               ],
             );
          }),
        )
      ],
    );
  }

  Widget _buildDetailedList() {
    return Column(
      children: [
        _buildDetailRow(Icons.payments_rounded, 'Tarif Perjalanan', 'Rp ${_formatCurrency(_dataPendapatan['total_pendapatan'])}', Colors.green),
        Divider(height: 24),
        _buildDetailRow(Icons.star_rounded, 'Bonus & Insentif', 'Rp 0', Colors.orange),
        Divider(height: 24),
        _buildDetailRow(Icons.local_offer, 'Promosi', 'Rp 0', Colors.purple),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
         Container(
           padding: EdgeInsets.all(8),
           decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
           child: Icon(icon, size: 18, color: color),
         ),
         SizedBox(width: 16),
         Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600))),
         Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSettlementAlert() {
     final canWithdraw = _settlementInfo['can_withdraw'] as bool;
     return Container(
       padding: EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: canWithdraw ? Colors.green[50] : Colors.red[50], 
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: canWithdraw ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
       ),
       child: Row(
         children: [
            Icon(canWithdraw ? Icons.check_circle : Icons.warning_amber_rounded, color: canWithdraw ? Colors.green : Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Status Settlement', style: TextStyle(fontWeight: FontWeight.bold, color: canWithdraw ? Colors.green[800] : Colors.red[800])),
                   Text(canWithdraw ? 'Aman' : 'Perlu Setor Cash!', style: TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey)
         ],
       ),
     );
  }

  String _getPeriodeLabel() {
    switch (_selectedPeriode) {
      case 'hari': return 'Hari Ini';
      case 'minggu': return 'Minggu Ini';
      case 'bulan': return 'Bulan Ini';
      default: return 'Hari Ini';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}