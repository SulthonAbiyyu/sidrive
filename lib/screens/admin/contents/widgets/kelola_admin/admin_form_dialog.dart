import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/models/admin_model.dart';
import 'package:sidrive/core/utils/responsive_admin.dart';

class AdminFormDialog extends StatefulWidget {
  final AdminModel? admin;
  final List<String> levelList;
  final VoidCallback onSuccess;

  const AdminFormDialog({
    super.key,
    this.admin,
    required this.levelList,
    required this.onSuccess,
  });

  @override
  State<AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<AdminFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _namaController;
  late TextEditingController _passwordController;
  late String _selectedLevel;
  late bool _isActive;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.admin != null;
    _usernameController = TextEditingController(text: isEdit ? widget.admin!.username : '');
    _emailController = TextEditingController(text: isEdit ? widget.admin!.email : '');
    _namaController = TextEditingController(text: isEdit ? widget.admin!.nama : '');
    _passwordController = TextEditingController();
    _selectedLevel = isEdit ? widget.admin!.level : widget.levelList.first;
    _isActive = isEdit ? widget.admin!.isActive : true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _namaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final adminProvider = context.read<AdminProvider>();
    bool success;

    try {
      if (widget.admin == null) {
        // CREATE
        success = await adminProvider.createAdmin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          nama: _namaController.text.trim(),
          level: _selectedLevel,
        );
      } else {
        // UPDATE
        success = await adminProvider.updateAdmin(
          idAdmin: widget.admin!.idAdmin,
          nama: _namaController.text.trim(),
          level: _selectedLevel,
          isActive: _isActive,
          newPassword: _passwordController.text.isEmpty ? null : _passwordController.text,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context);
          widget.onSuccess();
          _showSuccessSnackBar(widget.admin == null ? 'Admin berhasil ditambahkan' : 'Admin berhasil diupdate');
        } else {
          _showErrorSnackBar(adminProvider.errorMessage ?? 'Terjadi kesalahan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.admin != null;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusMD())),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: EdgeInsets.all(ResponsiveAdmin.spaceMD() + 4),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveAdmin.spaceXS() + 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceSM()),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Admin' : 'Tambah Admin Baru',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontH4(),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      padding: EdgeInsets.all(ResponsiveAdmin.spaceXS()),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveAdmin.spaceMD()),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username (disabled saat edit)
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Masukkan username',
                        icon: Icons.person_outline_rounded,
                        enabled: !isEdit,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Username wajib diisi';
                          if (value.length < 3) return 'Username minimal 3 karakter';
                          return null;
                        },
                      ),
                      SizedBox(height: ResponsiveAdmin.spaceSM()),

                      // Email (disabled saat edit)
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Masukkan email',
                        icon: Icons.email_outlined,
                        enabled: !isEdit,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
                          if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$').hasMatch(value)) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: ResponsiveAdmin.spaceSM()),

                      // Nama
                      _buildTextField(
                        controller: _namaController,
                        label: 'Nama Lengkap',
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Nama wajib diisi';
                          return null;
                        },
                      ),
                      SizedBox(height: ResponsiveAdmin.spaceSM()),

                      // Password
                      _buildTextField(
                        controller: _passwordController,
                        label: isEdit ? 'Password Baru (Opsional)' : 'Password',
                        hint: isEdit ? 'Kosongkan jika tidak ingin mengubah' : 'Masukkan password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          color: const Color(0xFF6B7280),
                        ),
                        validator: (value) {
                          if (!isEdit && (value == null || value.isEmpty)) return 'Password wajib diisi';
                          if (value != null && value.isNotEmpty && value.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: ResponsiveAdmin.spaceSM()),

                      // Level
                      Text(
                        'Level',
                        style: TextStyle(
                          fontSize: ResponsiveAdmin.fontCaption() + 1,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: ResponsiveAdmin.spaceXS()),
                      DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        isDense: true, // 🔑 bikin ramping
                        icon: const Icon(Icons.expand_more_rounded),
                        dropdownColor: Colors.white,
                        style: TextStyle(
                          fontSize: ResponsiveAdmin.fontBody(),
                          color: const Color(0xFF111827),
                        ),
                        items: widget.levelList.map((level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(
                              level == 'super_admin' ? 'Super Admin' : 'Admin',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          isDense: true, // 🔑 penting
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ResponsiveAdmin.spaceSM(),
                            vertical: ResponsiveAdmin.spaceXS() + 2, // 🔑 lebih ramping
                          ),
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
                        ),
                      ),

                      // Status (hanya saat edit)
                      if (isEdit) ...[
                        SizedBox(height: ResponsiveAdmin.spaceSM()),
                        Container(
                          padding: EdgeInsets.all(ResponsiveAdmin.spaceSM()),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: _isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                size: 18,
                              ),
                              SizedBox(width: ResponsiveAdmin.spaceSM()),
                              Expanded(
                                child: Text(
                                  'Status Akun',
                                  style: TextStyle(
                                    fontSize: ResponsiveAdmin.fontBody(),
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (value) => setState(() => _isActive = value),
                                activeColor: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveAdmin.spaceMD()),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: ResponsiveAdmin.fontBody(),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveAdmin.spaceXS() + 4),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveAdmin.spaceMD(),
                        vertical: ResponsiveAdmin.spaceSM(),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Simpan',
                            style: TextStyle(
                              fontSize: ResponsiveAdmin.fontBody(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveAdmin.fontCaption() + 1,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: ResponsiveAdmin.spaceXS()),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          validator: validator,
          style: TextStyle(
            fontSize: ResponsiveAdmin.fontBody(),
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF9CA3AF), fontSize: ResponsiveAdmin.fontBody()),
            prefixIcon: Icon(icon, size: 18, color: enabled ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveAdmin.radiusSM()),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveAdmin.spaceSM(),
              vertical: ResponsiveAdmin.spaceSM(),
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}