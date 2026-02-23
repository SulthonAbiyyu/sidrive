import 'package:flutter/material.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';
import 'package:sidrive/services/mahasiswa_import_service.dart';


/// Dialog untuk import CSV mahasiswa dengan preview dan konfirmasi
class MahasiswaImportDialog extends StatefulWidget {
  final ImportValidationResult validationResult;
  final Function(List<MahasiswaImportItem> items, bool replaceAll) onConfirmImport;

  const MahasiswaImportDialog({
    super.key,
    required this.validationResult,
    required this.onConfirmImport,
  });

  @override
  State<MahasiswaImportDialog> createState() => _MahasiswaImportDialogState();
}

class _MahasiswaImportDialogState extends State<MahasiswaImportDialog> {
  // Track replace decision untuk setiap duplicate
  final Map<String, bool> _replaceDecisions = {};
  bool _replaceAll = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize semua duplicate ke false (skip)
    for (var item in widget.validationResult.duplicateItems) {
      _replaceDecisions[item.nim] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD() + 4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS() + 2),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          SizedBox(width: ResponsiveAdmin.spaceSM()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview Import CSV',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontH4(),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: ResponsiveAdmin.spaceXS() - 2),
                Text(
                  '${widget.validationResult.totalItems} data ditemukan',
                  style: TextStyle(
                    fontSize: ResponsiveAdmin.fontSmall(),
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          
          if (widget.validationResult.hasErrors) ...[
            SizedBox(height: ResponsiveAdmin.spaceMD()),
            _buildErrorSection(),
          ],
          
          if (widget.validationResult.hasDuplicates) ...[
            SizedBox(height: ResponsiveAdmin.spaceMD()),
            _buildDuplicateSection(),
          ],
          
          if (widget.validationResult.hasValidItems) ...[
            SizedBox(height: ResponsiveAdmin.spaceMD()),
            _buildValidSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Data Valid',
            widget.validationResult.validItems.length.toString(),
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
          ),
        ),
        SizedBox(width: ResponsiveAdmin.spaceSM()),
        Expanded(
          child: _buildSummaryCard(
            'Duplikat',
            widget.validationResult.duplicateItems.length.toString(),
            Icons.warning_rounded,
            const Color(0xFFF59E0B),
          ),
        ),
        SizedBox(width: ResponsiveAdmin.spaceSM()),
        Expanded(
          child: _buildSummaryCard(
            'Error',
            widget.validationResult.errors.length.toString(),
            Icons.error_rounded,
            const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM() + 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: ResponsiveAdmin.spaceXS()),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontH3(),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontSmall(),
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_rounded, color: Color(0xFFEF4444), size: 16),
            SizedBox(width: ResponsiveAdmin.spaceXS()),
            Text(
              'Data Error (${widget.validationResult.errors.length})',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveAdmin.spaceXS() + 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          ),
          child: ListView.separated(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            itemCount: widget.validationResult.errors.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final error = widget.validationResult.errors[index];
              return _buildErrorItem(error);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorItem(ImportError error) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveAdmin.spaceXS() + 2,
            vertical: ResponsiveAdmin.spaceXS() - 2,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(ResponsiveAdmin.spaceXS()),
          ),
          child: Text(
            'Row ${error.rowNumber}',
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontSmall() - 1,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEF4444),
            ),
          ),
        ),
        SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${error.nim} - ${error.namaLengkap}',
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontCaption() + 1,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                error.errorMessage,
                style: TextStyle(
                  fontSize: ResponsiveAdmin.fontSmall(),
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B), size: 16),
            SizedBox(width: ResponsiveAdmin.spaceXS()),
            Text(
              'Data Duplikat (${widget.validationResult.duplicateItems.length})',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const Spacer(),
            // Replace All Toggle
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _replaceAll = !_replaceAll;
                  for (var item in widget.validationResult.duplicateItems) {
                    _replaceDecisions[item.nim] = _replaceAll;
                  }
                });
              },
              icon: Icon(
                _replaceAll ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 16,
              ),
              label: const Text('Replace All'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveAdmin.spaceXS() + 4,
                  vertical: ResponsiveAdmin.spaceXS(),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveAdmin.spaceXS() + 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          ),
          child: ListView.separated(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            itemCount: widget.validationResult.duplicateItems.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = widget.validationResult.duplicateItems[index];
              return _buildDuplicateItem(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateItem(MahasiswaImportItem item) {
    final shouldReplace = _replaceDecisions[item.nim] ?? false;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
      decoration: BoxDecoration(
        color: shouldReplace 
            ? const Color(0xFF6366F1).withOpacity(0.05)
            : const Color(0xFFF59E0B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.nim} - ${item.namaLengkap}',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontCaption() + 1,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: ResponsiveAdmin.spaceXS() - 2),
                    Text(
                      'Data baru: ${item.programStudi ?? "-"} • ${item.angkatan ?? "-"}',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontSmall(),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      'Data lama: ${item.existingData?.programStudi ?? "-"} • ${item.existingData?.angkatan ?? "-"}',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontSmall(),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Replace Toggle
              Checkbox(
                value: shouldReplace,
                onChanged: (value) {
                  setState(() {
                    _replaceDecisions[item.nim] = value ?? false;
                    // Update replace all state
                    _replaceAll = _replaceDecisions.values.every((v) => v);
                  });
                },
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
            SizedBox(width: ResponsiveAdmin.spaceXS()),
            Text(
              'Data Valid (${widget.validationResult.validItems.length})',
              style: TextStyle(
                fontSize: ResponsiveAdmin.fontBody(),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveAdmin.spaceXS() + 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
          ),
          child: ListView.separated(
            padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
            itemCount: widget.validationResult.validItems.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final item = widget.validationResult.validItems[index];
              return _buildValidItem(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValidItem(MahasiswaImportItem item) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, 
          color: Color(0xFF10B981), size: 14),
        SizedBox(width: ResponsiveAdmin.spaceXS() + 2),
        Expanded(
          child: Text(
            '${item.nim} - ${item.namaLengkap}',
            style: TextStyle(
              fontSize: ResponsiveAdmin.fontCaption() + 1,
              color: const Color(0xFF111827),
            ),
          ),
        ),
        Text(
          '${item.programStudi ?? "-"}',
          style: TextStyle(
            fontSize: ResponsiveAdmin.fontSmall(),
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final canImport = widget.validationResult.hasValidItems || 
                      widget.validationResult.hasDuplicates;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveAdmin.spaceSM() + 6,
                vertical: ResponsiveAdmin.spaceXS() + 6,
              ),
            ),
            child: const Text('Batal'),
          ),
          SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
          ElevatedButton.icon(
            onPressed: canImport ? _handleImport : null,
            icon: const Icon(Icons.upload_rounded, size: 15),
            label: const Text('Import Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveAdmin.spaceSM() + 6,
                vertical: ResponsiveAdmin.spaceXS() + 6,
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

  void _handleImport() {
    // Collect items to import
    final List<MahasiswaImportItem> itemsToImport = [
      ...widget.validationResult.validItems,
      ...widget.validationResult.duplicateItems.where(
        (item) => _replaceDecisions[item.nim] == true,
      ),
    ];

    if (itemsToImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data yang akan diimport'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    Navigator.pop(context);
    widget.onConfirmImport(itemsToImport, _replaceAll);
  }
}