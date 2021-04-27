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
  @override
  Widget build(BuildContext context) {
    return QRScanWidget(_onScan);
  }

  void _onScan(Barcode result) {
    print(result.code);
  }
}
