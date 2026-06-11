## 0.2.0-beta.1

Smarter parsing and input handling for real-world numbers, plus documentation
screenshots. No breaking API changes. Beta — please report any issues before
the stable `0.2.0`.

### Added
* **Auto-detect country on paste/type** — pasting a full international number
  (`+263771234567`, or `00263771234567` with the international call prefix)
  selects the matching country and strips the dial code, leaving only the
  national digits. On by default; opt out with `autoDetectCountry: false`.
  Only countries in the field's list are considered.
* **National trunk `0` handling** — a leading `0` (e.g. `0771234567`) is dropped
  to the national significant number. Toggle with `stripNationalPrefix`.
* **E.164 hydration via `initialValue`** — when `initialValue` starts with `+`
  (or `00`) the field parses it: the country is detected and only the national
  digits are placed in the input. National `initialValue` keeps working.
* **`Countries.parsePhone(...)`** and **`PhoneNumber.parse(...)`** — non-null
  parsers that fall back to a given country instead of returning `null`, so a
  field can always be pre-filled from messy stored data.
* `within:` parameter on `Countries.parse`, `Countries.fromDialCode` and
  `PhoneNumber.tryParse` to restrict matching to a subset of countries.
* `stripTrunkPrefix:` parameter on `Countries.parse` / `PhoneNumber.tryParse`.
* Real device screenshots in `screenshots/` and a pub.dev screenshot gallery.

### Changed
* **`Countries.parse` no longer mis-splits a bare local number.** Without a `+`,
  a number is only treated as "dial code + number" when the remainder is a valid
  national length for the candidate, so `771234567` returns `null` instead of
  wrongly peeling off `+7` (Russia). With a `+`, matching is unchanged
  (longest dial code wins).
* `PhoneNumber.tryParse` now strips a leading trunk `0` by default and routes
  through the improved matcher.

## 0.1.1

* Maintenance release validating the automated publishing pipeline. No
  functional or API changes to the widget.

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
