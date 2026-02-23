import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

class MapRouteOrder extends StatefulWidget {
  final LatLng? currentPosition;
  final LatLng? destinationPosition;
  final List<LatLng> routePoints;
  final VoidCallback? onMyLocationPressed;
  final Function(LatLng)? onMapMoved;
  final bool isDropPinMode;
  final LatLng centerPoint;
  final double radiusKm;

  const MapRouteOrder({
    Key? key,
    this.currentPosition,
    this.destinationPosition,
    this.routePoints = const [],
    this.onMyLocationPressed,
    this.onMapMoved,
    this.isDropPinMode = false,
    required this.centerPoint,
    required this.radiusKm,
  }) : super(key: key);

  @override
  State<MapRouteOrder> createState() => MapRouteOrderState();
}

class MapRouteOrderState extends State<MapRouteOrder> {
  final MapController _mapController = MapController();
  StreamSubscription<MapEvent>? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      if (widget.isDropPinMode && 
          widget.onMapMoved != null && 
          event is MapEventMove) {
        widget.onMapMoved!(_mapController.camera.center);
      }
    });
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  void moveToLocation(LatLng location, double zoom) {
    _mapController.move(location, zoom);
  }

  void fitBounds(LatLngBounds bounds, EdgeInsets padding) {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: padding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.currentPosition ?? widget.centerPoint,
            initialZoom: 12.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sidrive.app',
            ),

            // ✅ LINGKARAN TUNGGAL - AREA LAYANAN
            CircleLayer(
              circles: [
                CircleMarker(
                  point: widget.centerPoint,
                  radius: widget.radiusKm * 1000, // 30km = 30000 meter
                  useRadiusInMeter: true,
                  color: Color(0xFF4285F4).withOpacity(0.15),
                  borderColor: Color(0xFF4285F4),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            
            // Route polyline (hide saat drop pin mode)
            if (widget.routePoints.isNotEmpty && !widget.isDropPinMode)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints,
                    strokeWidth: 5.0,
                    color: Color(0xFF4285F4),
                  ),
                ],
              ),
            
            // Markers (hide saat drop pin mode)
            if (!widget.isDropPinMode)
              MarkerLayer(
                markers: [
                  // ✅ MARKER PUSAT AREA LAYANAN (FIX OVERFLOW)
                  Marker(
                    point: widget.centerPoint,
                    width: 150, // ✅ Lebih lebar untuk text panjang
                    height: 90, // ✅ Lebih tinggi agar tidak overflow
                    alignment: Alignment.center, // ✅ PENTING: Center alignment
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center, // ✅ Center vertical
                      children: [
                        // Label
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          constraints: BoxConstraints(maxWidth: 140), // ✅ Batasi lebar
                          decoration: BoxDecoration(
                            color: Color(0xFF4285F4),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Area Layanan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Radius ${widget.radiusKm.toInt()} km',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        // Icon
                        Icon(
                          Icons.location_city,
                          color: Color(0xFF4285F4),
                          size: 26,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // MARKER PICKUP
                  if (widget.currentPosition != null)
                    Marker(
                      point: widget.currentPosition!,
                      width: 40.w,
                      height: 40.h,
                      alignment: Alignment.center, // ✅ Center alignment
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 12.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: Color(0xFF4285F4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // MARKER DESTINATION
                  if (widget.destinationPosition != null)
                    Marker(
                      point: widget.destinationPosition!,
                      width: 40.w,
                      height: 40.h,
                      alignment: Alignment.center, // ✅ Center alignment
                      child: Icon(
                        Icons.location_on,
                        color: Color(0xFFEA4335),
                        size: 40.sp,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}