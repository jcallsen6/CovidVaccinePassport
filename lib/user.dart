import 'dart:math';
import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
import "package:dart_amqp/dart_amqp.dart";
import 'package:json_store/json_store.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:qr_example/qrScan.dart';
import 'package:qr_example/qrShow.dart';

class UserView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserView();
}

class _UserView extends State<UserView> {
  Client rabbitClient;
  JsonStore jsonStore = JsonStore();

// source for generating keypair: https://pub.dev/packages/rsa_encrypt
//to store the KeyPair once we get data from our future
  crypto.AsymmetricKeyPair keyPair;

  Future<void> _genKeyPair() async {
    var helper = RsaKeyHelper();
    keyPair = await helper.computeRSAKeyPair(helper.getSecureRandom());
  }

  Future<void> _loadFromStorage() async {
    Map<String, dynamic> json = await jsonStore.getItem('keypair');
    var helper = RsaKeyHelper();
    if (json == null) {
      await _genKeyPair();
      await jsonStore.setItem('keypair', {
        'publickey':
            helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey),
        'privatekey': helper
            .encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey)
      });
    } else {
      keyPair = crypto.AsymmetricKeyPair(
          helper.parsePublicKeyFromPem(json['publickey']),
          helper.parsePrivateKeyFromPem(json['privatekey']));
    }
    setState(() {});
  }

  void _connRabbitMQ() async {
    ConnectionSettings settings = new ConnectionSettings(
        host: "192.168.1.155",
        authProvider: new PlainAuthenticator("control", "ZafbCB4SxSAL2p"));
    rabbitClient = new Client(settings: settings);
  }

// source: https://pub.dev/packages/dart_amqp
  Future<bool> _publish(
      String exchangeName, String queueName, String message) async {
    try {
      Channel channel = await rabbitClient.channel();
      Exchange exchange =
          await channel.exchange(exchangeName, ExchangeType.DIRECT);
      exchange.publish(message, queueName);
      rabbitClient.close();
    } on ConnectionFailedException {
      await _serverDownDialog();
      return false;
    }
    return true;
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _serverDownDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Messaging Server is Down'),
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

  @override
  void initState() {
    _loadFromStorage();
    _connRabbitMQ();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (keyPair == null) {
      return Scaffold(
          body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[SpinKitRing(color: Colors.blue)],
      ));
    } else {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                  flex: 4,
                  child: QRShowWidget(RsaKeyHelper().encodePublicKeyToPemPKCS1(
                      keyPair.publicKey as RSAPublicKey))),
              Flexible(flex: 4, child: QRScanWidget(_onScan)),
            ]),
      );
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('User'),
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

  Future<void> _onScan(Barcode result) async {
    // make sure scanning a qr code that contains a uuid
    if (RegExp('[a-zA-Z0-9]{64}').hasMatch(result.code)) {
      Random rng = new Random();
      String message = '';
      for (var i = 0; i < 5; i++) {
        message += rng.nextInt(10).toString();
      }
      String signature =
          RsaKeyHelper().sign(message, keyPair.privateKey as RSAPrivateKey);

      if (await _publish('Businesses', result.code, "$message:$signature")) {
        await _showPublishDialog(message);
      }
    }
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _showPublishDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
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
