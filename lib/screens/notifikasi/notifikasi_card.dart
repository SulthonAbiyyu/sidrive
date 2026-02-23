// ============================================================================
// NOTIFIKASI CARD WIDGET
// Widget untuk menampilkan satu notifikasi dalam list
// ============================================================================

import 'package:flutter/material.dart';
import 'package:sidrive/models/notifikasi_model.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';

class NotifikasiCard extends StatelessWidget {
  final NotifikasiModel notifikasi;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotifikasiCard({
    super.key,
    required this.notifikasi,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notifikasi.idNotifikasi),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(12)),
          padding: ResponsiveMobile.allScaledPadding(16),
          decoration: BoxDecoration(
            color: notifikasi.isUnread 
                ? Colors.blue.shade50 
                : Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
            border: Border.all(
              color: notifikasi.isUnread 
                  ? Colors.blue.shade200 
                  : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              _buildIcon(),
              
              ResponsiveMobile.hSpace(12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notifikasi.judul,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.bodySize(context),
                              fontWeight: notifikasi.isUnread 
                                  ? FontWeight.bold 
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notifikasi.isUnread) ...[
                          ResponsiveMobile.hSpace(8),
                          Container(
                            width: ResponsiveMobile.scaledW(8),
                            height: ResponsiveMobile.scaledW(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    ResponsiveMobile.vSpace(6),
                    
                    // Body
                    Text(
                      notifikasi.pesan,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.captionSize(context),
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    ResponsiveMobile.vSpace(8),
                    
                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: ResponsiveMobile.scaledFont(12),
                          color: Colors.grey.shade500,
                        ),
                        ResponsiveMobile.hSpace(4),
                        Text(
                          notifikasi.timeAgo,
                          style: TextStyle(
                            fontSize: ResponsiveMobile.captionSize(context) - 1,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (notifikasi.jenis) {
      case 'pesanan':
        iconColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade100;
        icon = Icons.receipt_long_rounded;
        break;
      case 'pembayaran':
        iconColor = Colors.green.shade700;
        bgColor = Colors.green.shade100;
        icon = Icons.payment_rounded;
        break;
      case 'withdrawal':
        iconColor = Colors.orange.shade700;
        bgColor = Colors.orange.shade100;
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'promo':
        iconColor = Colors.purple.shade700;
        bgColor = Colors.purple.shade100;
        icon = Icons.local_offer_rounded;
        break;
      case 'sistem':
      default:
        iconColor = Colors.grey.shade700;
        bgColor = Colors.grey.shade100;
        icon = Icons.notifications_rounded;
    }

    return Container(
      width: ResponsiveMobile.scaledW(48),
      height: ResponsiveMobile.scaledW(48),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: ResponsiveMobile.scaledFont(24),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: ResponsiveMobile.scaledW(20)),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
      ),
      child: Icon(
        Icons.delete_rounded,
        color: Colors.white,
        size: ResponsiveMobile.scaledFont(28),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        title: const Text('Hapus Notifikasi?'),
        content: const Text('Notifikasi yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}