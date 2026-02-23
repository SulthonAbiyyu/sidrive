import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class PeriodeSelectorWidget extends StatelessWidget {
  final String selectedPeriode;
  final Function(String) onPeriodeChanged;

  const PeriodeSelectorWidget({
    Key? key,
    required this.selectedPeriode,
    required this.onPeriodeChanged,
    this.activeColor = const Color(0xFFFF6B9D),
    this.activeTextColor = Colors.white,
    this.inactiveColor = Colors.white,
    this.inactiveTextColor = const Color(0xFF616161),
  }) : super(key: key);

  final Color activeColor;
  final Color activeTextColor;
  final Color inactiveColor;
  final Color inactiveTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildPeriodeChip('Hari Ini', 'hari')),
        SizedBox(width: 4),
        Expanded(child: _buildPeriodeChip('Minggu Ini', 'minggu')),
        SizedBox(width: 4),
        Expanded(child: _buildPeriodeChip('Bulan Ini', 'bulan')),
      ],
    );
  }

  Widget _buildPeriodeChip(String label, String value) {
    final isActive = selectedPeriode == value;
    
    return GestureDetector(
      onTap: () => onPeriodeChanged(value),
      child: Container(
        // Reduced vertical padding to prevent overflow issues
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(9)),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : [],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                color: isActive ? activeTextColor : inactiveTextColor,
                fontSize: ResponsiveMobile.scaledFont(12), // Slightly larger base, scales down
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}