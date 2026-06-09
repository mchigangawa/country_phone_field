import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/countries.dart';
import '../models/country.dart';
import '../models/country_picker_config.dart';
import '../models/country_selector_style.dart';
import '../models/phone_field_labels.dart';
import '../models/phone_number.dart';
import 'country_picker.dart';

/// The visual border treatment used when [PhoneNumberField.decoration] is not
/// supplied. For anything more elaborate, pass a full [InputDecoration].
enum PhoneFieldBorderType {
  /// A box outline on all sides (the default).
  outline,

  /// A single underline beneath the field.
  underline,

  /// No border at all — handy for "filled, borderless" designs.
  none,
}

/// A highly customizable international phone number input.
///
/// The field combines a tappable country selector (flag + dial code) with a
/// digits-only text input. It formats and length-limits input per the selected
/// country, validates against that country's length rules, and emits a
/// [PhoneNumber] that keeps the country and national number cleanly separated.
///
/// ### Styling
/// Either lean on the convenience knobs ([borderType], [borderRadius],
/// [filled], [fillColor], [borderColor], [focusedBorderColor]…) or pass a fully
/// custom [decoration] — when you do, your decoration wins and the selector is
/// injected as its `prefixIcon` (unless you set one yourself). The selector
/// itself is configured through [selectorStyle], and the picker through
/// [pickerConfig] (or replaced wholesale via [pickerBuilder]).
///
/// ### Output
/// Listen to [onChanged]/[onSubmitted] for a [PhoneNumber], or integrate with a
/// [Form] using [validator]/[onSaved]. The widget never mutates the country
/// portion of the text — the text controller only ever holds national digits.
///
/// ```dart
/// PhoneNumberField(
///   initialCountry: Countries.zimbabwe,
///   onChanged: (phone) => print(phone.completeNumber), // +263771234567
/// );
/// ```
class PhoneNumberField extends StatefulWidget {
  /// Creates a phone number field.
  const PhoneNumberField({
    super.key,
    this.controller,
    this.initialValue,
    this.initialCountry,
    this.initialCountryCode,
    this.countries,
    this.lockedCountry,
    this.onChanged,
    this.onCountryChanged,
    this.onSubmitted,
    this.onSaved,
    this.validator,
    this.required = true,
    this.validateLength = true,
    this.autovalidateMode,
    this.labels = const PhoneFieldLabels(),
    this.selectorStyle = const CountrySelectorStyle(),
    this.pickerConfig = const CountryPickerConfig(),
    this.pickerBuilder,
    this.decoration,
    this.borderType = PhoneFieldBorderType.outline,
    this.borderRadius = 12,
    this.filled = true,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorColor,
    this.contentPadding,
    this.textStyle,
    this.cursorColor,
    this.textAlign = TextAlign.start,
    this.limitToMaxLength = true,
    this.clearOnCountryChange = false,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.keyboardType = TextInputType.phone,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either a controller or initialValue, not both.',
       );

  /// Controls the national-number text. When omitted, the field creates and
  /// owns one internally. The controller only ever contains digits (no dial
  /// code), so its `.text` is the national number.
  final TextEditingController? controller;

  /// Initial national number (digits) when no [controller] is supplied.
  final String? initialValue;

  /// Country selected on first build. Takes precedence over
  /// [initialCountryCode]. Defaults to [Countries.unitedStates].
  final Country? initialCountry;

  /// ISO 3166-1 alpha-2 code used to pick the initial country when
  /// [initialCountry] is null, e.g. `'ZW'`. Ignored if it doesn't match.
  final String? initialCountryCode;

  /// The set of selectable countries. Defaults to [Countries.all].
  final List<Country>? countries;

  /// When set, the field is pinned to this country and the picker is disabled
  /// (e.g. single-country mobile-money flows). Updating it later moves the
  /// field to the new country.
  final Country? lockedCountry;

  /// Called whenever the number or country changes, with the combined value.
  final ValueChanged<PhoneNumber>? onChanged;

  /// Called whenever the user picks a different country.
  final ValueChanged<Country>? onCountryChanged;

  /// Called when the user submits from the keyboard.
  final ValueChanged<PhoneNumber>? onSubmitted;

  /// Called by [Form.save] with the final value.
  final ValueChanged<PhoneNumber>? onSaved;

  /// Custom validation. Return an error string, or null to accept. Runs before
  /// the built-in required/length checks, so returning null lets them proceed.
  final String? Function(PhoneNumber value)? validator;

  /// Whether an empty value is an error (uses [PhoneFieldLabels.requiredError]).
  final bool required;

  /// Whether to enforce the country's [Country.minLength]/[Country.maxLength].
  final bool validateLength;

  /// When to run validation. Forwarded to the underlying form field.
  final AutovalidateMode? autovalidateMode;

  /// All user-facing strings; override to localise.
  final PhoneFieldLabels labels;

  /// How the country selector (prefix) is rendered.
  final CountrySelectorStyle selectorStyle;

  /// How the built-in picker behaves and looks.
  final CountryPickerConfig pickerConfig;

  /// Replaces the built-in picker entirely. Return the chosen country or null.
  final Future<Country?> Function(
    BuildContext context,
    List<Country> countries,
    Country selected,
  )?
  pickerBuilder;

  /// A fully custom [InputDecoration]. When provided it takes priority over the
  /// convenience styling knobs; the selector is injected as `prefixIcon` unless
  /// the decoration already defines one.
  final InputDecoration? decoration;

  /// Border treatment when [decoration] is null.
  final PhoneFieldBorderType borderType;

  /// Corner radius for [PhoneFieldBorderType.outline]/`none` borders.
  final double borderRadius;

  /// Whether the field background is filled.
  final bool filled;

  /// Fill color when [filled] is true. Defaults to the theme's fill.
  final Color? fillColor;

  /// Idle/enabled border color. Defaults to the theme divider color.
  final Color? borderColor;

  /// Focused border color. Defaults to the color scheme primary.
  final Color? focusedBorderColor;

  /// Error border/text color. Defaults to the color scheme error.
  final Color? errorColor;

  /// Inner content padding of the input.
  final EdgeInsetsGeometry? contentPadding;

  /// Text style of the typed number.
  final TextStyle? textStyle;

  /// Cursor color.
  final Color? cursorColor;

  /// Horizontal alignment of the typed number.
  final TextAlign textAlign;

  /// Whether typing is capped at the country's [Country.maxLength].
  final bool limitToMaxLength;

  /// Whether to clear the number when the country changes. When false (the
  /// default) the number is kept but truncated to the new country's max length.
  final bool clearOnCountryChange;

  /// Extra input formatters applied after the built-in digit/length filters.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether the text is read-only (the picker still works unless disabled).
  final bool readOnly;

  /// Whether to focus the field on first build.
  final bool autofocus;

  /// An external focus node. One is created internally when omitted.
  final FocusNode? focusNode;

  /// The keyboard action button. Defaults to the platform default.
  final TextInputAction? textInputAction;

  /// Keyboard type. Defaults to [TextInputType.phone].
  final TextInputType keyboardType;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  late TextEditingController _controller;
  bool _ownsController = false;
  late Country _country;

  static const BoxConstraints _selectorConstraints = BoxConstraints(
    minWidth: 0,
    minHeight: 0,
  );

  List<Country> get _countries => widget.countries ?? Countries.all;

  bool get _pickerEnabled =>
      widget.enabled && widget.lockedCountry == null && _countries.length > 1;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _ownsController = widget.controller == null;
    _country = _resolveInitialCountry();
    _controller.addListener(_handleTextChanged);
  }

