// ============================================================================
// MESSAGE BUBBLE WIDGET
// Reusable widget untuk menampilkan chat bubble
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sidrive/models/chat_models.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
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
              constraints: BoxConstraints(maxWidth: 0.7.sw),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  if (message.type == MessageType.text)
                    _buildTextContent()
                  else if (message.type == MessageType.image)
                    _buildImageContent()
                  else if (message.type == MessageType.systemInfo)
                    _buildSystemInfo(),
                  
                  SizedBox(height: 4.h),
                  
                  // Time & status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt.toUtc().add(const Duration(hours: 7))),
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

  Widget _buildTextContent() {
    return SelectableText(
      message.textContent ?? '',
      style: TextStyle(
        fontSize: 14.sp,
        color: ChatTheme.getTextColor(isMine),
        height: 1.4,
      ),
    );
  }

  Widget _buildImageContent() {
    if (message.imageUrl == null) return const SizedBox();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.network(
        message.imageUrl!,
        width: 200.w,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200.w,
            height: 150.h,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200.w,
            height: 150.h,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info_outline,
          size: 16.sp,
          color: isMine ? Colors.white : const Color(0xFFFF85A1),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            message.textContent ?? '',
            style: TextStyle(
              fontSize: 13.sp,
              color: isMine ? Colors.white : Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16.r,
      backgroundColor: isMine 
          ? const Color(0xFFFF85A1) 
          : Colors.grey.shade300,
      child: Text(
        message.senderRole[0].toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: isMine ? Colors.white : Colors.grey.shade700,
        ),
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
}