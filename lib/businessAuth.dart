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
      Random rng = new Random();
      for (var i = 0; i < 10; i++) {
        id += rng.nextInt(10).toString();
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
  bool _verifySignature(String message, String publicKey) {
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

    return (verifier.verifySignature(rawMessage, rsaSig));
  }

  void _connRabbitMQ() async {
    // You can provide a settings object to override the
    // default connection settings
    ConnectionSettings settings = new ConnectionSettings(
        host: "192.168.1.155",
        authProvider: new PlainAuthenticator("control", "ZafbCB4SxSAL2p"));
    rabbitClient = new Client(settings: settings);
  }

  // source: https://pub.dev/packages/dart_amqp
  void _consume(String queue) {
    rabbitClient
        .channel()
        .then((Channel channel) =>
            channel.exchange('Businesses', ExchangeType.DIRECT))
        .then((Exchange exchange) => exchange.bindQueueConsumer(queue, [queue]))
        .then((Consumer consumer) => consumer.listen((AmqpMessage message) {
              print(" [x] Received string: ${message.payloadAsString}");
              bool result =
                  _verifySignature(message.payloadAsString, widget.publicKey);
              // TODO display to user
              print(result);
            }));
  }
}
