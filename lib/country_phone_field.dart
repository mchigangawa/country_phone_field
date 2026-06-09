/// A highly customizable international phone number input field for Flutter.
///
/// The public surface is intentionally small — import this single library to
/// get the widget ([PhoneNumberField]), its value type ([PhoneNumber]), the
/// country model and catalogue ([Country], [Countries]) and the styling /
/// localisation configuration objects.
///
/// ```dart
/// import 'package:country_phone_field/country_phone_field.dart';
///
/// PhoneNumberField(
///   initialCountry: Countries.zimbabwe,
///   onChanged: (phone) {
///     if (phone.isValid) print(phone.completeNumber); // +263771234567
///   },
/// );
/// ```
library;

export 'src/data/countries.dart' show Countries;
export 'src/models/country.dart' show Country;
export 'src/models/country_picker_config.dart'
    show CountryPickerConfig, CountryPickerType;
export 'src/models/country_selector_style.dart' show CountrySelectorStyle;
export 'src/models/phone_field_labels.dart' show PhoneFieldLabels;
export 'src/models/phone_number.dart' show PhoneNumber;
export 'src/widgets/country_picker.dart' show showCountryPicker;
export 'src/widgets/phone_number_field.dart'
    show PhoneNumberField, PhoneFieldBorderType;
