import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';

class UmkmMapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const UmkmMapPicker({
    Key? key,
    this.initialLocation,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<UmkmMapPicker> createState() => _UmkmMapPickerState();
}

class _UmkmMapPickerState extends State<UmkmMapPicker> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? LatLng(-7.4479, 112.7186);
    _selectedAddress = widget.initialAddress ?? '';
    
    // Jika belum ada lokasi, ambil current location
    if (widget.initialLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
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
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    
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
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Alamat tidak ditemukan';
        });
      }
    } catch (e) {
      debugPrint('Error get address: $e');
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapMoved() {
    final center = _mapController.camera.center;
    if (_selectedLocation != center) {
      setState(() {
        _selectedLocation = center;
      });
      _getAddressFromLatLng(center);
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'location': _selectedLocation,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Lokasi Toko'),
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
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _onMapMoved();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sidrive.umkm',
              ),
            ],
          ),

          // Center pin
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 50,
                        color: Colors.orange.shade600,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Address info
          Positioned(
            top: 16,
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
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Geser peta untuk pilih lokasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedAddress.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(
                        'Alamat:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _isLoadingAddress ? 'Memuat alamat...' : _selectedAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: Colors.orange),
                ),
                SizedBox(width: 12),

                // Confirm button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingAddress ? null : _confirmLocation,
                    icon: Icon(Icons.check_circle, size: 20),
                    label: Text(
                      'Konfirmasi Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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