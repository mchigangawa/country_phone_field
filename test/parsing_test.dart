import 'package:flutter_test/flutter_test.dart';
import 'package:country_phone_field/country_phone_field.dart';

void main() {
  group('Countries.parse (strict)', () {
    test('splits an explicit international number', () {
      final p = Countries.parse('+263 77 123 4567');
      expect(p, isNotNull);
      expect(p!.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
    });

    test('no-plus number resolves when the remainder is a valid length', () {
      final p = Countries.parse('263771234567');
      expect(p?.country, Countries.zimbabwe);
      expect(p?.nationalNumber, '771234567');
    });

    test('bare local number is NOT mistaken for dial code + number', () {
      // Without a +, `771234567` must not split `+7` (Russia) off the front.
      expect(Countries.parse('771234567'), isNull);
    });

    test('+ removes ambiguity even for short remainders', () {
      // With a +, the dial code is trusted regardless of remainder length.
      final p = Countries.parse('+7771234567');
      expect(p, isNotNull);
      expect(p!.country.dialCode, '+7');
    });

    test('longest dial code wins', () {
      expect(Countries.parse('+12421234567')?.country.isoCode, 'BS');
    });

    test('strips a national trunk 0 by default', () {
      final p = Countries.parse('+2630771234567');
      expect(p?.nationalNumber, '771234567');
    });

    test('keeps the trunk 0 when stripTrunkPrefix is false', () {
      final p = Countries.parse('+2630771234567', stripTrunkPrefix: false);
      expect(p?.nationalNumber, '0771234567');
    });

    test('treats 00 as the international prefix', () {
      final p = Countries.parse('00263771234567');
      expect(p?.country, Countries.zimbabwe);
      expect(p?.nationalNumber, '771234567');
    });

    test('within restricts the candidate pool', () {
      // +1 is shared by US and Canada; restrict to Canada only.
      final p = Countries.parse(
        '+12025550123',
        within: [Countries.fromIsoCode('CA')!],
      );
      expect(p?.country, Countries.fromIsoCode('CA')!);
    });

    test('returns null for empty or unmatched input', () {
      expect(Countries.parse(''), isNull);
      expect(Countries.parse('   '), isNull);
      expect(Countries.parse('+00000'), isNull);
      expect(Countries.parse('abc'), isNull);
    });
  });

  group('Countries.parsePhone (fallback)', () {
    test('matched dial code wins over the fallback', () {
      final p = Countries.parsePhone(
        '+263771234567',
        fallback: Countries.kenya,
      );
      expect(p.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
    });

    test('drops a national trunk 0 onto the fallback', () {
      final p = Countries.parsePhone(
        '0771234567',
        fallback: Countries.zimbabwe,
      );
      expect(p.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
    });

    test('bare local number is attributed to the fallback', () {
      final p = Countries.parsePhone('771234567', fallback: Countries.zimbabwe);
      expect(p.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
    });

    test('blank / null input yields the fallback and an empty number', () {
      expect(Countries.parsePhone('', fallback: Countries.kenya), (
        country: Countries.kenya,
        nationalNumber: '',
      ));
      expect(Countries.parsePhone(null, fallback: Countries.kenya), (
        country: Countries.kenya,
        nationalNumber: '',
      ));
    });

    test('handles the 00 international prefix', () {
      final p = Countries.parsePhone(
        '00263771234567',
        fallback: Countries.kenya,
      );
      expect(p.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
    });

    test('within limits which countries can be detected', () {
      // A Kenyan number, but the field only offers Zimbabwe -> falls back.
      final p = Countries.parsePhone(
        '+254712345678',
        fallback: Countries.zimbabwe,
        within: [Countries.zimbabwe],
      );
      expect(p.country, Countries.zimbabwe);
    });
  });

  group('PhoneNumber.parse / tryParse', () {
    test('parse never returns null and uses the fallback', () {
      final p = PhoneNumber.parse('0771234567', fallback: Countries.zimbabwe);
      expect(p.country, Countries.zimbabwe);
      expect(p.nationalNumber, '771234567');
      expect(p.completeNumber, '+263771234567');
    });

    test('parse on blank input is empty but typed to the fallback', () {
      final p = PhoneNumber.parse(null, fallback: Countries.kenya);
      expect(p.country, Countries.kenya);
      expect(p.isEmpty, isTrue);
    });

    test('tryParse strips the trunk 0', () {
      final p = PhoneNumber.tryParse('+2630771234567');
      expect(p?.nationalNumber, '771234567');
    });

    test('tryParse returns null for a bare local number', () {
      expect(PhoneNumber.tryParse('771234567'), isNull);
    });

    test('tryParse honours within', () {
      final p = PhoneNumber.tryParse(
        '+12025550123',
        within: [Countries.fromIsoCode('CA')!],
      );
      expect(p?.country, Countries.fromIsoCode('CA')!);
    });
  });
}
