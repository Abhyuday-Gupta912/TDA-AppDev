import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/event_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close, color: AppTheme.white),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: AppTheme.white),
        ),
        actions: [
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_on, color: AppTheme.white),
          ),
          IconButton(
            onPressed: () => cameraController.switchCamera(),
            icon: const Icon(Icons.camera_rear, color: AppTheme.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Mobile Scanner View
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),

                // Scanner Overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: AppTheme.primaryColor,
                      borderRadius: 12,
                      borderLength: 30,
                      borderWidth: 8,
                      cutOutSize: 250,
                    ),
                  ),
                ),

                // Processing Overlay
                if (_isProcessing)
                  Container(
                    color: AppTheme.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Processing QR Code...',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Instructions Section
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Position QR code within the frame',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grey900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The QR code will be scanned automatically when detected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !_isProcessing) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _processQRCode(code);
      }
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Parse QR code data
      final qrData = _parseQRCode(qrCode);

      if (qrData != null) {
        await _handleQRData(qrData);
      } else {
        _showError('Invalid QR code format');
      }
    } catch (e) {
      _showError('Failed to process QR code: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Map<String, dynamic>? _parseQRCode(String qrCode) {
    try {
      // Try to parse as event registration QR code
      // Expected format: eventId_userId_registrationId or similar
      if (qrCode.contains('_')) {
        final parts = qrCode.split('_');
        if (parts.length >= 2) {
          return {
            'type': 'event_registration',
            'eventId': parts[0],
            'userId': parts[1],
            'registrationId': parts.length > 2 ? parts[2] : null,
          };
        }
      }

      // Try to parse as event QR code
      // Expected format: event:eventId
      if (qrCode.startsWith('event:')) {
        return {
          'type': 'event',
          'eventId': qrCode.substring(6),
        };
      }

      // Try to parse as URL
      if (qrCode.startsWith('http')) {
        return {
          'type': 'url',
          'url': qrCode,
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleQRData(Map<String, dynamic> qrData) async {
    switch (qrData['type']) {
      case 'event_registration':
        await _handleEventRegistration(qrData);
        break;
      case 'event':
        await _handleEventQR(qrData);
        break;
      case 'url':
        await _handleUrlQR(qrData);
        break;
      default:
        _showError('Unsupported QR code type');
    }
  }

  Future<void> _handleEventRegistration(Map<String, dynamic> qrData) async {
    try {
      final eventId = qrData['eventId'];
      final userId = qrData['userId'];

      // Call check-in API
      final response = await EventService.checkInAttendee(eventId, userId);

      if (response['success']) {
        _showSuccess(
          'Check-in Successful!',
          '${response['attendeeName']} has been checked in for ${response['eventName']}',
        );
      } else {
        _showError(response['message'] ?? 'Check-in failed');
      }
    } catch (e) {
      _showError('Failed to process check-in: ${e.toString()}');
    }
  }

  Future<void> _handleEventQR(Map<String, dynamic> qrData) async {
    final eventId = qrData['eventId'];

    // Navigate to event detail screen
    if (mounted) {
      context.pop();
      context.push('/event/$eventId');
    }
  }

  Future<void> _handleUrlQR(Map<String, dynamic> qrData) async {
    _showError('URL QR codes are not supported in this version');
  }

  void _showSuccess(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 48,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted) {
                context.pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: AppTheme.errorColor,
          size: 48,
        ),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
            rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth =
        this.cutOutWidth < width ? this.cutOutWidth : width - borderWidth;
    final cutOutHeight =
        this.cutOutHeight < height ? this.cutOutHeight : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - borderWidth * 2,
      cutOutHeight - borderWidth * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    // Draw corner borders
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();

    // Top-left corner
    path.moveTo(cutOutRect.left - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderLength);

    // Top-right corner
    path.moveTo(cutOutRect.right + borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom-right corner
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom-left corner
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
