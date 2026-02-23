import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/providers/auth_provider.dart';

/// ============================================================================
/// PENGATURAN CONTENT - LIGHT THEME ONLY
/// ============================================================================

class PengaturanContent extends StatefulWidget {
  const PengaturanContent({super.key});

  @override
  State<PengaturanContent> createState() => _PengaturanContentState();
}

class _PengaturanContentState extends State<PengaturanContent> {
  String _selectedTab = 'profile';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar
              Container(
                width: 240,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildNavigationMenu(),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
                  child: _buildContentByTab(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengaturan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                SizedBox(height: 2),
                Text('Kelola akun dan preferensi sistem', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return Column(
      children: [
        _buildNavItem('Profile', Icons.person_rounded, 'profile'),
        _buildNavItem('Keamanan', Icons.security_rounded, 'security'),
        _buildNavItem('Notifikasi', Icons.notifications_rounded, 'notification'),
        _buildNavItem('Sistem', Icons.settings_suggest_rounded, 'system'),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 12),
        _buildNavItem('Tentang', Icons.info_rounded, 'about'),
      ],
    );
  }

  Widget _buildNavItem(String title, IconData icon, String value) {
    final isSelected = _selectedTab == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF111827))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentByTab() {
    switch (_selectedTab) {
      case 'profile': return _buildProfileContent();
      case 'security': return _buildSecurityContent();
      case 'notification': return _buildNotificationContent();
      case 'system': return _buildSystemContent();
      case 'about': return _buildAboutContent();
      default: return _buildProfileContent();
    }
  }

  // PROFILE
  Widget _buildProfileContent() {
    final adminProvider = context.watch<AdminProvider>();
    final admin = adminProvider.currentAdmin;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCard(
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: const Icon(Icons.person_rounded, size: 40, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 20),
            _buildTextField('Nama', admin?.nama ?? 'Super Admin'),
            const SizedBox(height: 12),
            _buildTextField('Email', admin?.email ?? 'admin@sidrive.com'),
            const SizedBox(height: 12),
            _buildTextField('Role', 'Super Administrator', enabled: false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SECURITY
  Widget _buildSecurityContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Ganti Password',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update password secara berkala untuk keamanan.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePasswordDialog(),
                    icon: const Icon(Icons.lock_reset_rounded, size: 16),
                    label: const Text('Ganti Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Two-Factor Authentication',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2FA Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      SizedBox(height: 2),
                      Text('Akun dilindungi 2FA', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Switch(value: true, onChanged: (v) {}, activeColor: const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOTIFICATION
  Widget _buildNotificationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCard(
        title: 'Notifikasi Email',
        child: Column(
          children: [
            _buildToggle('Verifikasi Driver Baru', true),
            _buildToggle('Verifikasi UMKM Baru', true),
            _buildToggle('Penarikan Saldo', true),
            _buildToggle('Laporan Harian', false),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String title, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
          Switch(value: value, onChanged: (v) {}, activeColor: const Color(0xFF6366F1)),
        ],
      ),
    );
  }

  // SYSTEM
  Widget _buildSystemContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Tampilan',
            child: _buildSystemOption('Bahasa', 'Bahasa Indonesia', Icons.language_rounded),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Danger Zone',
            isError: true,
            child: _buildSystemOption('Logout', 'Keluar dari akun', Icons.logout_rounded, isError: true, onTap: () => _showLogoutDialog()),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOption(String title, String subtitle, IconData icon, {bool isError = false, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isError ? const Color(0xFFEF4444) : const Color(0xFF6366F1)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isError ? const Color(0xFFEF4444) : const Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ABOUT
  Widget _buildAboutContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildCard(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('SiDrive Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Version 1.0.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Developer', 'Team SiDrive'),
            _buildInfoRow('Build Date', '04 Januari 2026'),
            _buildInfoRow('Contact', 'admin@sidrive.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
        ],
      ),
    );
  }

  // HELPERS
  Widget _buildCard({String? title, required Widget child, bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isError ? const Color(0xFFEF4444).withOpacity(0.3) : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isError ? const Color(0xFFEF4444) : const Color(0xFF111827))),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFE5E7EB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  // DIALOGS
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Fitur edit profile akan segera tersedia.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Password Lama', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Simpan')),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/admin/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
} 