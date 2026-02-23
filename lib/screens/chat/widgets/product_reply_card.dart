// ============================================================================
// PRODUCT REPLY CARD WIDGET
// Menampilkan produk yang di-reply dalam chat (seperti Shopee)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:intl/intl.dart';

class ProductReplyCard extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const ProductReplyCard({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? {};
    final productName = metadata['product_name'] ?? 'Produk';
    final productImage = metadata['product_image'] ?? '';
    final productPrice = metadata['product_price'] ?? 0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) _buildAvatar(),
          if (!isMine) SizedBox(width: 8.w),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 0.75.sw),
              decoration: BoxDecoration(
                color: ChatTheme.getBubbleColor(isMine),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(isMine ? 18.r : 4.r),
                  bottomRight: Radius.circular(isMine ? 4.r : 18.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product card
                  Container(
                    margin: EdgeInsets.all(8.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isMine 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: ChatTheme.productReplyBorder.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: productImage.isNotEmpty
                              ? Image.network(
                                  productImage,
                                  width: 60.w,
                                  height: 60.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderImage();
                                  },
                                )
                              : _buildPlaceholderImage(),
                        ),
                        
                        SizedBox(width: 12.w),
                        
                        // Product info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name
                              Text(
                                productName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isMine ? Colors.white : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              SizedBox(height: 6.h),
                              
                              // Price
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine 
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFFFF85A1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'Rp ${_formatPrice(productPrice)}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isMine 
                                        ? Colors.white 
                                        : const Color(0xFFFF85A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: isMine 
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                  
                  // Additional text (jika ada)
                  if (message.textContent != null && message.textContent!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                      child: Text(
                        message.textContent!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ChatTheme.getTextColor(isMine),
                          height: 1.4,
                        ),
                      ),
                    ),
                  
                  // Time & status
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isMine 
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey.shade600,
                          ),
                        ),
                        
                        if (isMine) ...[
                          SizedBox(width: 4.w),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMine) SizedBox(width: 8.w),
          if (isMine) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60.w,
      height: 60.w,
      color: isMine 
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.shade200,
      child: Icon(
        Icons.shopping_bag,
        color: isMine ? Colors.white.withOpacity(0.5) : Colors.grey.shade400,
        size: 30.sp,
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: isMine 
          ? const Color(0xFFFF85A1) 
          : Colors.grey.shade300,
      child: Icon(
        Icons.shopping_bag,
        size: 16.sp,
        color: isMine ? Colors.white : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    
    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        color = Colors.white.withOpacity(0.6);
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = Colors.white.withOpacity(0.8);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withOpacity(0.8);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue.shade300;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red.shade300;
        break;
    }
    
    return Icon(icon, size: 14.sp, color: color);
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price).replaceAll(',', '.');
  }
}