import 'dart:io';
import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:qr_example/qrScan.dart';

class NurseView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NurseView();

  final String username;
  final String password;

  NurseView(this.username, this.password);
}

class _NurseView extends State<NurseView> {
  QRViewController controller;
// source: https://pub.dev/packages/qr_code_scanner/example
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: <Widget>[
        Flexible(
            flex: 4, child: QRScanWidget(_onQRViewCreated, CameraFacing.back)),
        Flexible(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: Text(
                  'Flip Camera',
                  style: TextStyle(fontSize: 24),
                ),
                onPressed: () {
                  controller.flipCamera();
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // source: https://pub.dev/packages/qr_code_scanner/example
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      // TODO visual indication qr code was scanned
      // TODO timer to not repeat a million times a second
      setState(() {
        print(scanData.toString());
      });
    });
  }
}
