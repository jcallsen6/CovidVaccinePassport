import 'package:flutter/material.dart';

import 'package:json_store/json_store.dart';

import 'package:qr_example/nurseLogin.dart';
import 'package:qr_example/user.dart';
import 'package:qr_example/businessScan.dart';

void main() => runApp(MaterialApp(home: MenuView()));

class MenuView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MenuView();
}

class _MenuView extends State<MenuView> {
  JsonStore jsonStore = JsonStore();

  @override
  void initState() {
    _loadUserType();
    super.initState();
  }

  void _loadUserType() async {
    Map<String, dynamic> json = await jsonStore.getItem('userType');
    if (json != null) {
      switch (json['type']) {
        case 'user':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserView()),
          );
          break;
        case 'nurse':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NurseLoginView()),
          );
          break;
        case 'business':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BusinessScanView()),
          );
          break;
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(
            'COVID-19 Vaccine Passport',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.height / 20,
                color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ]),
        Icon(Icons.medical_services_outlined,
            size: MediaQuery.of(context).size.height / 3),
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
              onPressed: () {
                jsonStore.setItem('userType', {'type': 'user'});
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
                jsonStore.setItem('userType', {'type': 'nurse'});
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
                jsonStore.setItem('userType', {'type': 'business'});
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
