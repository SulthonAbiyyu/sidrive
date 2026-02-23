import 'package:flutter/material.dart';
import 'package:sidrive/screens/admin/contents/statistik/overview_cards.dart';
import 'package:sidrive/screens/admin/contents/statistik/revenue_trend_chart.dart';
import 'package:sidrive/screens/admin/contents/statistik/user_distribution_chart.dart';
import 'package:sidrive/screens/admin/contents/statistik/orders_chart.dart';
import 'package:sidrive/screens/admin/contents/statistik/recent_activities.dart';
import 'package:sidrive/screens/admin/contents/statistik/performance_metrics.dart';

/// ============================================================================
/// STATISTIK CONTENT - Complete Statistics Dashboard
/// ============================================================================
/// LIGHT THEME ONLY - Matching Dashboard Design
/// Dashboard statistik dengan modular components
/// ============================================================================

class StatistikContent extends StatefulWidget {
  const StatistikContent({super.key});

  @override
  State<StatistikContent> createState() => _StatistikContentState();
}

class _StatistikContentState extends State<StatistikContent> {
  String _selectedPeriod = '7days'; // 7days, 30days, 3months, 1year
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        const OverviewCards(),

                        const SizedBox(height: 32),

                        // Charts Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Revenue Trend Chart (Left 60%)
                            Expanded(
                              flex: 60,
                              child: RevenueTrendChart(period: _selectedPeriod),
                            ),

                            const SizedBox(width: 24),

                            // User Distribution Chart (Right 40%)
                            const Expanded(
                              flex: 40,
                              child: UserDistributionChart(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Orders Chart & Recent Activities
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Orders Chart (Left 55%)
                            Expanded(
                              flex: 55,
                              child: OrdersChart(period: _selectedPeriod),
                            ),

                            const SizedBox(width: 24),

                            // Recent Activities (Right 45%)
                            const Expanded(
                              flex: 45,
                              child: RecentActivities(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Performance Metrics
                        const PerformanceMetrics(),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistik & Analitik',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Overview performa platform SiDrive',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Period Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                _buildPeriodButton('7 Hari', '7days'),
                _buildPeriodButton('30 Hari', '30days'),
                _buildPeriodButton('3 Bulan', '3months'),
                _buildPeriodButton('1 Tahun', '1year'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadStatistics();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}