import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';

import "package:dart_amqp/dart_amqp.dart";

import 'package:json_store/json_store.dart';

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
    // You can provide a settings object to override the
    // default connection settings
    ConnectionSettings settings = new ConnectionSettings(
        host: "192.168.1.155",
        authProvider: new PlainAuthenticator("control", "ZafbCB4SxSAL2p"));
    rabbitClient = new Client(settings: settings);
  }

// source: https://pub.dev/packages/dart_amqp
  void _publish(String exchange, String queue, String message) async {
    rabbitClient
        .channel()
        .then((Channel channel) =>
            channel.exchange(exchange, ExchangeType.DIRECT))
        .then((Exchange exchange) {
      // We dont care about the routing key as our exchange type is FANOUT
      exchange.publish(message, queue);
      rabbitClient.close();
    });
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
        children: <Widget>[Text('Loading')],
      ));
    } else {
      return Scaffold(
        body: Column(children: <Widget>[
          Flexible(
              flex: 4,
              child: QRShowWidget(RsaKeyHelper().encodePublicKeyToPemPKCS1(
                  keyPair.publicKey as RSAPublicKey))),
          Flexible(flex: 4, child: QRScanWidget(_onScan)),
        ]),
      );
    }
  }

  void _onScan(Barcode result) {
    Random rng = new Random();
    String message = '';
    for (var i = 0; i < 25; i++) {
      message += rng.nextInt(10000).toString();
    }
    String signature =
        RsaKeyHelper().sign(message, keyPair.privateKey as RSAPrivateKey);

    _publish('Buisnesses', result.toString(), "$message:$signature");
  }
}
