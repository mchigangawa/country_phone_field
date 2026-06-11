import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:country_phone_field_example/main.dart';

/// Drives the example app on a real device/simulator and captures PNG
/// screenshots used in the package README. Run with:
///
/// ```bash
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/screenshot_test.dart \
///   -d <device>
/// ```
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> prepareSurface() async {
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {
      // Already converted (subsequent tests in the same run) — ignore.
    }
  }

  testWidgets('overview (light)', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await prepareSurface();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_overview');
  });

  testWidgets('country picker bottom sheet', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('+263').first);
    await tester.pumpAndSettle();
    await prepareSurface();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_country_picker');
  });

  testWidgets('dialog picker', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    final dialCode = find.text('+91').first;
    await tester.scrollUntilVisible(
      dialCode,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(dialCode);
    await tester.pumpAndSettle();
    await prepareSurface();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03_dialog_picker');
  });

  testWidgets('auto-detect section', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    final target = find.textContaining('drops the leading 0');
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await prepareSurface();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_auto_detect');
  });

  testWidgets('overview (dark)', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();
    await prepareSurface();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05_overview_dark');
  });
}
