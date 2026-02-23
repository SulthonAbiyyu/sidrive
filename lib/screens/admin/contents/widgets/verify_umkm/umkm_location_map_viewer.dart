import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// ============================================================================
/// UMKM LOCATION MAP VIEWER
/// Widget untuk admin melihat lokasi toko UMKM di halaman verifikasi
/// Features:
/// - Maps dengan marker lokasi toko
/// - Zoom controls
/// - Recenter button
/// - Info card lokasi toko
/// ============================================================================

class UmkmLocationMapViewer extends StatefulWidget {
  final LatLng tokoLocation;
  final String tokoName;
  final String tokoAddress;

  const UmkmLocationMapViewer({
    Key? key,
    required this.tokoLocation,
    required this.tokoName,
    required this.tokoAddress,
  }) : super(key: key);

  @override
  State<UmkmLocationMapViewer> createState() => _UmkmLocationMapViewerState();
}

class _UmkmLocationMapViewerState extends State<UmkmLocationMapViewer> {
  final MapController _mapController = MapController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Lokasi Toko',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.tokoLocation,
              initialZoom: 16.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sidrive.app',
                maxZoom: 19,
              ),
              
              // Store Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.tokoLocation,
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 8,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Store Info Card (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.tokoName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 20, color: Color(0xFFE5E7EB)),
                    
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.tokoAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Coordinates
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pin_drop_rounded,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.tokoLocation.latitude.toStringAsFixed(6)}, ${widget.tokoLocation.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons (Bottom Right)
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter Button
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(widget.tokoLocation, 16.0);
                  },
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Zoom In Button
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Zoom Out Button
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                  child: const Icon(
                    Icons.remove_rounded,
                    color: Color(0xFF2563EB),
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