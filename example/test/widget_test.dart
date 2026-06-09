// Smoke test for the example gallery app.

import 'package:flutter_test/flutter_test.dart';
import 'package:phone_number_field_example/main.dart';

void main() {
  testWidgets('example gallery builds and shows the sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('phone_number_field'), findsOneWidget);
    expect(find.text('Live output'), findsOneWidget);
  });
}
