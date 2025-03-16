import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/qr_scanner_widget.dart';

// QR Scanner Service to handle QR scanning functionality
class QrScannerService {
  final BuildContext context;
  
  QrScannerService(this.context);

  // Open QR scanner and return scanned code
  Future<String?> scanQR() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const QrScannerWidget(),
    );
    
    return result;
  }

  // Process QR code
  Future<String> processQrCode(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isEmpty) {
      throw Exception('No QR code detected');
    }
    
    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    
    if (rawValue == null || rawValue.isEmpty) {
      throw Exception('Invalid QR code');
    }
    
    return rawValue;
  }
}

// QR Scanner Service Provider
final qrScannerServiceProvider = Provider.family<QrScannerService, BuildContext>((ref, context) {
  return QrScannerService(context);
});
