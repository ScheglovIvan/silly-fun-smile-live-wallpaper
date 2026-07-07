import 'package:flutter/widgets.dart';

/// One selectable app display language, as listed in the native Language picker
/// (screen 0004 / `source/0004.json`).
///
/// Carries everything the UI and the app-wide localization layer need:
///  * [code] — a stable key persisted on device and used as the [Locale];
///  * [name] — the label shown in the picker (already localized in-place, e.g.
///    "Deutsch", "عربي");
///  * [flagAsset] — the circular flag rendered in each cell;
///  * [rtl] — whether selecting it flips the whole app to right-to-left
///    (Arabic), per REQ-language-selection.
@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.flagAsset,
    this.countryCode,
    this.rtl = false,
  });

  /// Stable language key (BCP-47 language subtag) persisted across launches.
  final String code;

  /// Optional region subtag (e.g. `BR`, `CA`) so region-specific entries keep
  /// distinct [Locale]s.
  final String? countryCode;

  /// Display label shown in the picker row.
  final String name;

  /// Bundled circular flag asset for this language's row.
  final String flagAsset;

  /// True for right-to-left scripts (Arabic) — drives app-wide [Directionality].
  final bool rtl;

  /// The [Locale] applied to `MaterialApp` when this language is selected.
  Locale get locale =>
      countryCode == null ? Locale(code) : Locale(code, countryCode);

  /// Text direction the whole app adopts when this language is active.
  TextDirection get textDirection =>
      rtl ? TextDirection.rtl : TextDirection.ltr;
}

/// The bundled language catalog, in the exact top-to-bottom order the native
/// `SmileyWallpaper.LanguageCell` table renders them (`source/0004.json`).
///
/// Single source of truth shared by the Language picker (screen 0004) and the
/// app-wide [LocaleController] so the list, flags and applied locales never
/// drift apart.
class AppLanguages {
  AppLanguages._();

  static const String _dir = 'assets/media';

  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage(
      code: 'pt',
      countryCode: 'BR',
      name: 'Português (Brazil)',
      flagAsset:
          '$_dir/efc611f9b3749ed91e3bc5f5463ed432ad06049f9bc1efd1afd21bcdff019827.png',
    ),
    AppLanguage(
      code: 'af',
      name: 'Afrikaans',
      flagAsset:
          '$_dir/f9a6d999806a442ca527645fb6555191859f9e7d2f6492fa8d63188905bf5591.png',
    ),
    AppLanguage(
      code: 'de',
      name: 'Deutsch',
      flagAsset:
          '$_dir/b6e36da060b0d07065c9efcd0a81826f522a12b185204ee697c10d53688f730a.png',
    ),
    AppLanguage(
      code: 'en',
      countryCode: 'CA',
      name: 'Canada',
      flagAsset:
          '$_dir/754b96f45dc625d13d41850e123886af009ceda3557b6323e9d1fc67a91d6619.png',
    ),
    AppLanguage(
      code: 'en',
      name: 'English',
      flagAsset:
          '$_dir/800c07c62f1a3efc14cd94c3bacf2317e8eb174cb5c0df793dba3b9e9da20d96.png',
    ),
    AppLanguage(
      code: 'ko',
      name: 'Korean',
      flagAsset:
          '$_dir/223f0c8c65ccb5bd97af72fa693b42dc7bb9f0eacc0986c64442c20c9875720f.png',
    ),
    AppLanguage(
      code: 'nl',
      name: 'Dutch',
      flagAsset:
          '$_dir/ef7e8f5fa9401f6eb1a161dbde5bd06c28263a9e00fa2d3dd53352db8b0f9006.png',
    ),
    AppLanguage(
      code: 'vi',
      name: 'Vietnamese',
      flagAsset:
          '$_dir/e97ca7a4db045f5f4a58dc57bdaae21efa04fb0bdee76aedce954ba1b770cdc8.png',
    ),
    AppLanguage(
      code: 'ar',
      name: 'عربي',
      rtl: true,
      flagAsset:
          '$_dir/1bc7ce4cc11f099311f953a8f651a7196d3a28c231cec76bccffd888a6c020a6.png',
    ),
  ];

  /// The default language on first launch (English), matching the app's base
  /// localization.
  static const AppLanguage fallback = AppLanguage(
    code: 'en',
    name: 'English',
    flagAsset:
        '$_dir/800c07c62f1a3efc14cd94c3bacf2317e8eb174cb5c0df793dba3b9e9da20d96.png',
  );

  /// A stable identity string for [language] (`code` + optional region), used
  /// as the persistence key and for equality within the picker.
  static String keyOf(AppLanguage language) =>
      language.countryCode == null
          ? language.code
          : '${language.code}_${language.countryCode}';

  /// Resolve a persisted [key] back to a catalog entry, or [fallback].
  static AppLanguage fromKey(String? key) {
    if (key == null) return fallback;
    for (final language in all) {
      if (keyOf(language) == key) return language;
    }
    return fallback;
  }
}
