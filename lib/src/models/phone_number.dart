import 'package:flutter/foundation.dart';

import '../data/countries.dart';
import 'country.dart';

/// The value produced by a phone field: the selected [country] paired with the
/// national number the user typed.
///
/// This is the type handed to `PhoneNumberField.onChanged`, `onSubmitted`,
/// `onSaved` and the `validator`. It deliberately separates the country from
/// the rest of the number so you can store, transmit or display each part on
/// its own — while still offering convenience getters ([completeNumber],
/// [e164]) for the joined form.
@immutable
class PhoneNumber {
  /// Creates a phone number value. [nationalNumber] should contain digits only
  /// (no spaces, dashes or dial code); the field guarantees this for values it
  /// emits.
  const PhoneNumber({required this.country, required this.nationalNumber});

  /// Builds a [PhoneNumber] from a raw international string such as
  /// `'+263 77 123 4567'`, matching the dial code against the bundled (or
  /// supplied) countries. Returns `null` if no country can be matched.
  ///
  /// Pass [resolve] to use a custom country resolver (e.g. when you restrict
  /// the field to a subset of countries).
  static PhoneNumber? tryParse(
    String raw, {
    Country? Function(String dialCodeInput)? resolve,
  }) {
    final trimmed = raw.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final country = (resolve ?? _defaultResolve)('+$digits');
    if (country == null) return null;
    final national = digits.substring(country.dialCodeDigits.length);
    return PhoneNumber(country: country, nationalNumber: national);
  }

  /// The selected country (carries the dial code, flag and length rules).
  final Country country;

  /// The national significant number — digits only, without the dial code.
  final String nationalNumber;

  /// The full international number in E.164 form, e.g. `"+263771234567"`.
  String get completeNumber =>
      nationalNumber.isEmpty ? '' : '${country.dialCode}$nationalNumber';

  /// Alias for [completeNumber]; the canonical E.164 representation.
  String get e164 => completeNumber;

  /// `true` when [nationalNumber] satisfies the country's length bounds.
  ///
  /// This is a length-only heuristic, not a guarantee that the line exists. For
  /// carrier-grade validation pair this with a verification step (e.g. an SMS
  /// OTP) — see the package README.
  bool get isValid =>
      nationalNumber.isNotEmpty && country.isValidLength(nationalNumber);

  /// Whether the user has entered any digits at all.
  bool get isEmpty => nationalNumber.isEmpty;

  /// Inverse of [isEmpty].
  bool get isNotEmpty => nationalNumber.isNotEmpty;

  /// Returns a copy with selected fields replaced.
  PhoneNumber copyWith({Country? country, String? nationalNumber}) {
    return PhoneNumber(
      country: country ?? this.country,
      nationalNumber: nationalNumber ?? this.nationalNumber,
    );
  }

  static Country? _defaultResolve(String input) =>
      Countries.fromDialCode(input);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumber &&
          other.country == country &&
          other.nationalNumber == nationalNumber;

  @override
  int get hashCode => Object.hash(country, nationalNumber);

  @override
  String toString() =>
      'PhoneNumber(${country.isoCode}, national: $nationalNumber, e164: $completeNumber)';
}
