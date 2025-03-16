import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_config.dart';

class QRService {
  // Generate QR code from string
  static Widget generateQRCode(String data, {double size = 200.0}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }

  // Generate QR code for a cylinder
  static Widget generateCylinderQRCode(String qrCode, {double size = 200.0}) {
    return generateQRCode('${AppConfig.qrCodePrefix}$qrCode', size: size);
  }

  // Format QR data for cylinders
  static String formatCylinderQRData(String qrCode) {
    return '${AppConfig.qrCodePrefix}$qrCode';
  }

  // Check if QR code is a cylinder code
  static bool isCylinderQRCode(String qrData) {
    return qrData.startsWith(AppConfig.qrCodePrefix);
  }

  // Extract cylinder code from QR data
  static String extractCylinderCode(String qrData) {
    if (isCylinderQRCode(qrData)) {
      return qrData.substring(AppConfig.qrCodePrefix.length);
    }
    return qrData;
  }
}

class QRScannerController extends StateNotifier<MobileScannerController> {
  QRScannerController() 
      : super(MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        ));

  void toggleTorch() {
    state.toggleTorch();
  }

  void toggleCamera() {
    state.switchCamera();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}

final qrScannerControllerProvider = StateNotifierProvider<QRScannerController, MobileScannerController>((ref) {
  return QRScannerController();
});
