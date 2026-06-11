import '../models/country.dart';

/// The bundled catalogue of countries plus convenient lookup helpers.
///
/// The list ([Countries.all]) is sorted alphabetically by name and is `const`,
/// so referencing it is free. Individual entries are also exposed as static
/// getters (e.g. [Countries.zimbabwe]) for ergonomic defaults:
///
/// ```dart
/// PhoneNumberField(initialCountry: Countries.kenya);
/// ```
///
/// Lengths ([Country.minLength]/[Country.maxLength]) reflect the national
/// significant number (excluding the dial code) and follow the ITU E.164
/// guidance; where a precise value is not widely published a permissive
/// `4..15` default is used. You can always override an entry with
/// [Country.copyWith] or supply your own list to the field.
abstract final class Countries {
  const Countries._();

  /// Every bundled country, sorted by [Country.name].
  static const List<Country> all = _all;

  /// Looks up a country by its ISO 3166-1 alpha-2 code (case-insensitive).
  ///
  /// Returns `null` when no bundled country matches.
  static Country? fromIsoCode(String isoCode) {
    final code = isoCode.toUpperCase();
    for (final c in _all) {
      if (c.isoCode == code) return c;
    }
    return null;
  }

  /// Finds the bundled country whose [Country.dialCode] is the longest prefix
  /// of [input]. `input` may or may not start with `+`.
  ///
  /// Dial codes are not uniquely decodable (e.g. `+1` is shared by the US,
  /// Canada and many Caribbean nations), so when several countries share a
  /// code the first match in catalogue order wins. Pass [preferred] to bias
  /// the result toward a specific country (typically the currently selected
  /// one) when it is among the candidates. Pass [within] to restrict the search
  /// to a subset of countries (e.g. the field's allowed list).
  static Country? fromDialCode(
    String input, {
    Country? preferred,
    Iterable<Country>? within,
  }) {
    final normalized = input.startsWith('+') ? input : '+$input';
    final pool = within ?? _all;
    Country? best;
    for (final c in pool) {
      if (normalized.startsWith(c.dialCode)) {
        if (best == null || c.dialCode.length > best.dialCode.length) {
          best = c;
        } else if (c.dialCode.length == best.dialCode.length &&
            preferred != null &&
            c == preferred) {
          best = c;
        }
      }
    }
    if (preferred != null &&
        best != null &&
        preferred.dialCode == best.dialCode) {
      return preferred;
    }
    return best;
  }

  /// Splits a raw international number into its [Country] and the national
  /// number (digits only), returning `null` when no country can be confidently
  /// determined. Useful for hydrating a field from a stored E.164 string:
  ///
  /// ```dart
  /// final parsed = Countries.parse('+263771234567');
  /// // parsed.country == Countries.zimbabwe, parsed.nationalNumber == '771234567'
  /// ```
  ///
  /// ### Edge cases
  /// * A leading `+` removes ambiguity — any matching dial code is accepted and
  ///   the longest one wins (`+12421234567` → Bahamas, not the US).
  /// * **Without** a `+`, a bare national number must not be mistaken for
  ///   "dial code + number". So `263771234567` resolves to Zimbabwe (the 9
  ///   remaining digits are a valid ZW length), but `771234567` returns `null`
  ///   rather than wrongly splitting `+7` (Russia) off the front.
  /// * Set [stripTrunkPrefix] (default `true`) to drop a single national trunk
  ///   `0` that some regions prefix (`+44 020…` written as `+440…`). This only
  ///   applies to the national remainder, never the dial code.
  /// * Pass [within] to limit matching to a subset of countries — for example a
  ///   field that only offers a handful of countries.
  ///
  /// For a variant that always returns a usable value (falling back to a given
  /// country instead of `null`), see [parsePhone].
  static ({Country country, String nationalNumber})? parse(
    String raw, {
    bool stripTrunkPrefix = true,
    Iterable<Country>? within,
  }) {
    final trimmed = raw.trim();
    var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    var hasPlus = trimmed.startsWith('+');
    // `00` is the international call prefix — treat it like a leading `+`.
    if (!hasPlus && digits.startsWith('00')) {
      hasPlus = true;
      digits = digits.substring(2);
    }
    final country = _matchDialCode(digits, hasPlus: hasPlus, within: within);
    if (country == null) return null;
    final national = _trimTrunk(
      digits.substring(country.dialCodeDigits.length),
      stripTrunkPrefix,
    );
    return (country: country, nationalNumber: national);
  }

