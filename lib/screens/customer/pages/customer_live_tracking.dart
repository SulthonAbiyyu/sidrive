import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sidrive/services/customer_location_service.dart';
import 'package:sidrive/screens/customer/pages/maproute_customer.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_data_loader.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_dialogs.dart';
import 'package:sidrive/screens/customer/pages/customer_tracking_widgets.dart';
import 'package:sidrive/services/driver_tracking_service.dart';
import 'package:sidrive/screens/chat/chat_room_page.dart';
import 'package:sidrive/services/chat_service.dart';
import 'package:sidrive/models/chat_models.dart';

class CustomerLiveTracking extends StatefulWidget {
  final String idPesanan;
  final Map<String, dynamic> pesananData;

  const CustomerLiveTracking({
    Key? key,
    required this.idPesanan,
    required this.pesananData,
  }) : super(key: key);

  @override
  State<CustomerLiveTracking> createState() => _CustomerLiveTrackingState();
}

class _CustomerLiveTrackingState extends State<CustomerLiveTracking> {
  final supabase = Supabase.instance.client;
  final _customerLocationService = CustomerLocationService();
  final GlobalKey<MapRouteCustomerState> _mapKey = GlobalKey<MapRouteCustomerState>();
  
  // Data State
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _pengirimanData;
  LatLng? _driverLocation;
  LatLng? _customerLocation;
  
  // UI State
  String _currentStatus = 'diterima';
  bool _isPanelMinimized = false;
  bool _hasShownCompletionDialog = false;
  final _chatService = ChatService();
  
  // ✅ NEW: Detect if this is UMKM order
  bool _isUmkm = false;
  
  // Streams & Timers
  StreamSubscription? _pengirimanStream;
  Timer? _locationUpdateTimer;

  // Data Loader & Dialog Manager instances
  late CustomerTrackingDataLoader _dataLoader;
  late CustomerTrackingDialogs _dialogManager;
  final _trackingService = DriverTrackingService();

