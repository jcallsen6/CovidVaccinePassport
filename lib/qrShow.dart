import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';

class QRShowWidget extends StatelessWidget {
  final String contents;

  QRShowWidget(this.contents);
// source: https://pub.dev/packages/qr_code_scanner/example
  QrImage build(BuildContext context) => QrImage(
        data: contents,
        version: QrVersions.auto,
      );
}
