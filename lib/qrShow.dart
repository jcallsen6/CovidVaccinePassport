import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';

class QRShowWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRShowWidget();
  final String contents;

  QRShowWidget(this.contents);
}

class _QRShowWidget extends State<QRShowWidget> {
// source: https://pub.dev/packages/qr_code_scanner/example
  QrImage build(BuildContext context) => QrImage(
        data: widget.contents,
        version: QrVersions.auto,
      );
}
