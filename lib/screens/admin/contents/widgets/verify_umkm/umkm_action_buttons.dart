import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class UmkmActionButtons extends StatelessWidget {
  final UmkmVerification umkm;
  final Function(UmkmVerification) onApprove;
  final Function(UmkmVerification) onReject;

  const UmkmActionButtons({
    super.key,
    required this.umkm,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final isProcessing = adminProvider.isLoading;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveAdmin.spaceXL(),
        vertical: ResponsiveAdmin.spaceLG(),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tolak Button
          OutlinedButton.icon(
            onPressed: isProcessing ? null : () => onReject(umkm),
            icon: Icon(Icons.close_rounded, size: ResponsiveAdmin.fontH4()),
            label: Text(
              'Tolak',
              style: TextStyle(fontSize: ResponsiveAdmin.fontBody()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              disabledForegroundColor: const Color(0xFFEF4444).withOpacity(0.5),
              side: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveAdmin.spaceLG(),
                vertical: ResponsiveAdmin.spaceMD() - 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              ),
            ),
          ),
          
          SizedBox(width: ResponsiveAdmin.spaceMD()),
          
          // Terima Button
          ElevatedButton.icon(
            onPressed: isProcessing ? null : () => onApprove(umkm),
            icon: isProcessing
                ? SizedBox(
                    width: ResponsiveAdmin.spaceMD(),
                    height: ResponsiveAdmin.spaceMD(),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.check_rounded, size: ResponsiveAdmin.fontH4()),
            label: Text(
              isProcessing ? 'Memproses...' : 'Terima',
              style: TextStyle(fontSize: ResponsiveAdmin.fontBody()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
              disabledForegroundColor: Colors.white70,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveAdmin.spaceLG(),
                vertical: ResponsiveAdmin.spaceMD() - 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}