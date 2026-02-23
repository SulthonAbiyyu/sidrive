import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class AdminFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final String filterLevel;
  final String filterStatus;
  final List<String> levelList;
  final List<String> statusList;
  final Function(String?) onLevelChanged;
  final Function(String?) onStatusChanged;

  const AdminFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.filterLevel,
    required this.filterStatus,
    required this.levelList,
    required this.statusList,
    required this.onLevelChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD()),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontCaption() + 1,
                color: const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Cari Username, Nama, atau Email...',
                hintStyle: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: ResponsiveAdmin.fontCaption() + 1,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 16),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveAdmin.spaceSM(),
                  vertical: ResponsiveAdmin.spaceXS() + 4,
                ),
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: filterLevel,
              items: levelList,
              onChanged: onLevelChanged,
              hint: 'Level',
            ),
          ),
          SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: filterStatus,
              items: statusList,
              onChanged: onStatusChanged,
              hint: 'Status',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontCaption() + 1,
              color: const Color(0xFF111827),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveAdmin.spaceSM(),
          vertical: ResponsiveAdmin.spaceXS() + 4,
        ),
        isDense: true,
      ),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6B7280), size: 18),
      isExpanded: true,
    );
  }
}