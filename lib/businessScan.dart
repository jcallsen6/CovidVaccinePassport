import 'dart:io';

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
      title: const Text('Business Scanner'),
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
    try {
      // manually encode + signs as dart does not do this even in Uri.encodeFull()
      var req = await client.get(
        Uri.parse('http://192.168.1.155:8085/CheckUser?user=${result.code}'
            .replaceAll('+', '%2B')),
      );
      if (req.body == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BusinessAuthView(result.code)),
        );
      } else {
        _invalidUser();
      }
    } on SocketException {
      _serverDownDialog();
    }
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _serverDownDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Authentication Server is Down'),
          actions: <Widget>[
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _invalidUser() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Not Found'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(
                  Icons.no_encryption,
                  size: 64,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
