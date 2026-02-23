import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? driverData;

  const ProfilePage({Key? key, this.driverData}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  bool _isSwitching = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark(context);
    
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(isDark),
            const SizedBox(height: 16),
            _buildVehicleSection(isDark), // ✅ TOGGLE SECTION BARU!
            const SizedBox(height: 16),
            _buildInfoCard(isDark),
            const SizedBox(height: 16),
            _buildMenuSection(context, isDark),
            const SizedBox(height: 16),
            _buildLogoutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.driverData?['foto_profil'] != null
                    ? NetworkImage(widget.driverData!['foto_profil'])
                    : null,
                child: widget.driverData?['foto_profil'] == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.driverData?['nama'] ?? 'Driver',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.driverData?['no_telp'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge('Rating', '5.0', Icons.star),
              const SizedBox(width: 20),
              _buildStatBadge('Trip', '0', Icons.local_shipping),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ SECTION BARU: TOGGLE KENDARAAN!
  Widget _buildVehicleSection(bool isDark) {
    final vehicles = widget.driverData?['vehicles'] as List?;
    final activeVehicleType = widget.driverData?['active_vehicle_type'] as String?;
    
    if (vehicles == null || vehicles.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Kendaraan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daftarkan kendaraan Anda untuk mulai bekerja',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/request-driver-role');
              },
              icon: const Icon(Icons.add),
              label: const Text('Daftar Kendaraan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Jika hanya 1 kendaraan
    if (vehicles.length == 1) {
      final vehicle = vehicles.first;
      return _buildSingleVehicleCard(vehicle, isDark);
    }

    // Jika 2 kendaraan (Motor & Mobil) - SHOW TOGGLE!
    return _buildVehicleToggleCard(vehicles, activeVehicleType, isDark);
  }

  Widget _buildSingleVehicleCard(Map<String, dynamic> vehicle, bool isDark) {
    final isMotor = vehicle['jenis_kendaraan'] == 'motor';
    final color = isMotor ? Colors.green : Colors.blue;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isMotor ? Icons.two_wheeler : Icons.directions_car,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kendaraan Anda',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${vehicle['jenis_kendaraan'].toString().toUpperCase()} - ${vehicle['plat_nomor']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  'APPROVED',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVehicleDetailRow(
            Icons.badge,
            'Merk',
            vehicle['merk_kendaraan'] ?? '-',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildVehicleDetailRow(
            Icons.palette,
            'Warna',
            vehicle['warna_kendaraan'] ?? '-',
            isDark,
          ),
        ],
      ),
    );
  }

  // ✅ TOGGLE CARD UNTUK 2 KENDARAAN!
  Widget _buildVehicleToggleCard(List vehicles, String? activeVehicleType, bool isDark) {
    final motorVehicle = vehicles.firstWhere(
      (v) => v['jenis_kendaraan'] == 'motor',
      orElse: () => null,
    );
    final mobilVehicle = vehicles.firstWhere(
      (v) => v['jenis_kendaraan'] == 'mobil',
      orElse: () => null,
    );

    final isMotorActive = activeVehicleType == 'motor';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Kendaraan Aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pesanan akan disesuaikan dengan kendaraan yang dipilih',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          
          // ✅ TOGGLE SWITCH KEREN!
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background
                Container(
                  width: 280,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                // Animated slider
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: isMotorActive ? 5 : 145,
                  child: Container(
                    width: 130,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMotorActive
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: (isMotorActive ? Colors.green : Colors.blue).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                // Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      label: 'MOTOR',
                      icon: Icons.two_wheeler,
                      isActive: isMotorActive,
                      onTap: motorVehicle != null
                          ? () => _switchVehicle('motor')
                          : null,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildToggleButton(
                      label: 'MOBIL',
                      icon: Icons.directions_car,
isActive: !isMotorActive,
onTap: mobilVehicle != null
? () => _switchVehicle('mobil')
: null,
isDark: isDark,
),
],
),
],
),
),
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 16),
      
      // Detail kendaraan yang aktif
      Text(
        'Detail Kendaraan Aktif',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      const SizedBox(height: 12),
      
      if (isMotorActive && motorVehicle != null)
        _buildActiveVehicleDetails(motorVehicle, true, isDark)
      else if (!isMotorActive && mobilVehicle != null)
        _buildActiveVehicleDetails(mobilVehicle, false, isDark),
    ],
  ),
);
}
Widget _buildToggleButton({
required String label,
required IconData icon,
required bool isActive,
required VoidCallback? onTap,
required bool isDark,
}) {
return GestureDetector(
onTap: _isSwitching ? null : onTap,
child: Container(
width: 130,
height: 50,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(25),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
icon,
color: isActive ? Colors.white : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
size: 20,
),
const SizedBox(width: 8),
Text(
label,
style: TextStyle(
color: isActive ? Colors.white : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
fontSize: 13,
fontWeight: FontWeight.bold,
letterSpacing: 0.5,
),
),
],
),
),
);
}
Widget _buildActiveVehicleDetails(Map<String, dynamic> vehicle, bool isMotor, bool isDark) {
final color = isMotor ? Colors.green : Colors.blue;
return Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: color.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withOpacity(0.2)),
  ),
  child: Column(
    children: [
      _buildVehicleDetailRow(
        Icons.badge,
        'Plat Nomor',
        vehicle['plat_nomor'] ?? '-',
        isDark,
      ),
      const SizedBox(height: 8),
      _buildVehicleDetailRow(
        Icons.directions_car,
        'Merk',
        vehicle['merk_kendaraan'] ?? '-',
        isDark,
      ),
      const SizedBox(height: 8),
      _buildVehicleDetailRow(
        Icons.palette,
        'Warna',
        vehicle['warna_kendaraan'] ?? '-',
        isDark,
      ),
    ],
  ),
);
}
Widget _buildVehicleDetailRow(IconData icon, String label, String value, bool isDark) {
return Row(
children: [
Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
const SizedBox(width: 8),
Text(
'$label:',
style: TextStyle(
fontSize: 13,
color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
value,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: isDark ? Colors.white : Colors.black87,
),
),
),
],
);
}
// ✅ SWITCH VEHICLE FUNCTION
Future<void> _switchVehicle(String newVehicleType) async {
if (_isSwitching) return;
setState(() => _isSwitching = true);

try {
  final driverId = widget.driverData?['id_driver'];
  
  await supabase.from('drivers').update({
    'active_vehicle_type': newVehicleType,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id_driver', driverId);

  if (mounted) {
    setState(() {
      widget.driverData!['active_vehicle_type'] = newVehicleType;
      _isSwitching = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Kendaraan aktif diubah ke ${newVehicleType.toUpperCase()}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Refresh dashboard
    Navigator.pushReplacementNamed(context, '/driver/dashboard');
  }
} catch (e) {
  if (mounted) {
    setState(() => _isSwitching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Gagal mengubah kendaraan: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}
Widget _buildInfoCard(bool isDark) {
return Container(
margin: const EdgeInsets.symmetric(horizontal: 16),
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: isDark ? Colors.grey.shade800 : Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 2),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Informasi Akun',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: isDark ? Colors.white : Colors.black87,
),
),
const SizedBox(height: 16),
_buildInfoRow(
Icons.email,
'Email',
widget.driverData?['email'] ?? 'Belum diatur',
isDark,
),
const Divider(height: 24),
_buildInfoRow(
Icons.badge,
'NIM',
widget.driverData?['nim'] ?? 'Belum diatur',
isDark,
),
],
),
);
}
Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
return Row(
children: [
Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(10),
),
child: Icon(icon, color: Colors.blue, size: 20),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: TextStyle(
fontSize: 12,
color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
),
),
const SizedBox(height: 2),
Text(
value,
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w600,
color: isDark ? Colors.white : Colors.black87,
),
),
],
),
),
],
);
}
Widget _buildMenuSection(BuildContext context, bool isDark) {
return Container(
margin: const EdgeInsets.symmetric(horizontal: 16),
decoration: BoxDecoration(
color: isDark ? Colors.grey.shade800 : Colors.white,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 10,
offset: const Offset(0, 2),
),
],
),
child: Column(
children: [
_buildMenuItem(
context,
Icons.add_circle,
'Daftar Kendaraan Baru',
Colors.green,
() {
Navigator.pushNamed(context, '/request-driver-role');
},
isDark,
),
const Divider(height: 1),
_buildMenuItem(
context,
Icons.edit,
'Edit Profile',
Colors.blue,
() {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Fitur akan segera hadir')),
);
},
isDark,
),
const Divider(height: 1),
_buildMenuItem(
context,
Icons.lock,
'Ubah Password',
Colors.orange,
() {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Fitur akan segera hadir')),
);
},
isDark,
),
const Divider(height: 1),
_buildMenuItem(
context,
Icons.help_outline,
'Bantuan',
Colors.purple,
() {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Fitur akan segera hadir')),
);
},
isDark,
),
],
),
);
}
Widget _buildMenuItem(
BuildContext context,
IconData icon,
String title,
Color color,
VoidCallback onTap,
bool isDark,
) {
return InkWell(
onTap: onTap,
child: Padding(
padding: const EdgeInsets.all(16),
child: Row(
children: [
Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius: BorderRadius.circular(10),
),
child: Icon(icon, color: color, size: 22),
),
const SizedBox(width: 16),
Expanded(
child: Text(
title,
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w500,
color: isDark ? Colors.white : Colors.black87,
),
),
),
Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
],
),
),
);
}
Widget _buildLogoutButton(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
onPressed: () => _handleLogout(context),
icon: const Icon(Icons.logout),
label: const Text(
'Keluar',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
),
);
}
Future<void> _handleLogout(BuildContext context) async {
final confirm = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: const Text('Keluar'),
content: const Text('Apakah Anda yakin ingin keluar?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Batal'),
),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(8),
),
),
child: const Text('Ya, Keluar'),
),
],
),
);
if (confirm == true && context.mounted) {
  try {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
}
}