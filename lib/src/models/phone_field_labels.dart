import 'country.dart';

/// All user-facing strings the field and picker render.
///
/// Override any field to localise or rebrand. The defaults are English. The
/// length-related messages are functions so they can interpolate the selected
/// country and its expected digit count.
class PhoneFieldLabels {
  /// Creates a label set. Every argument has a sensible English default, so you
  /// can override just the pieces you need:
  ///
  /// ```dart
  /// const PhoneFieldLabels(requiredError: 'Numéro requis');
  /// ```
  const PhoneFieldLabels({
    this.labelText = 'Phone Number',
    this.hintText,
    this.searchHint = 'Search country or code…',
    this.pickerTitle = 'Select Country',
    this.requiredError = 'Phone number is required',
    this.invalidError = 'Enter a valid phone number',
    this.noResults = 'No countries found',
    this.lengthError = _defaultLengthError,
  });

  /// Floating/label text of the input.
  final String labelText;

  /// Placeholder shown when the field is empty (optional).
  final String? hintText;

  /// Placeholder of the picker search box.
  final String searchHint;

  /// Title shown at the top of the picker sheet/dialog.
  final String pickerTitle;

  /// Message when the field is empty but required.
  final String requiredError;

  /// Generic invalid-number message (used when length bounds are disabled).
  final String invalidError;

  /// Message when a country search yields nothing.
  final String noResults;

  /// Builds the length-mismatch message for [country]. Receives the country so
  /// it can name it and quote the expected digit count.
  final String Function(Country country) lengthError;

  static String _defaultLengthError(Country country) {
    if (country.minLength == country.maxLength) {
      return 'Enter a valid ${country.name} number '
          '(${country.minLength} digits)';
    }
    return 'Enter a valid ${country.name} number '
        '(${country.minLength}-${country.maxLength} digits)';
  }

  /// Returns a copy with selected fields replaced.
  PhoneFieldLabels copyWith({
    String? labelText,
    String? hintText,
    String? searchHint,
    String? pickerTitle,
    String? requiredError,
    String? invalidError,
    String? noResults,
    String Function(Country country)? lengthError,
  }) {
    return PhoneFieldLabels(
      labelText: labelText ?? this.labelText,
      hintText: hintText ?? this.hintText,
      searchHint: searchHint ?? this.searchHint,
      pickerTitle: pickerTitle ?? this.pickerTitle,
      requiredError: requiredError ?? this.requiredError,
      invalidError: invalidError ?? this.invalidError,
      noResults: noResults ?? this.noResults,
      lengthError: lengthError ?? this.lengthError,
    );
  }
}
