// lib/screens/page/profile_driver_utils.dart
// ============================================================================
// PROFILE DRIVER UTILITIES - Helper functions untuk Driver features
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDriverUtils {
  // =========================================================================
  // GET DRIVER VEHICLES INFO
  // =========================================================================
  static Future<Map<String, dynamic>> getDriverVehiclesInfo(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId == null) return <String, dynamic>{
        'hasMotor': false,
        'hasMobil': false,
        'motorApproved': false,
        'mobilApproved': false,
        'activeVehicle': 'motor',
        'jenisKendaraan': 'Belum diatur',
      };
      
      final supabase = Supabase.instance.client;
      
      // Get driver ID
      final driverData = await supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (driverData == null) return <String, dynamic>{
        'hasMotor': false,
        'hasMobil': false,
        'motorApproved': false,
        'mobilApproved': false,
        'activeVehicle': 'motor',
        'jenisKendaraan': 'Belum diatur',
      };
      
      final idDriver = driverData['id_driver'];
      
      // Get vehicles
      final vehicles = await supabase
          .from('driver_vehicles')
          .select('jenis_kendaraan, status_verifikasi, is_active, merk_kendaraan, plat_nomor')
          .eq('id_driver', idDriver);
      
      bool hasMotor = false;
      bool hasMobil = false;
      bool motorApproved = false;
      bool mobilApproved = false;
      String activeVehicle = 'motor';
      String jenisKendaraan = 'Belum diatur';
      
      for (var v in vehicles) {
        final jenis = v['jenis_kendaraan'] as String;
        final status = v['status_verifikasi'] as String;
        final isActive = v['is_active'] as bool? ?? false;
        
        if (jenis == 'motor') {
          hasMotor = true;
          if (status == 'approved') motorApproved = true;
          if (isActive) {
            activeVehicle = 'motor';
            jenisKendaraan = '${v['merk_kendaraan']} (${v['plat_nomor']})';
          }
        } else if (jenis == 'mobil') {
          hasMobil = true;
          if (status == 'approved') mobilApproved = true;
          if (isActive) {
            activeVehicle = 'mobil';
            jenisKendaraan = '${v['merk_kendaraan']} (${v['plat_nomor']})';
          }
        }
      }
      
      return <String, dynamic>{
        'hasMotor': hasMotor,
        'hasMobil': hasMobil,
        'motorApproved': motorApproved,
        'mobilApproved': mobilApproved,
        'activeVehicle': activeVehicle,
        'jenisKendaraan': jenisKendaraan,
      };
    } catch (e) {
      debugPrint('❌ Error getting vehicle info: $e');
      return {
        'hasMotor': false,
        'hasMobil': false,
        'motorApproved': false,
        'mobilApproved': false,
        'activeVehicle': 'motor',
        'jenisKendaraan': 'Belum diatur',
      };
    }
  }
  
  // =========================================================================
  // CHECK DRIVER VEHICLE STATUS
  // =========================================================================
  static Future<Map<String, bool>> checkDriverVehicleStatus(BuildContext context) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId == null) return <String, bool>{'hasMotor': false, 'hasMobil': false};
      
      final supabase = Supabase.instance.client;
      
      final driverData = await supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', userId)
          .maybeSingle();
      
      if (driverData == null) return <String, bool>{'hasMotor': false, 'hasMobil': false};
      
      final vehicles = await supabase
          .from('driver_vehicles')
          .select('jenis_kendaraan')
          .eq('id_driver', driverData['id_driver']);
      
      bool hasMotor = false;
      bool hasMobil = false;
      
      for (var v in vehicles) {
        if (v['jenis_kendaraan'] == 'motor') hasMotor = true;
        if (v['jenis_kendaraan'] == 'mobil') hasMobil = true;
      }
      
      return <String, bool>{'hasMotor': hasMotor, 'hasMobil': hasMobil};
    } catch (e) {
      return {'hasMotor': false, 'hasMobil': false};
    }
  }
  
  // =========================================================================
  // SWITCH ACTIVE VEHICLE
  // =========================================================================
  static Future<void> switchActiveVehicle(BuildContext context, String newVehicle) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.idUser;
      
      if (userId == null) return;
      
      final supabase = Supabase.instance.client;
      
      // Get driver ID
      final driverData = await supabase
          .from('drivers')
          .select('id_driver')
          .eq('id_user', userId)
          .single();
      
      final idDriver = driverData['id_driver'];
      
      // Set semua is_active = false
      await supabase
          .from('driver_vehicles')
          .update({'is_active': false})
          .eq('id_driver', idDriver);
      
      // Set yang dipilih is_active = true
      await supabase
          .from('driver_vehicles')
          .update({'is_active': true})
          .eq('id_driver', idDriver)
          .eq('jenis_kendaraan', newVehicle);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Berhasil beralih ke ${newVehicle == 'motor' ? 'Motor' : 'Mobil'}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 🔥 FIX BENAR: Update AuthProvider driverData
        authProvider.updateActiveVehicle(
          activeVehicle: newVehicle,
          jenisKendaraan: newVehicle == 'motor'
              ? 'Motor'
              : 'Mobil',
        );
      }
    } catch (e) {
      debugPrint('❌ Error switching vehicle: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal beralih kendaraan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}