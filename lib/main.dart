import 'dart:io';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';

import "package:dart_amqp/dart_amqp.dart";

void main() => runApp(MaterialApp(home: QRViewExample()));

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool user = false;
  Client rabbitClient;

  // source for generating keypair: https://pub.dev/packages/rsa_encrypt
  //to store the KeyPair once we get data from our future
  crypto.AsymmetricKeyPair keyPair;

  void _getKeyPair() async {
    var helper = RsaKeyHelper();
    this.keyPair = await helper.computeRSAKeyPair(helper.getSecureRandom());
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
    _getKeyPair();
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
    return Scaffold(
      body: Column(children: <Widget>[
        Flexible(flex: 4, child: _qrCodeDisplay(context)),
        Flexible(flex: 4, child: _buildQrView(context)),
      ]),
    );
  }

  // source: https://pub.dev/packages/qr_code_scanner/example
  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 200.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      cameraFacing: CameraFacing.front,
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  // source: https://pub.dev/packages/qr_code_scanner/example
  QrImage _qrCodeDisplay(BuildContext context) => QrImage(
        data: "1234567890",
        version: QrVersions.auto,
        size: MediaQuery.of(context).size.height / 2,
      );

  // source: https://pub.dev/packages/qr_code_scanner/example
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        print(result);
        print(RsaKeyHelper()
            .encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey));
        print(RsaKeyHelper()
            .encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey));
      });
    });
  }

  // source: https://pub.dev/packages/qr_code_scanner/example
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
