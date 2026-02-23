// ============================================================================
// KTM_BARCODE_SERVICE.DART
// Service untuk scan barcode KTM dan auto-verify
// ============================================================================
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Result dari barcode scan
class BarcodeVerificationResult {
  final String? nim;
  final bool isValid;
  final String? rawValue;
  final String errorMessage;

  BarcodeVerificationResult({
    this.nim,
    required this.isValid,
    this.rawValue,
    this.errorMessage = '',
  });
}

class KtmBarcodeService {
  
  /// Parse NIM dari barcode value
  /// Barcode format bisa bermacam-macam, contoh:
  /// - "221080200036" (plain NIM)
  /// - "UMSIDA:221080200036" (dengan prefix)
  /// - "NIM=221080200036" (key-value)
  BarcodeVerificationResult parseBarcode(String barcodeValue) {
    try {
      debugPrint('🔍 [BARCODE] Parsing barcode: $barcodeValue');

      // Clean value
      String cleanValue = barcodeValue.trim();

      // Strategy 1: Plain 12 digit number
      final plainNimMatch = RegExp(r'\b(\d{12})\b').firstMatch(cleanValue);
      if (plainNimMatch != null) {
        final nim = plainNimMatch.group(1)!;
        if (_isValidNimFormat(nim)) {
          debugPrint('✅ [BARCODE] NIM found (plain): $nim');
          return BarcodeVerificationResult(
            nim: nim,
            isValid: true,
            rawValue: barcodeValue,
          );
        }
      }

      // Strategy 2: With prefix (UMSIDA:221080200036)
      final prefixMatch = RegExp(r'UMSIDA[:\s=](\d{12})').firstMatch(cleanValue.toUpperCase());
      if (prefixMatch != null) {
        final nim = prefixMatch.group(1)!;
        debugPrint('✅ [BARCODE] NIM found (with prefix): $nim');
        return BarcodeVerificationResult(
          nim: nim,
          isValid: true,
          rawValue: barcodeValue,
        );
      }

      // Strategy 3: Key-value format (NIM=221080200036)
      final kvMatch = RegExp(r'NIM[:\s=](\d{12})').firstMatch(cleanValue.toUpperCase());
      if (kvMatch != null) {
        final nim = kvMatch.group(1)!;
        debugPrint('✅ [BARCODE] NIM found (key-value): $nim');
        return BarcodeVerificationResult(
          nim: nim,
          isValid: true,
          rawValue: barcodeValue,
        );
      }

      // Not found
      debugPrint('❌ [BARCODE] NIM not found in barcode');
      return BarcodeVerificationResult(
        isValid: false,
        rawValue: barcodeValue,
        errorMessage: 'NIM tidak ditemukan dalam barcode',
      );

    } catch (e) {
      debugPrint('❌ [BARCODE] Error parsing: $e');
      return BarcodeVerificationResult(
        isValid: false,
        errorMessage: 'Error parsing barcode: ${e.toString()}',
      );
    }
  }

  /// Validate NIM format
  bool _isValidNimFormat(String nim) {
    // Must be 12 digits
    if (nim.length != 12) return false;
    
    // Must be all numbers
    if (!RegExp(r'^\d{12}$').hasMatch(nim)) return false;
    
    // First 2 digits must be valid year (19-26 for 2019-2026)
    final firstTwo = int.tryParse(nim.substring(0, 2));
    if (firstTwo == null || firstTwo < 19 || firstTwo > 26) return false;
    
    return true;
  }

  /// Check if barcode is likely from KTM UMSIDA
  bool isLikelyKtmBarcode(String barcodeValue) {
    // Check if contains 12 digit number
    if (RegExp(r'\d{12}').hasMatch(barcodeValue)) return true;
    
    // Check if contains UMSIDA keyword
    if (barcodeValue.toUpperCase().contains('UMSIDA')) return true;
    
    return false;
  }
}

/// Widget untuk scan barcode KTM
class KtmBarcodeScanner extends StatefulWidget {
  final Function(String nim) onBarcodeDetected;
  final VoidCallback? onCancel;

  const KtmBarcodeScanner({
    super.key,
    required this.onBarcodeDetected,
    this.onCancel,
  });

  @override
  State<KtmBarcodeScanner> createState() => _KtmBarcodeScannerState();
}

class _KtmBarcodeScannerState extends State<KtmBarcodeScanner> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final KtmBarcodeService _barcodeService = KtmBarcodeService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        debugPrint('📷 [BARCODE_SCANNER] Barcode detected: $code');

        // Parse barcode
        final result = _barcodeService.parseBarcode(code);

        if (result.isValid && result.nim != null) {
          // Success!
          debugPrint('✅ [BARCODE_SCANNER] Valid NIM: ${result.nim}');
          widget.onBarcodeDetected(result.nim!);
          
          // Close scanner
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // Invalid barcode
          debugPrint('❌ [BARCODE_SCANNER] Invalid barcode');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage),
                backgroundColor: Colors.orange,
              ),
            );
          }

          setState(() {
            _isProcessing = false;
          });
        }

        break; // Process only first barcode
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode KTM'),
        backgroundColor: const Color(0xFF5DADE2),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scanning guide
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Arahkan kamera ke barcode KTM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Barcode ada di pojok kiri bawah KTM',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (widget.onCancel != null)
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize * 0.4, // Barcode biasanya horizontal
    );

    // Draw dark overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw scan area border
    final borderPaint = Paint()
      ..color = const Color(0xFF5DADE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF5DADE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      scanAreaRect.topLeft,
      scanAreaRect.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.topLeft,
      scanAreaRect.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      scanAreaRect.topRight,
      scanAreaRect.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.topRight,
      scanAreaRect.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      scanAreaRect.bottomLeft,
      scanAreaRect.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.bottomLeft,
      scanAreaRect.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      scanAreaRect.bottomRight,
      scanAreaRect.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanAreaRect.bottomRight,
      scanAreaRect.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}