  Country _resolveInitialCountry() {
    if (widget.lockedCountry != null) return widget.lockedCountry!;
    if (widget.initialCountry != null) return widget.initialCountry!;
    final code = widget.initialCountryCode;
    if (code != null) {
      final match = Countries.fromIsoCode(code);
      if (match != null) return match;
    }
    // Prefer a US default if available in the (possibly restricted) list,
    // otherwise fall back to the first available country.
    final list = _countries;
    if (list.contains(Countries.unitedStates)) return Countries.unitedStates;
    return list.isNotEmpty ? list.first : Countries.unitedStates;
  }

  @override
  void didUpdateWidget(PhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Swap controllers if the caller changed them.
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChanged);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
      _ownsController = widget.controller == null;
      _controller.addListener(_handleTextChanged);
    }

    // Honour a (newly) locked country.
    final locked = widget.lockedCountry;
    if (locked != null && locked != _country) {
      _setCountry(locked, notify: false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  PhoneNumber get _value =>
      PhoneNumber(country: _country, nationalNumber: _controller.text);

  void _handleTextChanged() {
    widget.onChanged?.call(_value);
  }

  void _setCountry(Country country, {bool notify = true}) {
    if (country == _country) return;
    setState(() {
      _country = country;
      if (widget.clearOnCountryChange) {
        _controller.clear();
      } else if (widget.limitToMaxLength &&
          _controller.text.length > country.maxLength) {
        _controller.text = _controller.text.substring(0, country.maxLength);
      }
    });
    if (notify) {
      widget.onCountryChanged?.call(country);
      widget.onChanged?.call(_value);
    }
  }

  Future<void> _openPicker() async {
    if (!_pickerEnabled) return;
    FocusScope.of(context).unfocus();
    final Country? picked;
    if (widget.pickerBuilder != null) {
      picked = await widget.pickerBuilder!(context, _countries, _country);
    } else {
      picked = await showCountryPicker(
        context: context,
        countries: _countries,
        config: widget.pickerConfig,
        labels: widget.labels,
        selected: _country,
      );
    }
    if (picked != null) _setCountry(picked);
  }

  // --- Validation -----------------------------------------------------------

  String? _validate(String? raw) {
    final value = PhoneNumber(country: _country, nationalNumber: raw ?? '');
    final custom = widget.validator?.call(value);
    if (custom != null) return custom;
    if (value.isEmpty) {
      return widget.required ? widget.labels.requiredError : null;
    }
    if (widget.validateLength &&
        !_country.isValidLength(value.nationalNumber)) {
      return widget.labels.lengthError(_country);
    }
    return null;
  }

  // --- Selector -------------------------------------------------------------

  Widget _buildSelector(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.selectorStyle;

    final Widget content;
    if (style.builder != null) {
      content = style.builder!(context, _country, _pickerEnabled);
    } else {
      final children = <Widget>[];
      if (style.showFlag) {
        children
          ..add(Text(_country.flag, style: TextStyle(fontSize: style.flagSize)))
          ..add(SizedBox(width: style.spacing));
      }
      if (style.showDialCode) {
        children.add(
          Text(
            _country.dialCode,
            style:
                style.dialCodeStyle ??
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      }
      if (style.showIsoCode) {
        children
          ..add(SizedBox(width: style.spacing / 2))
          ..add(
            Text(
              _country.isoCode,
              style:
                  style.isoCodeStyle ??
                  theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          );
      }
      if (style.showDropdownIcon && _pickerEnabled) {
        children.add(
          style.dropdownIcon ??
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
        );
      }
      if (style.showDivider) {
        children
          ..add(SizedBox(width: style.spacing))
          ..add(
            Container(
              width: style.dividerThickness,
              height: style.dividerHeight,
              color: style.dividerColor ?? theme.dividerColor,
            ),
          );
      }
      content = Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    return InkWell(
      onTap: _pickerEnabled ? _openPicker : null,
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(widget.borderRadius),
      ),
      child: Padding(padding: style.padding, child: content),
    );
  }

  // --- Decoration -----------------------------------------------------------

  InputDecoration _buildDecoration(BuildContext context, Widget selector) {
    final base = widget.decoration;
    if (base != null) {
      return base.copyWith(
        prefixIcon: base.prefixIcon ?? selector,
        prefixIconConstraints:
            base.prefixIconConstraints ?? _selectorConstraints,
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = widget.borderColor ?? theme.dividerColor;
    final focusColor = widget.focusedBorderColor ?? scheme.primary;
    final errorColor = widget.errorColor ?? scheme.error;

    InputBorder border(Color color, double width) {
      switch (widget.borderType) {
        case PhoneFieldBorderType.outline:
          return OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(color: color, width: width),
          );
        case PhoneFieldBorderType.underline:
          return UnderlineInputBorder(
            borderSide: BorderSide(color: color, width: width),
          );
        case PhoneFieldBorderType.none:
          return OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide.none,
          );
      }
    }

    return InputDecoration(
      labelText: widget.labels.labelText,
      hintText: widget.labels.hintText,
      filled: widget.filled,
      fillColor: widget.fillColor,
      contentPadding: widget.contentPadding,
      prefixIcon: selector,
      prefixIconConstraints: _selectorConstraints,
      border: border(borderColor, 1),
      enabledBorder: border(borderColor, 1),
      focusedBorder: border(focusColor, 2),
      errorBorder: border(errorColor, 1),
      focusedErrorBorder: border(errorColor, 2),
    );
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      if (widget.limitToMaxLength)
        LengthLimitingTextInputFormatter(_country.maxLength),
      ...?widget.inputFormatters,
    ];

    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textAlign: widget.textAlign,
      style: widget.textStyle,
      cursorColor: widget.cursorColor,
      autovalidateMode: widget.autovalidateMode,
      inputFormatters: formatters,
      validator: _validate,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(_value),
      onSaved: (_) => widget.onSaved?.call(_value),
      decoration: _buildDecoration(context, _buildSelector(context)),
    );
  }
}
