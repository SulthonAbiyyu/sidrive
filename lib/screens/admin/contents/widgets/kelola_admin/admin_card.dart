import 'package:flutter/material.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class AdminCard extends StatelessWidget {
  final AdminModel admin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminCard({
    super.key,
    required this.admin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM() + 2),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: ResponsiveAdmin.shadowSM(Colors.black),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM() + 2),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
                  ),
                  child: Center(
                    child: Text(
                      admin.nama[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontBody(),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveAdmin.spaceSM()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.nama,
                        style: TextStyle(
                          fontSize: ResponsiveAdmin.fontCaption() + 2,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveAdmin.spaceXS() - 1),
                      Row(
                        children: [
                          Text(
                            admin.username,
                            style: TextStyle(
                              fontSize: ResponsiveAdmin.fontSmall(),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveAdmin.spaceXS() + 2,
                            ),
                            child: const Text('•', style: TextStyle(color: Color(0xFF6B7280))),
                          ),
                          Expanded(
                            child: Text(
                              admin.email,
                              style: TextStyle(
                                fontSize: ResponsiveAdmin.fontSmall(),
                                color: const Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildLevelBadge(admin.level),
                SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
                _buildStatusBadge(admin.isActive),
                SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
                PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    else if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF6B7280)),
                          SizedBox(width: ResponsiveAdmin.spaceXS() + 2),
                          Text('Edit', style: TextStyle(fontSize: ResponsiveAdmin.fontCaption() + 1)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_rounded, size: 15, color: Color(0xFFEF4444)),
                          SizedBox(width: ResponsiveAdmin.spaceXS() + 2),
                          Text('Hapus', style: TextStyle(fontSize: ResponsiveAdmin.fontCaption() + 1, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF6B7280), size: 16),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    final isSuperAdmin = level == 'super_admin';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveAdmin.spaceXS() + 4,
        vertical: ResponsiveAdmin.spaceXS(),
      ),
      decoration: BoxDecoration(
        color: isSuperAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuperAdmin ? Icons.workspace_premium_rounded : Icons.person_rounded,
            size: 12,
            color: isSuperAdmin ? const Color(0xFF92400E) : const Color(0xFF1E40AF),
          ),
          SizedBox(width: ResponsiveAdmin.spaceXS() - 2),
          Text(
            isSuperAdmin ? 'Super Admin' : 'Admin',
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontSmall() - 1,
              fontWeight: FontWeight.w600,
              color: isSuperAdmin ? const Color(0xFF92400E) : const Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveAdmin.spaceXS() + 4,
        vertical: ResponsiveAdmin.spaceXS(),
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: ResponsiveAdmin.fontSmall() - 1,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
        ),
      ),
    );
  }
}