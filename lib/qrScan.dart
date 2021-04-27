import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScanWidget();
  final Function onViewCreated;

  QRScanWidget(this.onViewCreated);
}

class _QRScanWidget extends State<QRScanWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QRScan');

// source: https://pub.dev/packages/qr_code_scanner/example
  Widget build(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 200.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      cameraFacing: CameraFacing.front,
      key: qrKey,
      onQRViewCreated: widget.onViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }
}
