import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';
import '../utils/constants.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  final Function(String)? onScanComplete;
  
  const QRScannerScreen({Key? key, this.onScanComplete}) : super(key: key);

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  bool _isTorchOn = false;
  bool _hasScanned = false;
  String? _scannedCode;
  bool _isCylinderCode = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && !_hasScanned) {
        final String code = barcode.rawValue!;
        
        // Check if it's a cylinder QR code
        final bool isCylinderCode = QRService.isCylinderQRCode(code);
        
        setState(() {
          _hasScanned = true;
          _scannedCode = code;
          _isCylinderCode = isCylinderCode;
        });
        
        // Process the scanned code
        if (isCylinderCode) {
          // If it's a cylinder code, extract the actual code
          final String cylinderCode = QRService.extractCylinderCode(code);
          
          // If callback provided, call it with the extracted code
          if (widget.onScanComplete != null) {
            widget.onScanComplete!(cylinderCode);
          }
        } else {
          // If callback provided, call it with the raw code
          if (widget.onScanComplete != null) {
            widget.onScanComplete!(code);
          }
        }
        
        // Show the result dialog
        _showResultDialog(code);
        break;
      }
    }
  }

  void _showResultDialog(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Code: ${_isCylinderCode ? QRService.extractCylinderCode(code) : code}'),
              const SizedBox(height: 8),
              Text(
                _isCylinderCode
                    ? 'This is a valid cylinder code.'
                    : 'This is not a recognized cylinder code.',
                style: TextStyle(
                  color: _isCylinderCode ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (!_isCylinderCode) {
                  // If it wasn't a valid cylinder code, allow scanning again
                  setState(() {
                    _hasScanned = false;
                    _scannedCode = null;
                  });
                } else if (widget.onScanComplete == null) {
                  // If it was a valid code but no callback, allow scanning again
                  Navigator.of(context).pop(); // Close scanner screen
                }
              },
              child: Text(_isCylinderCode ? 'OK' : 'Scan Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerController = ref.watch(qrScannerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              scannerController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
              scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: scannerController,
              onDetect: _onDetect,
            ),
          ),
          // Bottom instructions panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Position the QR code within the frame',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The scanner will automatically detect valid QR codes',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureButton(
                      icon: Icons.flash_on,
                      label: 'Toggle Flash',
                      onTap: () {
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                        scannerController.toggleTorch();
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.flip_camera_android,
                      label: 'Switch Camera',
                      onTap: () {
                        scannerController.switchCamera();
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.close,
                      label: 'Cancel',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kPrimaryColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 254,
            height: 254,
            decoration: BoxDecoration(
              border: Border.all(color: kPrimaryColor, width: 2),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ],
    );
  }
}
