import 'package:flutter/material.dart';

class NurseView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NurseView();

  final String username;
  final String password;

  NurseView(this.username, this.password);
}

class _NurseView extends State<NurseView> {
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: <Widget>[Text('TODO')],
    ));
  }
}
