import 'package:flutter/material.dart';

class PendapatanCardWidget extends StatelessWidget {
  final double totalPendapatan;
  final int totalPesanan;
  final double totalJarak;
  final String periode;

  const PendapatanCardWidget({
    Key? key,
    required this.totalPendapatan,
    required this.totalPesanan,
    required this.totalJarak,
    required this.periode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hardcoded Target for visual flair (Innovation aspect)
    // In real app, this would come from a GoalService
    final double dailyTarget = 500000; 
    final double progress = (totalPendapatan / dailyTarget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Glassmorphism base
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: Income & Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pendapatan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  FittedBox(
                    child: Text(
                      'Rp ${_formatSimple(totalPendapatan)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32, // Hero Size
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                   SizedBox(height: 6),
                   Container(
                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(20)
                     ),
                     child: Text(
                       'Target Hari Ini: Rp 500rb',
                       style: TextStyle(fontSize: 10, color: Colors.white),
                     ),
                   )
                ],
              ),
              
              // RIGHT: Circular Progress Indicator (Visual Innovation)
              SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 6,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      color: Colors.white,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            ],
          ),
          
          SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          SizedBox(height: 16),
          
          // BOTTOM: Grid Stats (Mini)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.shopping_bag_outlined, '$totalPesanan', 'Order'),
              _buildVerticalDivider(),
              _buildStatItem(Icons.map_outlined, '${totalJarak.toStringAsFixed(1)}', 'km'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(height: 20, width: 1, color: Colors.white.withOpacity(0.2));

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        )
      ],
    );
  }

  String _formatSimple(double amount) {
    // Returns 100rb, 1.5jt, or full number
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 100000) return '${(amount / 1000).toStringAsFixed(0)}rb';
     return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}