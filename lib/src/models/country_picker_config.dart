import 'package:flutter/material.dart';

import 'country.dart';

/// How the country picker is presented.
enum CountryPickerType {
  /// A draggable modal bottom sheet (the default).
  bottomSheet,

  /// A centered dialog.
  dialog,
}

/// Configuration for the built-in country picker.
///
/// Tune presentation ([type], [backgroundColor], [borderRadius],
/// [initialChildSize]…), behaviour ([searchable], [favorites]) and rendering
/// ([itemBuilder]). For a completely bespoke experience, bypass this and pass
/// `pickerBuilder` to the field instead.
@immutable
class CountryPickerConfig {
  /// Creates a picker configuration. All fields are optional.
  const CountryPickerConfig({
    this.type = CountryPickerType.bottomSheet,
    this.searchable = true,
    this.showDialCodeInList = true,
    this.showFlagInList = true,
    this.favorites = const [],
    this.backgroundColor,
    this.barrierColor,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
    this.initialChildSize = 0.7,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.95,
    this.titleStyle,
    this.searchDecoration,
    this.itemBuilder,
    this.flagSize = 24,
  });

  /// Whether to show a bottom sheet or a dialog.
  final CountryPickerType type;

  /// Whether the search box is shown.
  final bool searchable;

  /// Whether each list row shows the dial code on the trailing edge.
  final bool showDialCodeInList;

  /// Whether each list row shows the flag on the leading edge.
  final bool showFlagInList;

  /// ISO codes to pin to the top of the list (e.g. `['ZW', 'ZA']`).
  final List<String> favorites;

  /// Sheet/dialog background. Defaults to the theme surface color.
  final Color? backgroundColor;

  /// The modal barrier color.
  final Color? barrierColor;

  /// Corner radius of the sheet/dialog.
  final BorderRadiusGeometry borderRadius;

  /// Initial height fraction of the bottom sheet (0–1).
  final double initialChildSize;

  /// Minimum height fraction of the bottom sheet (0–1).
  final double minChildSize;

  /// Maximum height fraction of the bottom sheet (0–1).
  final double maxChildSize;

  /// Style of the picker title.
  final TextStyle? titleStyle;

  /// Decoration of the search field. When null a sensible filled, rounded
  /// decoration is used.
  final InputDecoration? searchDecoration;

  /// Builds a custom row for [country]. When null the default
  /// flag/name/dial-code [ListTile] is used. Invoke [onTap] to select.
  final Widget Function(
    BuildContext context,
    Country country,
    bool isSelected,
    VoidCallback onTap,
  )?
  itemBuilder;

  /// Flag font size in the list.
  final double flagSize;

  /// Returns a copy with selected fields replaced.
  CountryPickerConfig copyWith({
    CountryPickerType? type,
    bool? searchable,
    bool? showDialCodeInList,
    bool? showFlagInList,
    List<String>? favorites,
    Color? backgroundColor,
    Color? barrierColor,
    BorderRadiusGeometry? borderRadius,
    double? initialChildSize,
    double? minChildSize,
    double? maxChildSize,
    TextStyle? titleStyle,
    InputDecoration? searchDecoration,
    Widget Function(BuildContext, Country, bool, VoidCallback)? itemBuilder,
    double? flagSize,
  }) {
    return CountryPickerConfig(
      type: type ?? this.type,
      searchable: searchable ?? this.searchable,
      showDialCodeInList: showDialCodeInList ?? this.showDialCodeInList,
      showFlagInList: showFlagInList ?? this.showFlagInList,
      favorites: favorites ?? this.favorites,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      barrierColor: barrierColor ?? this.barrierColor,
      borderRadius: borderRadius ?? this.borderRadius,
      initialChildSize: initialChildSize ?? this.initialChildSize,
      minChildSize: minChildSize ?? this.minChildSize,
      maxChildSize: maxChildSize ?? this.maxChildSize,
      titleStyle: titleStyle ?? this.titleStyle,
      searchDecoration: searchDecoration ?? this.searchDecoration,
      itemBuilder: itemBuilder ?? this.itemBuilder,
      flagSize: flagSize ?? this.flagSize,
    );
  }
}
