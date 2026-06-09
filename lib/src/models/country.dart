import 'package:flutter/foundation.dart';

/// An immutable description of a country/territory used by the phone field.
///
/// A [Country] bundles everything the field needs to render the selector,
/// format input and validate a national number:
///
/// * [name] — human readable English name (used by the search/picker).
/// * [isoCode] — ISO 3166-1 alpha-2 code, e.g. `"ZW"`. Also used to derive the
///   [flag] emoji when one is not supplied explicitly.
/// * [dialCode] — international calling code including the leading `+`,
///   e.g. `"+263"`.
/// * [minLength] / [maxLength] — the inclusive bounds, in digits, of a valid
///   *national* (significant) number for the country. These power the built-in
///   length validation and the input length limiter.
///
/// Countries are value types: two instances are equal when their [isoCode] and
/// [dialCode] match, which makes them safe to use in [DropdownButton]s, `Set`s
/// and equality checks.
@immutable
class Country {
  /// Creates a country description.
  ///
  /// Most callers should use the predefined entries exposed by `Countries`
  /// (for example `Countries.zimbabwe`), but this constructor is intentionally
  /// public so you can model territories the package does not ship with, or
  /// override the bundled data (a custom [flag], stricter lengths, a localised
  /// [name], etc.).
  const Country({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    this.minLength = 4,
    this.maxLength = 15,
    String? flag,
  }) : assert(isoCode != '', 'isoCode must not be empty'),
       assert(dialCode != '', 'dialCode must not be empty'),
       assert(minLength >= 0, 'minLength must be >= 0'),
       assert(maxLength >= minLength, 'maxLength must be >= minLength'),
       // ignore: prefer_initializing_formals
       _flag = flag;

  /// English display name, e.g. `"Zimbabwe"`.
  final String name;

  /// ISO 3166-1 alpha-2 code, e.g. `"ZW"`. Always uppercase by convention.
  final String isoCode;

  /// International dialing code including the leading `+`, e.g. `"+263"`.
  final String dialCode;

  /// Minimum number of digits for a valid national number.
  final int minLength;

  /// Maximum number of digits for a valid national number.
  final int maxLength;

  final String? _flag;

  /// The flag emoji for the country.
  ///
  /// When an explicit flag was not supplied to the constructor it is derived
  /// from [isoCode] by mapping each ASCII letter to its
  /// [regional indicator symbol](https://en.wikipedia.org/wiki/Regional_indicator_symbol).
  /// On platforms whose font lacks flag glyphs (notably Windows) this still
  /// renders as the two-letter code, which is an acceptable fallback.
  String get flag => _flag ?? _flagFromIso(isoCode);

  /// The dial code without the leading `+`, e.g. `"263"`.
  String get dialCodeDigits =>
      dialCode.startsWith('+') ? dialCode.substring(1) : dialCode;

  /// Whether [digits] (a national number, digits only) has a length within
  /// this country's [minLength]/[maxLength] bounds.
  bool isValidLength(String digits) =>
      digits.length >= minLength && digits.length <= maxLength;

  /// Returns a copy of this country overriding the given fields. Handy for
  /// tweaking bundled data, e.g. `Countries.unitedStates.copyWith(name: 'USA')`.
  Country copyWith({
    String? name,
    String? isoCode,
    String? dialCode,
    int? minLength,
    int? maxLength,
    String? flag,
  }) {
    return Country(
      name: name ?? this.name,
      isoCode: isoCode ?? this.isoCode,
      dialCode: dialCode ?? this.dialCode,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      flag: flag ?? _flag,
    );
  }

  static String _flagFromIso(String isoCode) {
    if (isoCode.length != 2) return isoCode;
    const base = 0x1F1E6; // regional indicator 'A'
    final upper = isoCode.toUpperCase();
    final first = upper.codeUnitAt(0);
    final second = upper.codeUnitAt(1);
    if (first < 0x41 || first > 0x5A || second < 0x41 || second > 0x5A) {
      return isoCode;
    }
    return String.fromCharCode(base + (first - 0x41)) +
        String.fromCharCode(base + (second - 0x41));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          other.isoCode == isoCode &&
          other.dialCode == dialCode;

  @override
  int get hashCode => Object.hash(isoCode, dialCode);

  @override
  String toString() => 'Country($isoCode, $dialCode, $name)';
}
