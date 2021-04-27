import 'package:flutter/material.dart';
import 'dart:io';

import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScanWidget();
  final Function onScan;

  QRScanWidget(this.onScan);
}

// source for entire class: https://pub.dev/packages/qr_code_scanner/example
class _QRScanWidget extends State<QRScanWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QRScan');
  Barcode result;
  QRViewController controller;
  bool _scanning = false;

  Widget build(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 200.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      cameraFacing: CameraFacing.back,
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

// In order to get hot reload to work we need to pause the camera if the platform
// is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (!_scanning) {
        _scanning = true;
        controller.pauseCamera();
        await widget.onScan(scanData);
        setState(() {
          controller.resumeCamera();
        });
        _scanning = false;
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
