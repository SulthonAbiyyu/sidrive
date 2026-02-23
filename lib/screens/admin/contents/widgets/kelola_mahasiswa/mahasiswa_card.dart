import 'package:flutter/material.dart';
import 'package:sidrive/models/mahasiswa_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class MahasiswaCard extends StatelessWidget {
  final MahasiswaModel mahasiswa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MahasiswaCard({
    super.key,
    required this.mahasiswa,
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
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
                  ),
                  child: Center(
                    child: Text(
                      mahasiswa.namaLengkap[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontBody(),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: ResponsiveAdmin.spaceSM()),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mahasiswa.namaLengkap,
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
                            mahasiswa.nim,
                            style: TextStyle(
                              fontSize: ResponsiveAdmin.fontSmall(),
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (mahasiswa.programStudi != null) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveAdmin.spaceXS() + 2,
                              ),
                              child: const Text(
                                '•',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                mahasiswa.programStudi!,
                                style: TextStyle(
                                  fontSize: ResponsiveAdmin.fontSmall(),
                                  color: const Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (mahasiswa.angkatan != null) ...[
                        SizedBox(height: ResponsiveAdmin.spaceXS() - 2),
                        Text(
                          'Angkatan ${mahasiswa.angkatan}',
                          style: TextStyle(
                            fontSize: ResponsiveAdmin.fontSmall() - 1,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status Badge
                _buildStatusBadge(mahasiswa.statusMahasiswa),
                
                SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
                
                // Actions Menu
                PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF6B7280)),
                          SizedBox(width: ResponsiveAdmin.spaceXS() + 2),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: ResponsiveAdmin.fontCaption() + 1,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_rounded, size: 15, color: Color(0xFFEF4444)),
                          SizedBox(width: ResponsiveAdmin.spaceXS() + 2),
                          Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: ResponsiveAdmin.fontCaption() + 1,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF6B7280),
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    
    switch (status.toLowerCase()) {
      case 'aktif':
        backgroundColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = 'Aktif';
        break;
      case 'lulus':
        backgroundColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        label = 'Lulus';
        break;
      case 'cuti':
        backgroundColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        label = 'Cuti';
        break;
      case 'nonaktif':
        backgroundColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = 'Nonaktif';
        break;
      default:
        backgroundColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = status;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveAdmin.spaceXS() + 4,
        vertical: ResponsiveAdmin.spaceXS(),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: ResponsiveAdmin.fontSmall() - 1,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}