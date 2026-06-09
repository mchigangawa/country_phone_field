import 'package:flutter/material.dart';
import 'package:phone_number_field/phone_number_field.dart';

void main() => runApp(const ExampleApp());

/// A small gallery app showing several configurations of [PhoneNumberField]:
/// the default outlined style, a borderless/filled style, an underline style,
/// a locked single-country field, a dialog picker, and a fully custom
/// decoration — plus live output and form validation.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF6C5CE7);
    return MaterialApp(
      title: 'phone_number_field demo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: GalleryPage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () => setState(() {
          _themeMode = _themeMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark;
        }),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    required this.isDark,
    required this.onToggleTheme,
    super.key,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final _formKey = GlobalKey<FormState>();
  PhoneNumber? _live;
  String? _submitted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('phone_number_field'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Live output banner.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live output',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Country: ${_live?.country.name ?? '—'}'),
                    Text('National: ${_live?.nationalNumber ?? '—'}'),
                    Text('E.164: ${_live?.completeNumber ?? '—'}'),
                    Text('Valid: ${_live?.isValid ?? false}'),
                    if (_submitted != null) ...[
                      const Divider(),
                      Text('Submitted: $_submitted'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 1. Default outlined, validated, drives the live banner.
            _Section(
              title: '1 · Default (outlined + validation)',
              child: PhoneNumberField(
                initialCountry: Countries.zimbabwe,
                pickerConfig: const CountryPickerConfig(
                  favorites: ['ZW', 'ZA', 'KE', 'NG'],
                ),
                onChanged: (value) => setState(() => _live = value),
              ),
            ),

            // 2. Borderless / filled, rounded.
            _Section(
              title: '2 · Borderless filled',
              child: PhoneNumberField(
                initialCountry: Countries.kenya,
                borderType: PhoneFieldBorderType.none,
                borderRadius: 28,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                labels: const PhoneFieldLabels(labelText: 'Mobile'),
              ),
            ),

            // 3. Underline style, no flag, ISO code instead of dial code.
            _Section(
              title: '3 · Underline · ISO code · no divider',
              child: const PhoneNumberField(
                initialCountry: Countries.unitedStates,
                borderType: PhoneFieldBorderType.underline,
                filled: false,
                selectorStyle: CountrySelectorStyle(
                  showFlag: false,
                  showIsoCode: true,
                  showDivider: false,
                ),
              ),
            ),

            // 4. Locked single country (picker disabled).
            _Section(
              title: '4 · Locked country (mobile-money style)',
              child: const PhoneNumberField(
                lockedCountry: Countries.zimbabwe,
                labels: PhoneFieldLabels(labelText: 'EcoCash number'),
              ),
            ),

            // 5. Dialog picker + custom dropdown icon.
            _Section(
              title: '5 · Dialog picker',
              child: const PhoneNumberField(
                initialCountry: Countries.india,
                pickerConfig: CountryPickerConfig(
                  type: CountryPickerType.dialog,
                ),
                selectorStyle: CountrySelectorStyle(
                  dropdownIcon: Icon(Icons.expand_more, size: 18),
                ),
              ),
            ),

            // 6. Fully custom InputDecoration.
            _Section(
              title: '6 · Fully custom decoration',
              child: PhoneNumberField(
                initialCountry: Countries.nigeria,
                decoration: InputDecoration(
                  labelText: 'WhatsApp',
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.tertiary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(
                    () => _submitted = _live?.completeNumber ?? '(empty)',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Valid! Submitted.')),
                  );
                }
              },
              child: const Text('Validate & submit'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
