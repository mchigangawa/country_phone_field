import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:country_phone_field/country_phone_field.dart';

/// Wraps [child] in a minimal MaterialApp/Scaffold for widget testing.
Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PhoneNumberField rendering', () {
    testWidgets('shows the initial country flag and dial code', (tester) async {
      await tester.pumpWidget(
        _host(const PhoneNumberField(initialCountry: Countries.zimbabwe)),
      );
      expect(find.text('+263'), findsOneWidget);
      expect(find.text(Countries.zimbabwe.flag), findsOneWidget);
    });

    testWidgets('resolves initial country from ISO code', (tester) async {
      await tester.pumpWidget(
        _host(const PhoneNumberField(initialCountryCode: 'KE')),
      );
      expect(find.text('+254'), findsOneWidget);
    });

    testWidgets('renders the floating label', (tester) async {
      await tester.pumpWidget(
        _host(
          const PhoneNumberField(labels: PhoneFieldLabels(labelText: 'Mobile')),
        ),
      );
      expect(find.text('Mobile'), findsOneWidget);
    });
  });

  group('Input handling', () {
    testWidgets('emits a PhoneNumber separating country from number', (
      tester,
    ) async {
      PhoneNumber? captured;
      await tester.pumpWidget(
        _host(
          PhoneNumberField(
            initialCountry: Countries.zimbabwe,
            onChanged: (value) => captured = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '771234567');
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.country, Countries.zimbabwe);
      expect(captured!.nationalNumber, '771234567');
      expect(captured!.completeNumber, '+263771234567');
      expect(captured!.isValid, isTrue);
    });

    testWidgets('filters out non-digit characters', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _host(
          PhoneNumberField(
            controller: controller,
            initialCountry: Countries.zimbabwe,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '77-abc-12!34');
      await tester.pump();
      expect(controller.text, '771234');
    });

    testWidgets('caps input at the country max length', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _host(
          PhoneNumberField(
            controller: controller,
            initialCountry: Countries.zimbabwe, // maxLength 9
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '123456789012345');
      await tester.pump();
      expect(controller.text.length, 9);
    });
  });

  group('Validation', () {
    Future<String?> runValidator(
      WidgetTester tester,
      PhoneNumberField field, {
      String? input,
    }) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_host(Form(key: formKey, child: field)));
      if (input != null) {
        await tester.enterText(find.byType(TextField), input);
        await tester.pump();
      }
      formKey.currentState!.validate();
      await tester.pump();
      return null;
    }

    testWidgets('reports required when empty', (tester) async {
      await runValidator(
        tester,
        const PhoneNumberField(initialCountry: Countries.zimbabwe),
      );
      expect(find.text('Phone number is required'), findsOneWidget);
    });

    testWidgets('reports a length error for too-short numbers', (tester) async {
      await runValidator(
        tester,
        const PhoneNumberField(initialCountry: Countries.zimbabwe),
        input: '123',
      );
      expect(find.textContaining('Zimbabwe'), findsOneWidget);
    });

    testWidgets('accepts a valid number (no error shown)', (tester) async {
      await runValidator(
        tester,
        const PhoneNumberField(initialCountry: Countries.zimbabwe),
        input: '771234567',
      );
      expect(find.textContaining('Zimbabwe'), findsNothing);
      expect(find.text('Phone number is required'), findsNothing);
    });

    testWidgets('custom validator takes priority', (tester) async {
      await runValidator(
        tester,
        PhoneNumberField(
          initialCountry: Countries.zimbabwe,
          validator: (value) => 'Blocked',
        ),
        input: '771234567',
      );
      expect(find.text('Blocked'), findsOneWidget);
    });

    testWidgets('not-required empty field passes', (tester) async {
      await runValidator(
        tester,
        const PhoneNumberField(
          initialCountry: Countries.zimbabwe,
          required: false,
        ),
      );
      expect(find.text('Phone number is required'), findsNothing);
    });
  });

  group('Country picker', () {
    testWidgets('opens and changes the country on selection', (tester) async {
      Country? changed;
      await tester.pumpWidget(
        _host(
          PhoneNumberField(
            initialCountry: Countries.zimbabwe,
            onCountryChanged: (c) => changed = c,
          ),
        ),
      );

      await tester.tap(find.text('+263'));
      await tester.pumpAndSettle();

      // Picker title visible.
      expect(find.text('Select Country'), findsOneWidget);

      // Search for Kenya and tap it.
      await tester.enterText(find.byType(TextField).last, 'Kenya');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Kenya'));
      await tester.pumpAndSettle();

      expect(changed, Countries.kenya);
      expect(find.text('+254'), findsOneWidget);
    });

    testWidgets('locked country disables the picker', (tester) async {
      await tester.pumpWidget(
        _host(const PhoneNumberField(lockedCountry: Countries.zimbabwe)),
      );

      await tester.tap(find.text('+263'));
      await tester.pumpAndSettle();
      // No picker appears.
      expect(find.text('Select Country'), findsNothing);
    });
  });

  group('Customization', () {
    testWidgets('respects a fully custom decoration', (tester) async {
      await tester.pumpWidget(
        _host(
          const PhoneNumberField(
            initialCountry: Countries.zimbabwe,
            decoration: InputDecoration(
              labelText: 'Custom',
              border: UnderlineInputBorder(),
            ),
          ),
        ),
      );
      expect(find.text('Custom'), findsOneWidget);
      // Selector still injected (dial code visible).
      expect(find.text('+263'), findsOneWidget);
    });

    testWidgets('borderless type renders without throwing', (tester) async {
      await tester.pumpWidget(
        _host(
          const PhoneNumberField(
            initialCountry: Countries.zimbabwe,
            borderType: PhoneFieldBorderType.none,
            filled: true,
          ),
        ),
      );
      expect(find.byType(PhoneNumberField), findsOneWidget);
    });

    testWidgets('can hide flag and dial code via selector style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const PhoneNumberField(
            initialCountry: Countries.zimbabwe,
            selectorStyle: CountrySelectorStyle(
              showFlag: false,
              showDialCode: false,
              showIsoCode: true,
            ),
          ),
        ),
      );
      expect(find.text('+263'), findsNothing);
      expect(find.text('ZW'), findsOneWidget);
    });
  });

  group('Form integration', () {
    testWidgets('onSaved receives the final value', (tester) async {
      final formKey = GlobalKey<FormState>();
      PhoneNumber? saved;
      await tester.pumpWidget(
        _host(
          Form(
            key: formKey,
            child: PhoneNumberField(
              initialCountry: Countries.zimbabwe,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '771234567');
      formKey.currentState!.save();

      expect(saved, isNotNull);
      expect(saved!.completeNumber, '+263771234567');
    });
  });
}
