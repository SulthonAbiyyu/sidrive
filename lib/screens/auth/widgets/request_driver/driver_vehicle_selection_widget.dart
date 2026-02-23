// lib/screens/driver/widgets/request_driver/driver_vehicle_selection_widget.dart
import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class DriverVehicleSelectionWidget extends StatelessWidget {
  final bool isMotorLocked;
  final bool isMobilLocked;
  final bool isMotorSelected;
  final bool isMobilSelected;
  final String? motorLockedReason;
  final String? mobilLockedReason;
  final void Function(String type) onVehicleToggle;

  const DriverVehicleSelectionWidget({
    super.key,
    required this.isMotorLocked,
    required this.isMobilLocked,
    required this.isMotorSelected,
    required this.isMobilSelected,
    required this.motorLockedReason,
    required this.mobilLockedReason,
    required this.onVehicleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Jenis Kendaraan',
          style: TextStyle(
            fontSize: ResponsiveMobile.bodySize(context) + 1,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        ResponsiveMobile.vSpace(8),
        Text(
          'Anda bisa mendaftar Motor, Mobil, atau keduanya sekaligus',
          style: TextStyle(
            fontSize: ResponsiveMobile.captionSize(context),
            color: Colors.grey.shade600,
          ),
        ),
        ResponsiveMobile.vSpace(16),
        // ✅ FIX: GRID LAYOUT DENGAN ASPECT RATIO 1:1
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95, // Sedikit lebih tinggi untuk konten
          children: [
            _buildVehicleCard(
              context: context,
              type: 'motor',
              title: 'Motor',
              subtitle: 'Ojek Motor',
              icon: Icons.two_wheeler_rounded,
              color: Colors.green.shade600,
              isLocked: isMotorLocked,
              lockedReason: motorLockedReason,
              isSelected: isMotorSelected,
            ),
            _buildVehicleCard(
              context: context,
              type: 'mobil',
              title: 'Mobil',
              subtitle: 'Ojek Mobil',
              icon: Icons.directions_car_rounded,
              color: Colors.blue.shade600,
              isLocked: isMobilLocked,
              lockedReason: mobilLockedReason,
              isSelected: isMobilSelected,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleCard({
    required BuildContext context,
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLocked,
    required String? lockedReason,
    required bool isSelected,
  }) {
    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.lock_rounded;
    if (isLocked && lockedReason != null) {
      switch (lockedReason) {
        case 'pending':
          statusText = 'Verifikasi';
          statusColor = Colors.orange.shade600;
          statusIcon = Icons.schedule_rounded;
          break;
        case 'approved':
          statusText = 'Disetujui';
          statusColor = Colors.green.shade600;
          statusIcon = Icons.check_circle_rounded;
          break;
        case 'rejected':
          statusText = 'Ditolak';
          statusColor = Colors.red.shade600;
          statusIcon = Icons.cancel_rounded;
          break;
      }
    }

    return InkWell(
      onTap: isLocked ? null : () => onVehicleToggle(type),
      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
      child: Container(
        padding: ResponsiveMobile.allScaledPadding(14),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.grey.shade100
              : (isSelected ? color.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
          border: Border.all(
            color: isLocked
                ? Colors.grey.shade300
                : (isSelected ? color : Colors.grey.shade200),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (!isLocked && isSelected)
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            if (!isLocked && !isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveMobile.scaledW(56),
              height: ResponsiveMobile.scaledW(56),
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.shade200
                    : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(14)),
              ),
              child: Icon(
                icon,
                color: isLocked ? Colors.grey.shade500 : color,
                size: ResponsiveMobile.scaledFont(32),
              ),
            ),
            ResponsiveMobile.vSpace(10),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveMobile.bodySize(context),
                fontWeight: FontWeight.w700,
                color: isLocked ? Colors.grey.shade700 : Colors.black87,
              ),
            ),
            ResponsiveMobile.vSpace(4),
            if (isLocked) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveMobile.scaledW(8),
                  vertical: ResponsiveMobile.scaledH(3),
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: ResponsiveMobile.scaledFont(12),
                      color: statusColor,
                    ),
                    ResponsiveMobile.hSpace(3),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context) - 1,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: ResponsiveMobile.captionSize(context),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            ResponsiveMobile.vSpace(10),
            if (isLocked)
              Icon(
                Icons.lock_rounded,
                color: Colors.grey.shade500,
                size: ResponsiveMobile.scaledFont(22),
              )
            else
              Container(
                width: ResponsiveMobile.scaledW(22),
                height: ResponsiveMobile.scaledW(22),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(6)),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: ResponsiveMobile.scaledFont(14),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}