// ============================================================================
// CHAT ACTIVATION BANNER
// Banner untuk menampilkan status aktivasi chat (customer-driver)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatActivationBanner extends StatelessWidget {
  final String reason;
  final double progress; // 0.0 - 1.0

  const ChatActivationBanner({
    super.key,
    required this.reason,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock,
                  color: Colors.orange.shade800,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Belum Aktif',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress Perjalanan',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    '${progress.toStringAsFixed(1)} km / ${2.0.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Progress bar
              Stack(
                children: [
                  // Background
                  Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  
                  // Progress fill
                  FractionallySizedBox(
                    // ✅ FIXED: progress adalah nilai km (0-2), dibagi 2.0 agar 2km = 100%
                    widthFactor: (progress / 2.0).clamp(0.0, 1.0),
                    child: Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  
                  // End marker (2 KM target)
                  Positioned(
                    right: 0,
                    top: -2.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '2 km',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Info text
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Chat akan aktif otomatis saat driver menempuh 2 km perjalanan',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}