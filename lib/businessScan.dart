import 'dart:io';
import 'dart:core';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
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
  bool loaded = false;

  // Super dumb solution due to broken qr code scanner library. Camera crashes if
  // called immediately or I'm doing something really dumb without realizing
  @override
  void initState() {
    Timer(Duration(milliseconds: 100), handleTimer);
    super.initState();
  }

  void handleTimer() {
    setState(() {
      loaded = true;
    });
  }

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
    try {
      // make sure the qr code scanned is a valid public key
      RsaKeyHelper().parsePublicKeyFromPem(result.code);
      var client = http.Client();
      try {
        // manually encode + signs as dart does not do this even in Uri.encodeFull()
        var req = await client.get(
          Uri.parse('http://192.168.1.155:8085/CheckUser?user=${result.code}'
              .replaceAll('+', '%2B')),
        );
        if (req.body == 'success') {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BusinessAuthView(result.code)),
          );
          // stupid delay to get the camera to come up
          loaded = false;
          Timer(Duration(milliseconds: 100), handleTimer);
        } else {
          _invalidUser();
        }
      } on SocketException {
        _serverDownDialog();
      }
    } catch (exception) {
      print('Invalid QR Code Scanned');
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