  @override
  void initState() {
    super.initState();
    
    // ✅ RESET FLAG DI SINI - PENTING UNTUK ORDER BARU!
    _hasShownCompletionDialog = false;
    
    // ✅ Detect if UMKM order
    _isUmkm = widget.pesananData['jenis'] == 'umkm';
    
    print('🔄 [CustomerTracking] initState called');
    print('🔄 [CustomerTracking] Order Type: ${_isUmkm ? "UMKM" : "OJEK"}');
    print('🔄 [CustomerTracking] Dialog flag reset to: $_hasShownCompletionDialog');
    
    // Initialize helpers
    _dataLoader = CustomerTrackingDataLoader(
      context: context,
      widget: widget,
      supabase: supabase,
      customerLocationService: _customerLocationService,
      onDriverDataLoaded: (data) {
        if (mounted) setState(() => _driverData = data);
      },
      onPengirimanDataLoaded: (data) {
        if (mounted) setState(() => _pengirimanData = data);
      },
      onDriverLocationUpdated: (location) {
        if (mounted) setState(() => _driverLocation = location);
      },
      onCustomerLocationUpdated: (location) {
        if (mounted) setState(() => _customerLocation = location);
      },
      onStatusUpdated: (status) {
        if (mounted) {
          setState(() => _currentStatus = status);
          WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapKey.currentState?.updateRoute();
        });
          
          print('📊 [CustomerTracking] Status updated to: $status');
        }
      },
      onOrderCompleted: () {
        // ✅ DOUBLE CHECK DENGAN FLAG
        if (!_hasShownCompletionDialog) {
          print('🎉 [CustomerTracking] Order completed - showing dialog');
          _hasShownCompletionDialog = true;
          _onOrderCompleted();
        } else {
          print('⚠️ [CustomerTracking] Dialog already shown, skipping');
        }
      },
      onStreamCreated: (stream) {
        _pengirimanStream = stream;
      },
      onTimerCreated: (timer) {
        _locationUpdateTimer = timer;
      },
    );

    _dialogManager = CustomerTrackingDialogs(
      context: context,
      widget: widget,
      supabase: supabase,
      getPengirimanData: () => _pengirimanData,
    );

    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    print('🗺️ ========== INIT LIVE TRACKING ==========');
    print('🗺️ Pesanan ID: ${widget.idPesanan}');
    print('🗺️ Dialog Flag: $_hasShownCompletionDialog');
    
    await _dataLoader.loadDriverAndPengiriman();
    _dataLoader.listenPengirimanUpdates();
    _dataLoader.startDriverLocationUpdates();
    _dataLoader.startCustomerLocationTracking();
    
    // ✅ START TRACKING SERVICE (MASIH DALAM FUNGSI)
    if (_pengirimanData != null) {
      final pengirimanId = _pengirimanData!['id_pengiriman'];
      final driverId = _pengirimanData!['id_driver'];
      
      if (pengirimanId != null && driverId != null) {
        _trackingService.startTracking(
          idPengiriman: pengirimanId,
          idDriver: driverId,
        );
        print('✅ Tracking service started');
      }
    }
  }

  void _onOrderCompleted() {
    print('🎉 ========== ORDER COMPLETED ==========');
    print('🎉 Order Type: ${_isUmkm ? "UMKM" : "OJEK"}');
    print('🎉 Stopping all tracking services...');
    
    _locationUpdateTimer?.cancel();
    _customerLocationService.stopTracking();
    
    if (!mounted) {
      print('⚠️ Widget not mounted, skipping dialog');
      return;
    }
    
    // ✅ LOGIC BARU: Cek jenis pesanan
    if (_isUmkm) {
      // ✅ UMKM: Langsung ke riwayat, SKIP rating dialog
      print('📦 UMKM Order - Skip rating, direct to history');
      
      // Show completion dialog (tanpa rating)
      _dialogManager.showCompletionDialog();
      
    } else {
      // ✅ OJEK: Tampilkan rating dialog seperti biasa
      print('🏍️ OJEK Order - Show rating dialog');
      _dialogManager.showRatingDialog();
    }
  }

  @override
  void dispose() {
    print('🧹 ========== DISPOSING CUSTOMER TRACKING ==========');
    print('🧹 Pesanan ID: ${widget.idPesanan}');
    
    _pengirimanStream?.cancel();
    _locationUpdateTimer?.cancel();
    _customerLocationService.stopTracking();
    _trackingService.stopTracking();
    _hasShownCompletionDialog = false;
    
    print('✅ All resources cleaned up');
    
    super.dispose();
  }

  Future<void> _openChat() async {
    if (_driverData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data driver belum tersedia')),
      );
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id;
      final driverId = _driverData!['id_user'];

      if (userId == null || driverId == null) {
        throw Exception('User ID atau Driver ID tidak ditemukan');
      }

      // Create or get chat room
      final room = await _chatService.createOrGetRoom(
        context: ChatContext.customerDriver,
        participantIds: [userId, driverId],
        participantRoles: {
          userId: 'customer',
          driverId: 'driver',
        },
        orderId: widget.idPesanan,
      );

      if (room == null) {
        throw Exception('Gagal membuat chat room');
      }

      if (!mounted) return;

      // Navigate ke chat room
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            roomId: room.id,
            room: room,
            currentUserId: userId,
            currentUserRole: 'customer',
          ),
        ),
      );
    } catch (e) {
      print('❌ Error opening chat: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    print('🔨 BUILD DEBUG:');
    print('  - driverData: ${_driverData != null ? "✅ Ada" : "❌ Null"}');
    print('  - driverLocation: ${_driverLocation != null ? "✅ Ada" : "❌ Null"}');
    print('  - currentStatus: $_currentStatus');
    print('  - dialogFlag: $_hasShownCompletionDialog');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _driverData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_driverData == null 
                    ? 'Memuat data driver...' 
                    : 'Memuat lokasi...'),
                ],
              ),
            )
          : Stack(
              children: [
                // MAPS - FULLSCREEN
                MapRouteCustomer(
                  key: _mapKey,
                  idPesanan: widget.idPesanan,
                  pesananData: widget.pesananData,
                  currentStatus: _currentStatus,
                  driverLocation: _driverLocation,
                  customerLocation: _customerLocation,
                ),
                
                // MINIMIZABLE PANEL (BOTTOM)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta! > 5 && !_isPanelMinimized) {
                        setState(() => _isPanelMinimized = true);
                      }
                      else if (details.primaryDelta! < -5 && _isPanelMinimized) {
                        setState(() => _isPanelMinimized = false);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isPanelMinimized 
                          ? 140.0 
                          : (screenHeight * 0.5).clamp(140.0, screenHeight * 0.6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // DRAG HANDLE
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPanelMinimized = !_isPanelMinimized;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          
                          // CONTENT
                          Flexible(
                            child: _isPanelMinimized
                                ? CustomerTrackingWidgets.buildMinimizedContent(
                                    context: context,
                                    driverData: _driverData,
                                    currentStatus: _currentStatus,
                                    isUmkm: _isUmkm, // ✅ Pass isUmkm
                                  )
                                : CustomerTrackingWidgets.buildFullContent(
                                    context: context,
                                    screenWidth: screenWidth,
                                    driverData: _driverData,
                                    currentStatus: _currentStatus,
                                    pesananData: widget.pesananData,
                                    pengirimanData: _pengirimanData,
                                    isUmkm: _isUmkm, // ✅ Pass isUmkm
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

          Positioned(
            bottom: (_isPanelMinimized ? 140 : screenHeight * 0.5) + 80,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFFFF85A1),
              heroTag: 'chat_button',
              onPressed: _openChat,
              child: const Icon(
                Icons.chat_bubble,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // ✅ FOLLOW BUTTON (KANAN BAWAH)
          Positioned(
            bottom: (_isPanelMinimized ? 140 : screenHeight * 0.5) + 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blue,
              heroTag: 'follow_button',
              onPressed: () {
                _mapKey.currentState?.toggleFollowMode();
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// SiDrive - Originally developed by Muhammad Sulthon Abiyyu
// Contact: 0812-4975-4004
// Created: November 2025