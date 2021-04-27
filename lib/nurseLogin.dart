import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';

import 'package:qr_example/nurse.dart';

import 'package:http/http.dart' as http;
import 'package:qr_example/qrScan.dart';

class NurseLoginView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NurseLoginView();
}

class _NurseLoginView extends State<NurseLoginView> {
  TextEditingController _username = TextEditingController(text: '');
  TextEditingController _password = TextEditingController(text: '');

  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          child: Text(
            'Nurse Authentication',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 32, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ),
        TextFormField(
          decoration: const InputDecoration(
            icon: Icon(Icons.person),
            hintText: 'Username',
            labelText: 'Username',
          ),
          controller: _username,
        ),
        TextFormField(
          decoration: const InputDecoration(
            icon: Icon(Icons.person),
            hintText: 'Password',
            labelText: 'Password',
          ),
          controller: _password,
          obscureText: true,
        ),
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
              onPressed: () async {
                // source for basic auth: https://stackoverflow.com/questions/50244416/how-to-pass-basic-auth-credentials-in-api-call-for-a-flutter-mobile-application
                String basicAuth = 'Basic ' +
                    base64Encode(
                        utf8.encode('${_username.text}:${_password.text}'));
                var client = http.Client();
                var req = await client.get(
                  Uri.parse('http://192.168.1.155:8080/Authenticate'),
                  headers: <String, String>{'authorization': basicAuth},
                );
                if (req.statusCode == 200) {
                  client.close();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            NurseView(_username.text, _password.text)),
                  );
                } else {
                  client.close();
                  _invalidLogin();
                }
              },
              child: Text(
                'Login',
                style: TextStyle(fontSize: 25),
              )),
        ),
      ],
    ));
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _invalidLogin() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invalid Nurse Login'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[],
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
