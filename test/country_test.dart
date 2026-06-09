import 'package:flutter_test/flutter_test.dart';
import 'package:phone_number_field/phone_number_field.dart';

void main() {
  group('Country', () {
    test('derives flag emoji from ISO code', () {
      // ZW -> regional indicators 🇿 🇼
      expect(Countries.zimbabwe.flag, '\u{1F1FF}\u{1F1FC}');
      expect(Countries.unitedStates.flag, '\u{1F1FA}\u{1F1F8}');
    });

    test('honours an explicit flag override', () {
      const c = Country(
        name: 'Test',
        isoCode: 'XX',
        dialCode: '+999',
        flag: '🏳️',
      );
      expect(c.flag, '🏳️');
    });

    test('falls back to the iso code for non-letter codes', () {
      const c = Country(name: 'Bad', isoCode: '12', dialCode: '+1');
      expect(c.flag, '12');
    });

    test('dialCodeDigits strips the plus', () {
      expect(Countries.zimbabwe.dialCodeDigits, '263');
    });

    test('isValidLength respects bounds', () {
      expect(Countries.zimbabwe.isValidLength('771234567'), isTrue); // 9
      expect(Countries.zimbabwe.isValidLength('77123456'), isFalse); // 8
      expect(Countries.zimbabwe.isValidLength('7712345678'), isFalse); // 10
    });

    test('equality is based on iso + dial code', () {
      const a = Country(name: 'A', isoCode: 'ZW', dialCode: '+263');
      const b = Country(
        name: 'Different Name',
        isoCode: 'ZW',
        dialCode: '+263',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith overrides only given fields', () {
      final c = Countries.unitedStates.copyWith(name: 'USA');
      expect(c.name, 'USA');
      expect(c.isoCode, 'US');
      expect(c.dialCode, '+1');
    });

    test('constructor asserts guard invalid data', () {
      expect(
        () => Country(
          name: 'x',
          isoCode: 'XX',
          dialCode: '+1',
          minLength: 5,
          maxLength: 3,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Countries catalogue', () {
    test('is non-empty and alphabetically sorted by name', () {
      expect(Countries.all, isNotEmpty);
      final names = Countries.all.map((c) => c.name).toList();
      final sorted = [...names]..sort();
      expect(names, sorted);
    });

    test('has no duplicate iso codes', () {
      final isoCodes = Countries.all.map((c) => c.isoCode).toList();
      expect(isoCodes.toSet().length, isoCodes.length);
    });

    test('fromIsoCode is case-insensitive', () {
      expect(Countries.fromIsoCode('zw'), Countries.zimbabwe);
      expect(Countries.fromIsoCode('ZW'), Countries.zimbabwe);
      expect(Countries.fromIsoCode('zz'), isNull);
    });

    test('fromDialCode matches the longest prefix', () {
      // +1242 (Bahamas) should win over +1 for a Bahamian number.
      final bahamas = Countries.fromDialCode('+12421234567');
      expect(bahamas?.isoCode, 'BS');
    });

    test('fromDialCode honours preferred on shared codes', () {
      final preferred = Countries.fromDialCode(
        '+15551234567',
        preferred: Countries.unitedStates,
      );
      expect(preferred, Countries.unitedStates);
    });

    test('parse splits country from national number', () {
      final parsed = Countries.parse('+263 77 123 4567');
      expect(parsed, isNotNull);
      expect(parsed!.country, Countries.zimbabwe);
      expect(parsed.nationalNumber, '771234567');
    });

    test('parse returns null when nothing matches', () {
      expect(Countries.parse('+0000'), isNull);
      expect(Countries.parse('abc'), isNull);
    });
  });
}
