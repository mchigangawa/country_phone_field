import 'package:flutter_test/flutter_test.dart';
import 'package:phone_number_field/phone_number_field.dart';

void main() {
  group('PhoneNumber', () {
    const valid = PhoneNumber(
      country: Countries.zimbabwe,
      nationalNumber: '771234567',
    );

    test('completeNumber / e164 join dial code and national number', () {
      expect(valid.completeNumber, '+263771234567');
      expect(valid.e164, '+263771234567');
    });

    test('completeNumber is empty when no digits typed', () {
      const empty = PhoneNumber(
        country: Countries.zimbabwe,
        nationalNumber: '',
      );
      expect(empty.completeNumber, '');
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
    });

    test('isValid reflects the country length rules', () {
      expect(valid.isValid, isTrue);
      const short = PhoneNumber(
        country: Countries.zimbabwe,
        nationalNumber: '12',
      );
      expect(short.isValid, isFalse);
    });

    test('copyWith replaces selected fields', () {
      final us = valid.copyWith(
        country: Countries.unitedStates,
        nationalNumber: '2025550123',
      );
      expect(us.country, Countries.unitedStates);
      expect(us.completeNumber, '+12025550123');
    });

    test('tryParse builds a value from an international string', () {
      final p = PhoneNumber.tryParse('+263 77 123 4567');
      expect(p, isNotNull);
      expect(p!.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
      expect(p.completeNumber, '+263771234567');
    });

    test('tryParse returns null for unmatched input', () {
      expect(PhoneNumber.tryParse(''), isNull);
      expect(PhoneNumber.tryParse('+00000'), isNull);
    });

    test('tryParse accepts a custom resolver', () {
      final p = PhoneNumber.tryParse(
        '+99 12345',
        resolve: (_) =>
            const Country(name: 'Test', isoCode: 'XX', dialCode: '+99'),
      );
      expect(p, isNotNull);
      expect(p!.nationalNumber, '12345');
    });

    test('equality is structural', () {
      const a = PhoneNumber(
        country: Countries.zimbabwe,
        nationalNumber: '771234567',
      );
      expect(a, equals(valid));
      expect(a.hashCode, valid.hashCode);
    });
  });
}
