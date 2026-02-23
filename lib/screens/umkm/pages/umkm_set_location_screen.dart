// lib/screens/umkm/umkm_set_location_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/core/utils/error_dialog_utils.dart';

/// Screen untuk UMKM set lokasi toko mereka
/// - Drop pin di map
/// - Search lokasi
/// - Simpan ke database sebagai POINT geometry
class UmkmSetLocationScreen extends StatefulWidget {
  final String idUmkm;
  final String? currentAddress; // Alamat toko yang sudah ada
  final LatLng? currentLocation; // Lokasi existing (kalau ada)

  const UmkmSetLocationScreen({
    Key? key,
    required this.idUmkm,
    this.currentAddress,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<UmkmSetLocationScreen> createState() => _UmkmSetLocationScreenState();
}

class _UmkmSetLocationScreenState extends State<UmkmSetLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;

  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    // Gunakan lokasi existing kalau ada
    if (widget.currentLocation != null) {
      _selectedLocation = widget.currentLocation;
      _selectedAddress = widget.currentAddress ?? '';
      _searchController.text = _selectedAddress;
    } else {
      // Default ke Surabaya
      _selectedLocation = LatLng(-7.4479, 112.7186);
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif');
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_selectedLocation!, 17.0);
      await _getAddressFromLatLng(_selectedLocation!);
    } catch (e) {
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error',
          message: e.toString(),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // Get address from coordinates
  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?'
          'format=json&lat=${location.latitude}&lon=${location.longitude}'
          '&addressdetails=1&accept-language=id';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SiDrive-UMKM/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!mounted) return;

        setState(() {
          _selectedAddress = data['display_name'] ?? 'Alamat tidak ditemukan';
          _searchController.text = _selectedAddress;
        });
      }
    } catch (e) {
      print('❌ Error get address: $e');
    }
  }

  // Search places
  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    final query = _searchController.text;

    if (query.isEmpty || query.length < 3) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/search?'
          'q=$query&format=json&addressdetails=1&limit=10&accept-language=id'
          '&countrycodes=id';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SiDrive-UMKM/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (!mounted) return;

        setState(() {
          _searchResults = data.map((item) => {
            'name': item['name'] ?? item['display_name'],
            'displayName': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          }).toList();
          _showSearchResults = _searchResults.isNotEmpty;
        });
      }
    } catch (e) {
      print('❌ Error search: $e');
    }
  }

  void _selectSearchResult(Map<String, dynamic> place) {
    setState(() {
      _selectedLocation = LatLng(place['lat'], place['lon']);
      _selectedAddress = place['displayName'];
      _searchController.text = _selectedAddress;
      _showSearchResults = false;
      _searchResults = [];
    });

    _mapController.move(_selectedLocation!, 17.0);
  }

  // Update lokasi saat map digeser
  void _onMapMoved(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final center = _mapController.camera.center;
      if (_selectedLocation != center) {
        setState(() {
          _selectedLocation = center;
        });
        _getAddressFromLatLng(center);
      }
    }
  }

  // Save location to database
  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Error',
        message: 'Pilih lokasi toko terlebih dahulu',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Format POINT geometry untuk PostGIS
      final pointGeometry = 'POINT(${_selectedLocation!.longitude} ${_selectedLocation!.latitude})';

      // ✅ FIX: Update KEDUA kolom (lokasi_toko DAN alamat_toko_lengkap)
      await _supabase
          .from('umkm')
          .update({
            'lokasi_toko': pointGeometry,
            'alamat_toko_lengkap': _selectedAddress, // ← TAMBAH INI!
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id_umkm', widget.idUmkm);

      if (mounted) { // ← Cek mounted juga di sini
        await ErrorDialogUtils.showSuccessDialog(
          context: context,
          title: 'Berhasil!',
          message: 'Lokasi toko berhasil disimpan',
          actionText: 'OK',
        );

        Navigator.pop(context, {
          'location': _selectedLocation,
          'address': _selectedAddress,
        });
      }
    } catch (e) {
      if (mounted) { // ← Dan di sini
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error',
          message: 'Gagal menyimpan lokasi: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) { // ← Dan di sini juga
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Lokasi Toko'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? LatLng(-7.4479, 112.7186),
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapEvent: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sidrive.umkm',
              ),
            ],
          ),

          // Center pin
          Center(
            child: Icon(
              Icons.location_on,
              size: 50,
              color: Colors.red.shade600,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi...',
                        prefixIcon: Icon(Icons.search, color: Colors.orange),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _showSearchResults = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Search results
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on, color: Colors.orange),
                          title: Text(
                            place['name'],
                            style: TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            place['displayName'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () => _selectSearchResult(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Address info at bottom
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Lokasi Toko',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _selectedAddress.isEmpty 
                          ? 'Geser peta untuk pilih lokasi'
                          : _selectedAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // My location button
                FloatingActionButton(
                  heroTag: 'myLocation',
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location, color: Colors.orange),
                ),
                SizedBox(width: 12),

                // Save button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Simpan Lokasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}