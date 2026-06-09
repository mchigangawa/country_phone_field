## 0.1.0

Initial release.

* `PhoneNumberField` — a highly customizable international phone input.
* `PhoneNumber` value type that separates the country from the national number,
  with `completeNumber`/`e164`, `isValid`, and `tryParse`.
* `Country` model and `Countries` catalogue (~190 entries) with `fromIsoCode`,
  `fromDialCode` (longest-prefix) and `parse` helpers; flags derived from ISO
  codes.
* Styling: convenience knobs (`borderType` outline/underline/none,
  `borderRadius`, `filled`, colors, padding) plus full `InputDecoration`
  override; `CountrySelectorStyle` for the flag/dial-code prefix.
* Country picker: searchable bottom sheet or dialog, favorites, custom row
  builder (`CountryPickerConfig`), or a fully custom `pickerBuilder`.
* Validation: required + per-country length checks, custom `validator`, and
  `Form` integration via `onSaved`.
* Localizable strings via `PhoneFieldLabels`.
* Lockable to a single country; restrictable to a subset of countries.
* Example gallery app and a full test suite.
