import 'package:flutter/material.dart';

import 'country.dart';

/// Controls how the country selector (the tappable prefix showing the flag and
/// dial code) is rendered.
///
/// Every visual element can be toggled or restyled, and [builder] lets you
/// replace the whole thing when the knobs are not enough.
@immutable
class CountrySelectorStyle {
  /// Creates a selector style. All parameters are optional; the defaults
  /// reproduce a flag + dial code + dropdown arrow + divider layout.
  const CountrySelectorStyle({
    this.showFlag = true,
    this.showDialCode = true,
    this.showIsoCode = false,
    this.showDropdownIcon = true,
    this.showDivider = true,
    this.flagSize = 22,
    this.spacing = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.dialCodeStyle,
    this.isoCodeStyle,
    this.dropdownIcon,
    this.dividerColor,
    this.dividerThickness = 1,
    this.dividerHeight = 24,
    this.builder,
  });

  /// Whether to show the flag emoji.
  final bool showFlag;

  /// Whether to show the dial code, e.g. `+263`.
  final bool showDialCode;

  /// Whether to show the ISO code, e.g. `ZW` (off by default).
  final bool showIsoCode;

  /// Whether to show the dropdown arrow affordance. Automatically hidden when
  /// the field's country is locked.
  final bool showDropdownIcon;

  /// Whether to draw the vertical divider between the selector and the input.
  final bool showDivider;

  /// Font size of the flag emoji.
  final double flagSize;

  /// Horizontal gap between selector elements.
  final double spacing;

  /// Padding around the selector content.
  final EdgeInsetsGeometry padding;

  /// Text style for the dial code. Falls back to the theme's body text, bold.
  final TextStyle? dialCodeStyle;

  /// Text style for the ISO code when [showIsoCode] is true.
  final TextStyle? isoCodeStyle;

  /// Custom dropdown icon. Defaults to [Icons.arrow_drop_down].
  final Widget? dropdownIcon;

  /// Color of the divider. Defaults to the theme divider color.
  final Color? dividerColor;

  /// Thickness of the divider line.
  final double dividerThickness;

  /// Height of the divider line.
  final double dividerHeight;

  /// Fully custom selector content. When provided, all other fields are
  /// ignored and the returned widget is used verbatim (still wrapped in the
  /// field's tap handler). The bool indicates whether the picker is enabled.
  final Widget Function(BuildContext context, Country country, bool enabled)?
  builder;

  /// Returns a copy with selected fields replaced.
  CountrySelectorStyle copyWith({
    bool? showFlag,
    bool? showDialCode,
    bool? showIsoCode,
    bool? showDropdownIcon,
    bool? showDivider,
    double? flagSize,
    double? spacing,
    EdgeInsetsGeometry? padding,
    TextStyle? dialCodeStyle,
    TextStyle? isoCodeStyle,
    Widget? dropdownIcon,
    Color? dividerColor,
    double? dividerThickness,
    double? dividerHeight,
    Widget Function(BuildContext, Country, bool)? builder,
  }) {
    return CountrySelectorStyle(
      showFlag: showFlag ?? this.showFlag,
      showDialCode: showDialCode ?? this.showDialCode,
      showIsoCode: showIsoCode ?? this.showIsoCode,
      showDropdownIcon: showDropdownIcon ?? this.showDropdownIcon,
      showDivider: showDivider ?? this.showDivider,
      flagSize: flagSize ?? this.flagSize,
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
      dialCodeStyle: dialCodeStyle ?? this.dialCodeStyle,
      isoCodeStyle: isoCodeStyle ?? this.isoCodeStyle,
      dropdownIcon: dropdownIcon ?? this.dropdownIcon,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      dividerHeight: dividerHeight ?? this.dividerHeight,
      builder: builder ?? this.builder,
    );
  }
}
