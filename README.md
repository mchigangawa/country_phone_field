# country_phone_field

A **highly customizable** international phone number input field for Flutter.

Pick a country from a searchable picker, type a number that is automatically
filtered and length-limited for that country, validate it, and get back a clean
[`PhoneNumber`](#the-phonenumber-output) value that keeps the **country
separated from the rest of the number**.

- 🌍 Bundled catalogue of ~190 countries (flag, dial code, ISO code, length rules)
- 🎨 Style it any way you like — outlined, underlined, filled, **borderless**, or a fully custom `InputDecoration`
- 🔎 Searchable country picker (bottom sheet **or** dialog), favorites, custom rows, or your own picker entirely
- ✅ Built-in required + per-country length validation, or bring your own `validator`
- 📦 Emits E.164 (`+263771234567`) **and** the parts (`country` + `nationalNumber`) separately
- 🔒 Lockable to a single country (e.g. mobile-money flows)
- 🌗 Theme-aware (light/dark) out of the box, fully overridable
- 🌐 Every user-facing string is overridable for localization

## Install

```yaml
dependencies:
  country_phone_field: ^0.1.0
```

```dart
import 'package:country_phone_field/country_phone_field.dart';
```

## Quick start

```dart
PhoneNumberField(
  initialCountry: Countries.zimbabwe,
  onChanged: (phone) {
    print(phone.country.isoCode);   // ZW
    print(phone.nationalNumber);    // 771234567
    print(phone.completeNumber);    // +263771234567  (E.164)
    print(phone.isValid);           // true
  },
);
```

## The `PhoneNumber` output

Every callback (`onChanged`, `onSubmitted`, `onSaved`, `validator`) gives you a
`PhoneNumber`, which separates the country from the number:

| Member | Description |
| --- | --- |
| `country` | The selected `Country` (dial code, flag, ISO code, length rules) |
| `nationalNumber` | The number the user typed — **digits only, no dial code** |
| `completeNumber` / `e164` | Joined E.164 form, e.g. `+263771234567` |
| `isValid` | `true` when the length matches the country's rules |
| `isEmpty` / `isNotEmpty` | Whether any digits were entered |

Hydrate a field from a stored E.164 string:

```dart
final parsed = PhoneNumber.tryParse('+263771234567');
// parsed.country == Countries.zimbabwe, parsed.nationalNumber == '771234567'
```

## Validation & verification

`PhoneNumberField` validates **length** against the selected country's
`minLength`/`maxLength` and integrates with `Form`:

```dart
final formKey = GlobalKey<FormState>();

Form(
  key: formKey,
  child: PhoneNumberField(
    initialCountry: Countries.kenya,
    required: true,           // empty => error (default)
    validateLength: true,     // enforce per-country digit count (default)
    onSaved: (phone) => _store(phone.completeNumber),
    validator: (phone) {      // optional: runs first, wins if it returns a message
      if (phone.nationalNumber.startsWith('0')) return 'Drop the leading 0';
      return null;
    },
  ),
);

if (formKey.currentState!.validate()) {
  formKey.currentState!.save();
}
```

> **Note on verification.** Length validation is a fast structural check, *not*
> proof that a line exists. For real verification, pair this field with an SMS
> OTP (or similar) step using `phone.completeNumber`.

## Styling — pick your level

### 1. Convenience knobs (no `InputDecoration` needed)

```dart
PhoneNumberField(
  borderType: PhoneFieldBorderType.outline,   // outline | underline | none
  borderRadius: 12,
  filled: true,
  fillColor: Colors.white,
  borderColor: Colors.grey,
  focusedBorderColor: Colors.indigo,
  errorColor: Colors.red,
  contentPadding: EdgeInsets.all(16),
  textStyle: TextStyle(fontSize: 16),
  cursorColor: Colors.indigo,
);
```

**Borderless / filled** is just `borderType: PhoneFieldBorderType.none` with
`filled: true`. **Underlined** is `PhoneFieldBorderType.underline`.

### 2. Fully custom `InputDecoration`

When you pass `decoration`, it wins — the country selector is injected as the
`prefixIcon` (unless you set one yourself):

```dart
PhoneNumberField(
  decoration: InputDecoration(
    labelText: 'WhatsApp',
    filled: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.teal),
    ),
  ),
);
```

### 3. The selector (flag + dial code prefix)

```dart
PhoneNumberField(
  selectorStyle: CountrySelectorStyle(
    showFlag: true,
    showDialCode: true,
    showIsoCode: false,
    showDropdownIcon: true,
    showDivider: true,
    flagSize: 22,
    dialCodeStyle: TextStyle(fontWeight: FontWeight.bold),
    dropdownIcon: Icon(Icons.expand_more),
    // ...or replace it entirely:
    builder: (context, country, enabled) => Text(country.flag),
  ),
);
```

## The country picker

```dart
PhoneNumberField(
  pickerConfig: CountryPickerConfig(
    type: CountryPickerType.bottomSheet,   // or .dialog
    searchable: true,
    favorites: ['ZW', 'ZA', 'KE', 'NG'],   // pinned to the top
    initialChildSize: 0.7,
    backgroundColor: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    itemBuilder: (context, country, isSelected, onTap) => ListTile(
      onTap: onTap,
      title: Text('${country.flag}  ${country.name}'),
    ),
  ),
);
```

Or replace the picker completely:

```dart
PhoneNumberField(
  pickerBuilder: (context, countries, selected) async {
    return await myCustomCountryChooser(context, countries);
  },
);
```

## Lock to a single country

```dart
PhoneNumberField(
  lockedCountry: Countries.zimbabwe, // picker disabled, dropdown arrow hidden
  labels: PhoneFieldLabels(labelText: 'EcoCash number'),
);
```

## Restrict / extend the catalogue

```dart
// Only a subset:
PhoneNumberField(countries: [Countries.kenya, Countries.zimbabwe, Countries.southAfrica]);

// Look things up:
Countries.fromIsoCode('ZW');        // Country?
Countries.fromDialCode('+263...');  // longest-prefix match
Countries.parse('+263771234567');   // (country, nationalNumber)

// Customize an entry or add your own:
final c = Countries.zimbabwe.copyWith(name: 'Zim');
const custom = Country(name: 'Narnia', isoCode: 'NA', dialCode: '+999', minLength: 6, maxLength: 8);
```

## Localization

Every string is overridable:

```dart
PhoneNumberField(
  labels: PhoneFieldLabels(
    labelText: 'Numéro de téléphone',
    searchHint: 'Rechercher…',
    pickerTitle: 'Choisir un pays',
    requiredError: 'Numéro requis',
    lengthError: (c) => 'Numéro ${c.name} invalide',
  ),
);
```

## Responsiveness

The field expands to its parent's width and the selector sizes to its content,
so it adapts to phones, tablets and web. Constrain it with normal layout
widgets (`SizedBox`, `Expanded`, `ConstrainedBox`, etc.). The picker uses a
draggable sheet on small screens and works as a centered dialog (`type:
CountryPickerType.dialog`) on larger ones.

## Example

A full gallery (six styles, live output, theme toggle, form validation) lives in
[`example/`](example/lib/main.dart):

```bash
cd example && flutter run
```

## API surface

`PhoneNumberField`, `PhoneNumber`, `Country`, `Countries`,
`CountrySelectorStyle`, `CountryPickerConfig`, `CountryPickerType`,
`PhoneFieldLabels`, `PhoneFieldBorderType`, `showCountryPicker`.

## License

See [LICENSE](LICENSE).
