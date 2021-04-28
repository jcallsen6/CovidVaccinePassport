import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:qr_example/qrScan.dart';

class NurseView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NurseView();
  final String username;
  final String password;

  NurseView(this.username, this.password);
}

class _NurseView extends State<NurseView> {
  bool loaded = false;

  // Super dumb solution due to broken qr code scanner library. Camera crashes if
  // called immediately or I'm doing something really dumb without realizing
  @override
  void initState() {
    loaded = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (loaded) {
      return QRScanWidget(_onScan);
    } else {
      return Scaffold(
          body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[SpinKitRing(color: Colors.blue)],
      ));
    }
  }

  void _onScan(Barcode result) async {
    // source for basic auth: https://stackoverflow.com/questions/50244416/how-to-pass-basic-auth-credentials-in-api-call-for-a-flutter-mobile-application
    String basicAuth = 'Basic ' +
        base64Encode(utf8.encode('${widget.username}:${widget.password}'));
    var client = http.Client();
    var req = await client.post(Uri.parse('http://192.168.1.155:8080/AddUser'),
        headers: <String, String>{'authorization': basicAuth},
        body: {'user': result.code});
    if (req.statusCode == 200) {
      _successDialog();
    }
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _successDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Successfully Added!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(
                  Icons.check,
                  size: 50,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Continue'),
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