  /// Like [parse], but never returns `null`: when no dial code can be matched
  /// the digits are kept and attributed to [fallback], so a field can always be
  /// pre-filled. A blank input yields `(fallback, '')`.
  ///
  /// This is the right tool for hydrating an input from possibly-messy stored
  /// data. It mirrors how a person reads a number:
  ///
  /// ```dart
  /// Countries.parsePhone('+263771234567');  // (Zimbabwe, '771234567')
  /// Countries.parsePhone('0771234567', fallback: Countries.zimbabwe);
  ///   // (Zimbabwe, '771234567')  — national trunk 0 dropped
  /// Countries.parsePhone('771234567', fallback: Countries.zimbabwe);
  ///   // (Zimbabwe, '771234567')  — bare local number, attributed to fallback
  /// Countries.parsePhone('', fallback: Countries.kenya);  // (Kenya, '')
  /// ```
  ///
  /// A leading national `0` is only treated as a trunk prefix when the input
  /// has no `+`; with an explicit dial code the remainder is taken verbatim
  /// (unless [stripTrunkPrefix] strips a trunk 0 from the national part).
  static ({Country country, String nationalNumber}) parsePhone(
    String? raw, {
    Country fallback = unitedStates,
    bool stripTrunkPrefix = true,
    Iterable<Country>? within,
  }) {
    final trimmed = (raw ?? '').trim();
    var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return (country: fallback, nationalNumber: '');
    var hasPlus = trimmed.startsWith('+');
    // `00` is the international call prefix — treat it like a leading `+`.
    if (!hasPlus && digits.startsWith('00')) {
      hasPlus = true;
      digits = digits.substring(2);
    }

    // A leading national 0 with no country code (e.g. `0771234567`) is a local
    // number on the fallback country.
    if (!hasPlus && stripTrunkPrefix && digits.startsWith('0')) {
      return (country: fallback, nationalNumber: digits.substring(1));
    }

    final country = _matchDialCode(digits, hasPlus: hasPlus, within: within);
    if (country != null) {
      final national = _trimTrunk(
        digits.substring(country.dialCodeDigits.length),
        stripTrunkPrefix,
      );
      return (country: country, nationalNumber: national);
    }

    // No recognisable dial code — treat the digits as a local number.
    return (country: fallback, nationalNumber: digits);
  }

  /// Peels a country dial code off the front of [digits] (digits only, no `+`).
  ///
  /// With [hasPlus] any matching dial code is accepted and the longest one
  /// wins. Without it, the remaining digits must be a valid national length for
  /// the candidate, so a bare local number is not mistaken for "code + number".
  static Country? _matchDialCode(
    String digits, {
    required bool hasPlus,
    Iterable<Country>? within,
  }) {
    final pool = within ?? _all;
    Country? best;
    for (final c in pool) {
      final code = c.dialCodeDigits;
      if (!digits.startsWith(code)) continue;
      final restLength = digits.length - code.length;
      if (!hasPlus &&
          !(restLength >= c.minLength && restLength <= c.maxLength)) {
        continue;
      }
      if (best == null || c.dialCode.length > best.dialCode.length) {
        best = c;
      }
    }
    return best;
  }

  /// Drops a single leading national trunk `0` when [enabled].
  static String _trimTrunk(String national, bool enabled) =>
      (enabled && national.startsWith('0')) ? national.substring(1) : national;

