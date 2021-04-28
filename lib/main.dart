import 'package:flutter/material.dart';
import 'package:qr_example/nurseLogin.dart';
import 'package:qr_example/user.dart';
import 'package:qr_example/businessScan.dart';

void main() => runApp(MaterialApp(home: LoginView()));

class LoginView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginView();
}

// TODO remember this choice and just load by default after first opening
class _LoginView extends State<LoginView> {
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          child: Text(
            'COVID-19 Vaccine Passport',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 64, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserView()),
                );
              },
              child: Text(
                'User',
                style: TextStyle(fontSize: 50),
              )),
        ),
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NurseLoginView()),
                );
              },
              child: Text(
                'Nurse',
                style: TextStyle(fontSize: 50),
              )),
        ),
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusinessScanView()),
                );
              },
              child: Text(
                'Business',
                style: TextStyle(fontSize: 50),
              )),
        ),
      ],
    ));
  }
}

enum userType { Nurse, business, User }
