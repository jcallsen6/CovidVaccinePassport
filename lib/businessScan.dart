import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

import 'package:qr_example/qrScan.dart';
import 'package:qr_example/businessAuth.dart';

class BusinessScanView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BusinessScanView();
}

class _BusinessScanView extends State<BusinessScanView> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(children: <Widget>[
        Flexible(flex: 4, child: QRScanWidget(_onScan)),
      ]),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Business'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.home),
        tooltip: 'Change user type',
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onScan(Barcode result) async {
    var client = http.Client();
    var req = await client.get(
      Uri.parse('http://192.168.1.155:8080/CheckUser?user=${result.code}'),
    );
    if (req.body == 'success') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BusinessAuthView(result.code)),
      );
    }
  }

// source: https://pub.dev/packages/qr_code_scanner/example
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