  // --- Named accessors for the most commonly used defaults. ---
  static const Country zimbabwe = Country(
    name: 'Zimbabwe',
    isoCode: 'ZW',
    dialCode: '+263',
    minLength: 9,
    maxLength: 9,
  );
  static const Country unitedStates = Country(
    name: 'United States',
    isoCode: 'US',
    dialCode: '+1',
    minLength: 10,
    maxLength: 10,
  );
  static const Country unitedKingdom = Country(
    name: 'United Kingdom',
    isoCode: 'GB',
    dialCode: '+44',
    minLength: 10,
    maxLength: 10,
  );
  static const Country southAfrica = Country(
    name: 'South Africa',
    isoCode: 'ZA',
    dialCode: '+27',
    minLength: 9,
    maxLength: 9,
  );
  static const Country kenya = Country(
    name: 'Kenya',
    isoCode: 'KE',
    dialCode: '+254',
    minLength: 9,
    maxLength: 9,
  );
  static const Country nigeria = Country(
    name: 'Nigeria',
    isoCode: 'NG',
    dialCode: '+234',
    minLength: 8,
    maxLength: 10,
  );
  static const Country india = Country(
    name: 'India',
    isoCode: 'IN',
    dialCode: '+91',
    minLength: 10,
    maxLength: 10,
  );

