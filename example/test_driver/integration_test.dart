import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver that writes every screenshot the integration test takes into the
/// package's `screenshots/` folder as a PNG named after the screenshot id.
Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final file = File('../screenshots/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
          return true;
        },
  );
}
