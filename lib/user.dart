import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/export.dart' as cryptoExport;
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
  Barcode result;
  QRViewController controller;
  bool user = false;
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

// source: https://pub.dev/packages/dart_amqp
  void _consume(String queue) {
    rabbitClient
        .channel()
        .then((Channel channel) => channel.queue(queue))
        .then((Queue queue) => queue.consume())
        .then((Consumer consumer) => consumer.listen((AmqpMessage message) {
              print(" [x] Received string: ${message.payloadAsString}");
            }));
  }

  @override
  void initState() {
    _loadFromStorage();
    _connRabbitMQ();
    super.initState();
  }

// source: https://pub.dev/packages/qr_code_scanner/example
// In order to get hot reload to work we need to pause the camera if the platform
// is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
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
          Flexible(flex: 4, child: QRScanWidget(_onQRViewCreated)),
        ]),
      );
    }
  }

// source: https://pub.dev/packages/qr_code_scanner/example
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    Random rng = new Random();
    String message = '';
    for (var i = 0; i < 25; i++) {
      message += rng.nextInt(10000).toString();
    }
    String signature =
        RsaKeyHelper().sign(message, keyPair.privateKey as RSAPrivateKey);

    controller.scannedDataStream.listen((scanData) {
      // TODO visual indication qr code was scanned
      // TODO timer to not repeat a million times a second
      setState(() {
        _publish('Buisnesses', scanData.toString(), "$message:$signature");
      });
    });
  }

// source: https://github.com/PointyCastle/pointycastle/blob/master/tutorials/rsa.md
  bool _verifySignature(String message, String publicKey) {
    final contents = message.split(':');
    final rawMessage = contents[0].codeUnits;
    final signature = contents[1].codeUnits;
    final rsaSig = RSASignature(signature);

    final verifier = cryptoExport.RSASigner(
        cryptoExport.SHA256Digest(), "0609608648016503040201");

    verifier.init(
        false,
        crypto.PublicKeyParameter<RSAPublicKey>(
            RsaKeyHelper().parsePublicKeyFromPem(publicKey)));

    return (verifier.verifySignature(rawMessage, rsaSig));
  }

// source: https://pub.dev/packages/qr_code_scanner/example
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
