import 'package:flutter/material.dart';

import '../models/country.dart';
import '../models/country_picker_config.dart';
import '../models/phone_field_labels.dart';

/// Presents the country picker (bottom sheet or dialog) and resolves to the
/// chosen [Country], or `null` if the user dismissed it.
///
/// This is what the field calls when no custom `pickerBuilder` is supplied, but
/// it is public so you can reuse the same picker elsewhere in your app.
Future<Country?> showCountryPicker({
  required BuildContext context,
  required List<Country> countries,
  required CountryPickerConfig config,
  required PhoneFieldLabels labels,
  Country? selected,
}) {
  switch (config.type) {
    case CountryPickerType.dialog:
      return showDialog<Country>(
        context: context,
        barrierColor: config.barrierColor,
        builder: (context) => Dialog(
          backgroundColor: config.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: config.borderRadius),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 420,
            height: MediaQuery.of(context).size.height * config.maxChildSize,
            child: _CountryPickerBody(
              countries: countries,
              config: config,
              labels: labels,
              selected: selected,
              scrollController: null,
            ),
          ),
        ),
      );
    case CountryPickerType.bottomSheet:
      return showModalBottomSheet<Country>(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            config.backgroundColor ?? Theme.of(context).colorScheme.surface,
        barrierColor: config.barrierColor,
        shape: RoundedRectangleBorder(borderRadius: config.borderRadius),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: config.initialChildSize,
            minChildSize: config.minChildSize,
            maxChildSize: config.maxChildSize,
            expand: false,
            builder: (context, scrollController) => _CountryPickerBody(
              countries: countries,
              config: config,
              labels: labels,
              selected: selected,
              scrollController: scrollController,
            ),
          );
        },
      );
  }
}

/// The searchable list shared by both presentation modes.
class _CountryPickerBody extends StatefulWidget {
  const _CountryPickerBody({
    required this.countries,
    required this.config,
    required this.labels,
    required this.selected,
    required this.scrollController,
  });

  final List<Country> countries;
  final CountryPickerConfig config;
  final PhoneFieldLabels labels;
  final Country? selected;
  final ScrollController? scrollController;

  @override
  State<_CountryPickerBody> createState() => _CountryPickerBodyState();
}

class _CountryPickerBodyState extends State<_CountryPickerBody> {
  late List<Country> _filtered = _ordered();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Countries with favorites pinned to the top, original order otherwise.
  List<Country> _ordered() {
    final favorites = widget.config.favorites
        .map((code) => code.toUpperCase())
        .toList(growable: false);
    if (favorites.isEmpty) return widget.countries;
    final pinned = <Country>[];
    final rest = <Country>[];
    for (final c in widget.countries) {
      (favorites.contains(c.isoCode) ? pinned : rest).add(c);
    }
    pinned.sort(
      (a, b) =>
          favorites.indexOf(a.isoCode).compareTo(favorites.indexOf(b.isoCode)),
    );
    return [...pinned, ...rest];
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _ordered();
      } else {
        _filtered = widget.countries.where((country) {
          return country.name.toLowerCase().contains(q) ||
              country.dialCode.contains(q) ||
              country.isoCode.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = widget.config;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle (bottom sheet affordance).
          if (config.type == CountryPickerType.bottomSheet)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            widget.labels.pickerTitle,
            style:
                config.titleStyle ??
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (config.searchable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration:
                    config.searchDecoration ??
                    InputDecoration(
                      hintText: widget.labels.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            ),
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      widget.labels.noResults,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final country = _filtered[index];
                      final isSelected = country == widget.selected;
                      void select() => Navigator.of(context).pop(country);

                      if (config.itemBuilder != null) {
                        return config.itemBuilder!(
                          context,
                          country,
                          isSelected,
                          select,
                        );
                      }
                      return ListTile(
                        selected: isSelected,
                        leading: config.showFlagInList
                            ? Text(
                                country.flag,
                                style: TextStyle(fontSize: config.flagSize),
                              )
                            : null,
                        title: Text(country.name),
                        trailing: config.showDialCodeInList
                            ? Text(
                                country.dialCode,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                        onTap: select,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
