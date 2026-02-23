// lib/screens/customer/umkm/umkm_delivery_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sidrive/core/utils/error_dialog_utils.dart';

/// Screen untuk customer pilih lokasi pengiriman UMKM
/// - Drop pin di map
/// - Search lokasi
/// - Bisa gunakan lokasi sekarang
class UmkmDeliveryMapScreen extends StatefulWidget {
  final LatLng tokoLocation; // Lokasi toko UMKM
  final String tokoName; // Nama toko

  const UmkmDeliveryMapScreen({
    Key? key,
    required this.tokoLocation,
    required this.tokoName,
  }) : super(key: key);

  @override
  State<UmkmDeliveryMapScreen> createState() => _UmkmDeliveryMapScreenState();
}

class _UmkmDeliveryMapScreenState extends State<UmkmDeliveryMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;
  StreamSubscription<MapEvent>? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    
    // Default lokasi di toko
    _selectedLocation = widget.tokoLocation;
    
    // Listen map movement
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        final center = _mapController.camera.center;
        if (_selectedLocation != center) {
          setState(() {
            _selectedLocation = center;
          });
          _getAddressFromLatLng(center);
        }
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif. Mohon aktifkan GPS Anda.');
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Mohon aktifkan di pengaturan.');
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_selectedLocation!, 17.0);
      await _getAddressFromLatLng(_selectedLocation!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi Anda berhasil didapatkan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialogUtils.showWarningDialog(
          context: context,
          title: 'Error Lokasi',
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
        headers: {'User-Agent': 'SiDrive-Customer/1.0'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Alamat tidak ditemukan';
          // Update search field jika tidak sedang mengetik
          if (!_searchController.text.startsWith(_selectedAddress.substring(0, 5))) {
            _searchController.text = _selectedAddress;
          }
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
          '&countrycodes=id&bounded=1'
          '&viewbox=112.5,-7.6,112.9,-7.2'; // Fokus di area Surabaya

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SiDrive-Customer/1.0'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

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

  // Konfirmasi lokasi
  void _confirmLocation() {
    if (_selectedLocation == null) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Error',
        message: 'Pilih lokasi pengiriman terlebih dahulu',
      );
      return;
    }

    if (_selectedAddress.isEmpty) {
      ErrorDialogUtils.showWarningDialog(
        context: context,
        title: 'Error',
        message: 'Alamat belum terdeteksi. Tunggu sebentar...',
      );
      return;
    }

    // Return data ke checkout screen
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi Pengiriman'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.tokoLocation,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sidrive.customer',
              ),

              // Marker toko
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.tokoLocation,
                    width: 40,
                    height: 40,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.tokoName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.store,
                          color: Colors.orange,
                          size: 28,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Center pin (lokasi pengiriman)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lokasi Pengiriman',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.blue.shade600,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                        hintText: 'Cari lokasi pengiriman...',
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _showSearchResults = false);
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
                          leading: Icon(Icons.location_on, color: Colors.blue),
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

          // Address info & hint
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
                        Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Geser peta untuk pilih lokasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 16),
                    Row(
                      children: [
                        Icon(Icons.place, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress.isEmpty 
                                ? 'Mendeteksi alamat...'
                                : _selectedAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              fontWeight: _selectedAddress.isNotEmpty 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                  elevation: 4,
                  child: _isLoadingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                        )
                      : Icon(Icons.my_location, color: Colors.blue),
                ),
                SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Konfirmasi Lokasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
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