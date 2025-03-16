import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/cylinder.dart';
import 'api_service.dart';
import '../config/app_config.dart';

class QRScannerService {
  final ApiService _apiService;
  
  QRScannerService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Get cylinder by QR code
  Future<Cylinder> getCylinderByQRCode(String qrCode) async {
    try {
      final response = await _apiService.get('${AppConfig.cylindersByQREndpoint}/$qrCode');
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Show QR scanner dialog
  Future<String?> scanQRCode(BuildContext context) async {
    String? scannedCode;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: 400,
            width: 300,
            child: Column(
              children: [
                AppBar(
                  title: const Text('Scan QR Code'),
                  backgroundColor: Colors.blue[800],
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  centerTitle: true,
                  elevation: 0,
                ),
                Expanded(
                  child: MobileScanner(
                    // Register a callback for when QR codes are detected
                    onDetect: (BarcodeCapture capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          scannedCode = barcode.rawValue;
                          Navigator.pop(context);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    return scannedCode;
  }
  
  // Show QR scanner screen (full page)
  static Future<String?> scanQRCodeFullScreen(BuildContext context) async {
    String? scannedCode;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan QR Code'),
            backgroundColor: Colors.blue[800],
          ),
          body: MobileScanner(
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  scannedCode = barcode.rawValue;
                  Navigator.pop(context);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
    
    return scannedCode;
  }
}
