import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/core/utils/currency_formatter.dart';
import 'package:sidrive/core/widgets/wallet_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CashSettlementPage extends StatefulWidget {
  const CashSettlementPage({Key? key}) : super(key: key);

  @override
  State<CashSettlementPage> createState() => _CashSettlementPageState();
}

class _CashSettlementPageState extends State<CashSettlementPage> {
  final _supabase = Supabase.instance.client;
  double _cashPending = 0;
  int _orderCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final driverId = context.read<AuthProvider>().currentUser?.idUser;
    if (driverId == null) return;

    try {
      final driver = await _supabase
          .from('drivers')
          .select('total_cash_pending, jumlah_order_belum_setor')
          .eq('id_driver', driverId)
          .single();

      setState(() {
        _cashPending = (driver['total_cash_pending'] ?? 0).toDouble();
        _orderCount = driver['jumlah_order_belum_setor'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showTopUpDialog() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TopUpBottomSheet(
        userId: currentUser.idUser,
        userName: currentUser.nama,
        userEmail: currentUser.email,
        userPhone: currentUser.noTelp, 
        isCashSettlement: true,
        onSuccess: (amount) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlement berhasil diajukan')),
          );
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cash Settlement')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('Cash Pending',
                              style: TextStyle(fontSize: 16)),
                          SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(_cashPending),
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          Text('$_orderCount order belum disetor'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_cashPending > 0)
                    ElevatedButton(
                      onPressed: _showTopUpDialog,
                      child: Text('Setor Cash'),
                    ),
                ],
              ),
            ),
    );
  }
}