  static const List<Country> _all = [
    Country(
      name: 'Afghanistan',
      isoCode: 'AF',
      dialCode: '+93',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Albania',
      isoCode: 'AL',
      dialCode: '+355',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Algeria',
      isoCode: 'DZ',
      dialCode: '+213',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Andorra',
      isoCode: 'AD',
      dialCode: '+376',
      minLength: 6,
      maxLength: 9,
    ),
    Country(
      name: 'Angola',
      isoCode: 'AO',
      dialCode: '+244',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Argentina',
      isoCode: 'AR',
      dialCode: '+54',
      minLength: 10,
      maxLength: 11,
    ),
    Country(
      name: 'Armenia',
      isoCode: 'AM',
      dialCode: '+374',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Australia',
      isoCode: 'AU',
      dialCode: '+61',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Austria',
      isoCode: 'AT',
      dialCode: '+43',
      minLength: 7,
      maxLength: 13,
    ),
    Country(
      name: 'Azerbaijan',
      isoCode: 'AZ',
      dialCode: '+994',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Bahamas',
      isoCode: 'BS',
      dialCode: '+1242',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Bahrain',
      isoCode: 'BH',
      dialCode: '+973',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Bangladesh',
      isoCode: 'BD',
      dialCode: '+880',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Barbados',
      isoCode: 'BB',
      dialCode: '+1246',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Belarus',
      isoCode: 'BY',
      dialCode: '+375',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Belgium',
      isoCode: 'BE',
      dialCode: '+32',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Belize',
      isoCode: 'BZ',
      dialCode: '+501',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Benin',
      isoCode: 'BJ',
      dialCode: '+229',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Bhutan',
      isoCode: 'BT',
      dialCode: '+975',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Bolivia',
      isoCode: 'BO',
      dialCode: '+591',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Bosnia and Herzegovina',
      isoCode: 'BA',
      dialCode: '+387',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Botswana',
      isoCode: 'BW',
      dialCode: '+267',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Brazil',
      isoCode: 'BR',
      dialCode: '+55',
      minLength: 10,
      maxLength: 11,
    ),
    Country(
      name: 'Brunei',
      isoCode: 'BN',
      dialCode: '+673',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Bulgaria',
      isoCode: 'BG',
      dialCode: '+359',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Burkina Faso',
      isoCode: 'BF',
      dialCode: '+226',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Burundi',
      isoCode: 'BI',
      dialCode: '+257',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Cambodia',
      isoCode: 'KH',
      dialCode: '+855',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Cameroon',
      isoCode: 'CM',
      dialCode: '+237',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Canada',
      isoCode: 'CA',
      dialCode: '+1',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Cape Verde',
      isoCode: 'CV',
      dialCode: '+238',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Central African Republic',
      isoCode: 'CF',
      dialCode: '+236',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Chad',
      isoCode: 'TD',
      dialCode: '+235',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Chile',
      isoCode: 'CL',
      dialCode: '+56',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'China',
      isoCode: 'CN',
      dialCode: '+86',
      minLength: 11,
      maxLength: 11,
    ),
    Country(
      name: 'Colombia',
      isoCode: 'CO',
      dialCode: '+57',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Comoros',
      isoCode: 'KM',
      dialCode: '+269',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Congo (Brazzaville)',
      isoCode: 'CG',
      dialCode: '+242',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Congo (Kinshasa)',
      isoCode: 'CD',
      dialCode: '+243',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Costa Rica',
      isoCode: 'CR',
      dialCode: '+506',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: "Cote d'Ivoire",
      isoCode: 'CI',
      dialCode: '+225',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Croatia',
      isoCode: 'HR',
      dialCode: '+385',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Cuba',
      isoCode: 'CU',
      dialCode: '+53',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Cyprus',
      isoCode: 'CY',
      dialCode: '+357',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Czech Republic',
      isoCode: 'CZ',
      dialCode: '+420',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Denmark',
      isoCode: 'DK',
      dialCode: '+45',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Djibouti',
      isoCode: 'DJ',
      dialCode: '+253',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Dominican Republic',
      isoCode: 'DO',
      dialCode: '+1809',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Ecuador',
      isoCode: 'EC',
      dialCode: '+593',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Egypt',
      isoCode: 'EG',
      dialCode: '+20',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'El Salvador',
      isoCode: 'SV',
      dialCode: '+503',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Equatorial Guinea',
      isoCode: 'GQ',
      dialCode: '+240',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Eritrea',
      isoCode: 'ER',
      dialCode: '+291',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Estonia',
      isoCode: 'EE',
      dialCode: '+372',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Eswatini',
      isoCode: 'SZ',
      dialCode: '+268',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Ethiopia',
      isoCode: 'ET',
      dialCode: '+251',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Fiji',
      isoCode: 'FJ',
      dialCode: '+679',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Finland',
      isoCode: 'FI',
      dialCode: '+358',
      minLength: 9,
      maxLength: 10,
    ),
    Country(
      name: 'France',
      isoCode: 'FR',
      dialCode: '+33',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Gabon',
      isoCode: 'GA',
      dialCode: '+241',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Gambia',
      isoCode: 'GM',
      dialCode: '+220',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Georgia',
      isoCode: 'GE',
      dialCode: '+995',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Germany',
      isoCode: 'DE',
      dialCode: '+49',
      minLength: 10,
      maxLength: 11,
    ),
    Country(
      name: 'Ghana',
      isoCode: 'GH',
      dialCode: '+233',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Greece',
      isoCode: 'GR',
      dialCode: '+30',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Greenland',
      isoCode: 'GL',
      dialCode: '+299',
      minLength: 6,
      maxLength: 6,
    ),
    Country(
      name: 'Guatemala',
      isoCode: 'GT',
      dialCode: '+502',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Guinea',
      isoCode: 'GN',
      dialCode: '+224',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Guyana',
      isoCode: 'GY',
      dialCode: '+592',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Haiti',
      isoCode: 'HT',
      dialCode: '+509',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Honduras',
      isoCode: 'HN',
      dialCode: '+504',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Hong Kong',
      isoCode: 'HK',
      dialCode: '+852',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Hungary',
      isoCode: 'HU',
      dialCode: '+36',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Iceland',
      isoCode: 'IS',
      dialCode: '+354',
      minLength: 7,
      maxLength: 9,
    ),
    Country(
      name: 'India',
      isoCode: 'IN',
      dialCode: '+91',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Indonesia',
      isoCode: 'ID',
      dialCode: '+62',
      minLength: 9,
      maxLength: 11,
    ),
    Country(
      name: 'Iran',
      isoCode: 'IR',
      dialCode: '+98',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Iraq',
      isoCode: 'IQ',
      dialCode: '+964',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Ireland',
      isoCode: 'IE',
      dialCode: '+353',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Israel',
      isoCode: 'IL',
      dialCode: '+972',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Italy',
      isoCode: 'IT',
      dialCode: '+39',
      minLength: 9,
      maxLength: 10,
    ),
    Country(
      name: 'Jamaica',
      isoCode: 'JM',
      dialCode: '+1876',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Japan',
      isoCode: 'JP',
      dialCode: '+81',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Jordan',
      isoCode: 'JO',
      dialCode: '+962',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Kazakhstan',
      isoCode: 'KZ',
      dialCode: '+7',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Kenya',
      isoCode: 'KE',
      dialCode: '+254',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Kuwait',
      isoCode: 'KW',
      dialCode: '+965',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Kyrgyzstan',
      isoCode: 'KG',
      dialCode: '+996',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Laos',
      isoCode: 'LA',
      dialCode: '+856',
      minLength: 8,
      maxLength: 10,
    ),
    Country(
      name: 'Latvia',
      isoCode: 'LV',
      dialCode: '+371',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Lebanon',
      isoCode: 'LB',
      dialCode: '+961',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Lesotho',
      isoCode: 'LS',
      dialCode: '+266',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Liberia',
      isoCode: 'LR',
      dialCode: '+231',
      minLength: 7,
      maxLength: 9,
    ),
    Country(
      name: 'Libya',
      isoCode: 'LY',
      dialCode: '+218',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Liechtenstein',
      isoCode: 'LI',
      dialCode: '+423',
      minLength: 7,
      maxLength: 9,
    ),
    Country(
      name: 'Lithuania',
      isoCode: 'LT',
      dialCode: '+370',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Luxembourg',
      isoCode: 'LU',
      dialCode: '+352',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Macau',
      isoCode: 'MO',
      dialCode: '+853',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Madagascar',
      isoCode: 'MG',
      dialCode: '+261',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Malawi',
      isoCode: 'MW',
      dialCode: '+265',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Malaysia',
      isoCode: 'MY',
      dialCode: '+60',
      minLength: 9,
      maxLength: 10,
    ),
    Country(
      name: 'Maldives',
      isoCode: 'MV',
      dialCode: '+960',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Mali',
      isoCode: 'ML',
      dialCode: '+223',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Malta',
      isoCode: 'MT',
      dialCode: '+356',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Mauritania',
      isoCode: 'MR',
      dialCode: '+222',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Mauritius',
      isoCode: 'MU',
      dialCode: '+230',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Mexico',
      isoCode: 'MX',
      dialCode: '+52',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Moldova',
      isoCode: 'MD',
      dialCode: '+373',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Monaco',
      isoCode: 'MC',
      dialCode: '+377',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Mongolia',
      isoCode: 'MN',
      dialCode: '+976',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Montenegro',
      isoCode: 'ME',
      dialCode: '+382',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Morocco',
      isoCode: 'MA',
      dialCode: '+212',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Mozambique',
      isoCode: 'MZ',
      dialCode: '+258',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Myanmar',
      isoCode: 'MM',
      dialCode: '+95',
      minLength: 8,
      maxLength: 10,
    ),
    Country(
      name: 'Namibia',
      isoCode: 'NA',
      dialCode: '+264',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Nepal',
      isoCode: 'NP',
      dialCode: '+977',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Netherlands',
      isoCode: 'NL',
      dialCode: '+31',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'New Zealand',
      isoCode: 'NZ',
      dialCode: '+64',
      minLength: 8,
      maxLength: 10,
    ),
    Country(
      name: 'Nicaragua',
      isoCode: 'NI',
      dialCode: '+505',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Niger',
      isoCode: 'NE',
      dialCode: '+227',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Nigeria',
      isoCode: 'NG',
      dialCode: '+234',
      minLength: 8,
      maxLength: 10,
    ),
    Country(
      name: 'North Korea',
      isoCode: 'KP',
      dialCode: '+850',
      minLength: 8,
      maxLength: 10,
    ),
    Country(
      name: 'North Macedonia',
      isoCode: 'MK',
      dialCode: '+389',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Norway',
      isoCode: 'NO',
      dialCode: '+47',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Oman',
      isoCode: 'OM',
      dialCode: '+968',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Pakistan',
      isoCode: 'PK',
      dialCode: '+92',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Palestine',
      isoCode: 'PS',
      dialCode: '+970',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Panama',
      isoCode: 'PA',
      dialCode: '+507',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Papua New Guinea',
      isoCode: 'PG',
      dialCode: '+675',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'Paraguay',
      isoCode: 'PY',
      dialCode: '+595',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Peru',
      isoCode: 'PE',
      dialCode: '+51',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Philippines',
      isoCode: 'PH',
      dialCode: '+63',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Poland',
      isoCode: 'PL',
      dialCode: '+48',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Portugal',
      isoCode: 'PT',
      dialCode: '+351',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Qatar',
      isoCode: 'QA',
      dialCode: '+974',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Romania',
      isoCode: 'RO',
      dialCode: '+40',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Russia',
      isoCode: 'RU',
      dialCode: '+7',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Rwanda',
      isoCode: 'RW',
      dialCode: '+250',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Saudi Arabia',
      isoCode: 'SA',
      dialCode: '+966',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Senegal',
      isoCode: 'SN',
      dialCode: '+221',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Serbia',
      isoCode: 'RS',
      dialCode: '+381',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Seychelles',
      isoCode: 'SC',
      dialCode: '+248',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Sierra Leone',
      isoCode: 'SL',
      dialCode: '+232',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Singapore',
      isoCode: 'SG',
      dialCode: '+65',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Slovakia',
      isoCode: 'SK',
      dialCode: '+421',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Slovenia',
      isoCode: 'SI',
      dialCode: '+386',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Somalia',
      isoCode: 'SO',
      dialCode: '+252',
      minLength: 7,
      maxLength: 8,
    ),
    Country(
      name: 'South Africa',
      isoCode: 'ZA',
      dialCode: '+27',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'South Korea',
      isoCode: 'KR',
      dialCode: '+82',
      minLength: 9,
      maxLength: 10,
    ),
    Country(
      name: 'South Sudan',
      isoCode: 'SS',
      dialCode: '+211',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Spain',
      isoCode: 'ES',
      dialCode: '+34',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Sri Lanka',
      isoCode: 'LK',
      dialCode: '+94',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Sudan',
      isoCode: 'SD',
      dialCode: '+249',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Suriname',
      isoCode: 'SR',
      dialCode: '+597',
      minLength: 6,
      maxLength: 7,
    ),
    Country(
      name: 'Sweden',
      isoCode: 'SE',
      dialCode: '+46',
      minLength: 7,
      maxLength: 13,
    ),
    Country(
      name: 'Switzerland',
      isoCode: 'CH',
      dialCode: '+41',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Syria',
      isoCode: 'SY',
      dialCode: '+963',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Taiwan',
      isoCode: 'TW',
      dialCode: '+886',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Tajikistan',
      isoCode: 'TJ',
      dialCode: '+992',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Tanzania',
      isoCode: 'TZ',
      dialCode: '+255',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Thailand',
      isoCode: 'TH',
      dialCode: '+66',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Togo',
      isoCode: 'TG',
      dialCode: '+228',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Trinidad and Tobago',
      isoCode: 'TT',
      dialCode: '+1868',
      minLength: 7,
      maxLength: 7,
    ),
    Country(
      name: 'Tunisia',
      isoCode: 'TN',
      dialCode: '+216',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Turkey',
      isoCode: 'TR',
      dialCode: '+90',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Turkmenistan',
      isoCode: 'TM',
      dialCode: '+993',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Uganda',
      isoCode: 'UG',
      dialCode: '+256',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Ukraine',
      isoCode: 'UA',
      dialCode: '+380',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'United Arab Emirates',
      isoCode: 'AE',
      dialCode: '+971',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'United Kingdom',
      isoCode: 'GB',
      dialCode: '+44',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'United States',
      isoCode: 'US',
      dialCode: '+1',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Uruguay',
      isoCode: 'UY',
      dialCode: '+598',
      minLength: 8,
      maxLength: 8,
    ),
    Country(
      name: 'Uzbekistan',
      isoCode: 'UZ',
      dialCode: '+998',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Venezuela',
      isoCode: 'VE',
      dialCode: '+58',
      minLength: 10,
      maxLength: 10,
    ),
    Country(
      name: 'Vietnam',
      isoCode: 'VN',
      dialCode: '+84',
      minLength: 9,
      maxLength: 10,
    ),
    Country(
      name: 'Yemen',
      isoCode: 'YE',
      dialCode: '+967',
      minLength: 8,
      maxLength: 9,
    ),
    Country(
      name: 'Zambia',
      isoCode: 'ZM',
      dialCode: '+260',
      minLength: 9,
      maxLength: 9,
    ),
    Country(
      name: 'Zimbabwe',
      isoCode: 'ZW',
      dialCode: '+263',
      minLength: 9,
      maxLength: 9,
    ),
  ];
}
