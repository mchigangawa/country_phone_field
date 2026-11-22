import 'package:cupertino_ui/cupertino_ui.dart';

/// Selects the controls used to render the field.
enum PhoneFieldDesign {
  /// Uses Cupertino controls inside a CupertinoApp and Material elsewhere.
  adaptive,

  /// Always uses Material controls.
  material,

  /// Always uses Cupertino controls.
  cupertino;

  /// Resolves the design for this widget tree.
  bool usesCupertino(BuildContext context) =>
      this == cupertino ||
      (this == adaptive &&
          context.findAncestorWidgetOfExactType<CupertinoApp>() != null);
}
