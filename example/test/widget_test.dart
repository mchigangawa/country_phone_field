// Smoke test for the example gallery app.

import 'package:flutter_test/flutter_test.dart';
import 'package:country_phone_field_example/main.dart';

void main() {
  testWidgets('example gallery builds and shows the sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('country_phone_field'), findsOneWidget);
    expect(find.text('Live output'), findsOneWidget);
  });
}
