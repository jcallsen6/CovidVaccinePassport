import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:qr_example/nurseScan.dart';

import 'package:http/http.dart' as http;

class NurseLoginView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NurseLoginView();
}

class _NurseLoginView extends State<NurseLoginView> {
  TextEditingController _username = TextEditingController(text: '');
  TextEditingController _password = TextEditingController(text: '');

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: Icon(Icons.admin_panel_settings_outlined,
                  size: MediaQuery.of(context).size.height / 3),
            ),
            Padding(
                child: TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: 'Username',
                    labelText: 'Username',
                  ),
                  controller: _username,
                ),
                padding: EdgeInsets.fromLTRB(20, 5, 30, 5)),
            Padding(
                child: TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.lock),
                    hintText: 'Password',
                    labelText: 'Password',
                  ),
                  controller: _password,
                  obscureText: true,
                ),
                padding: EdgeInsets.fromLTRB(20, 0, 30, 10)),
            Container(
              alignment: Alignment.center,
              child: ElevatedButton(
                  onPressed: () async {
                    // source for basic auth: https://stackoverflow.com/questions/50244416/how-to-pass-basic-auth-credentials-in-api-call-for-a-flutter-mobile-application
                    String basicAuth = 'Basic ' +
                        base64Encode(
                            utf8.encode('${_username.text}:${_password.text}'));
                    var client = http.Client();
                    try {
                      var req = await client.get(
                        Uri.parse('http://192.168.1.155:8085/Authenticate'),
                        headers: <String, String>{'authorization': basicAuth},
                      );
                      if (req.statusCode == 200) {
                        client.close();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NurseScanView(
                                  _username.text, _password.text)),
                        );
                      } else {
                        client.close();
                        _invalidLogin();
                      }
                    } on SocketException {
                      _serverDownDialog();
                    }
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 25),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Nurse Authentication'),
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
  Future<void> _invalidLogin() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Nurse Login'),
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
