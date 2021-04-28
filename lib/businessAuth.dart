import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/export.dart' as cryptoExport;
import 'package:pointycastle/asymmetric/api.dart';
import "package:dart_amqp/dart_amqp.dart";
import 'package:qr_example/qrShow.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:json_store/json_store.dart';

class BusinessAuthView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BusinessAuthView();
  final String publicKey;

  BusinessAuthView(this.publicKey);
}

class _BusinessAuthView extends State<BusinessAuthView> {
  Client rabbitClient;
  JsonStore jsonStore = JsonStore();
  String id = '';

  @override
  void initState() {
    _loadFromStorage();
    _connRabbitMQ();
    super.initState();
  }

  Future<void> _loadFromStorage() async {
    Map<String, dynamic> json = await jsonStore.getItem('business');
    if (json == null) {
      // source for random string: https://stackoverflow.com/a/61929967
      const String _charSpace =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvqxyz0123456789';
      Random rng = new Random();
      for (var index = 0; index < 64; index++) {
        int charIndex = rng.nextInt(_charSpace.length);
        id += _charSpace.substring(charIndex, charIndex + 1);
      }
      await jsonStore.setItem('business', {'id': id});
    } else {
      id = json['id'];
    }
    setState(() {
      _consume(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[QRShowWidget(id)],
    ));
  }

  // source: https://github.com/PointyCastle/pointycastle/blob/master/tutorials/rsa.md
  String _verifySignature(String message, String publicKey) {
    final contents = message.split(':');
    final rawMessage = Uint8List.fromList(contents[0].codeUnits);
    final signature = base64Decode(contents[1]);
    final rsaSig = RSASignature(signature);

    final verifier = cryptoExport.RSASigner(
        cryptoExport.SHA256Digest(), "0609608648016503040201");

    verifier.init(
        false,
        crypto.PublicKeyParameter<RSAPublicKey>(
            RsaKeyHelper().parsePublicKeyFromPem(publicKey)));

    String result;
    if (verifier.verifySignature(rawMessage, rsaSig)) {
      result = contents[0];
    }
    return result;
  }

  void _connRabbitMQ() async {
    ConnectionSettings settings = new ConnectionSettings(
        host: "192.168.1.155",
        authProvider: new PlainAuthenticator("control", "ZafbCB4SxSAL2p"));
    rabbitClient = new Client(settings: settings);
  }

  // source: https://pub.dev/packages/dart_amqp
  Future<void> _consume(String queue) async {
    rabbitClient
        .channel()
        .then((Channel channel) =>
            channel.exchange('Businesses', ExchangeType.DIRECT))
        .then((Exchange exchange) => exchange.bindQueueConsumer(queue, [queue]))
        .then((Consumer consumer) =>
            consumer.listen((AmqpMessage message) async {
              String result =
                  _verifySignature(message.payloadAsString, widget.publicKey);
              if (result != null) {
                await _showSuccessDialog(result);
                Navigator.pop(context);
              }
            }));
  }

  // source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
  Future<void> _showSuccessDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Valid User!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(
                  Icons.check,
                  size: 64,
                ),
                Text(message),
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
