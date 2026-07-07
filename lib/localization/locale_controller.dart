import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

/// App-wide holder for the selected display language (REQ-language-selection:
/// "When the user selects a language in the Language picker, the system shall
/// apply that localization across the app").
///
/// The choice drives `MaterialApp.locale` and the app-wide [Directionality]
/// (right-to-left for Arabic), so every screen re-lays-out the moment a language
/// is picked. State is kept in memory for instant reaction and mirrored to
/// on-device storage (via [SharedPreferences]) so the choice survives relaunch —
/// matching the [Favourite]/History persistence pattern.
///
/// Screens read it through [LocaleScope.of] (subscribes to rebuilds) or
/// [LocaleScope.read] (one-shot). The Language picker (screen 0004) calls
/// [select]; the root [MaterialApp] reads [language] / [locale] / [textDirection].
class LocaleController extends ChangeNotifier {
  LocaleController();

  static const String _key = 'app.language.v1';

  AppLanguage _language = AppLanguages.fallback;
  bool _loaded = false;

  /// The currently applied language (English until a choice is loaded/made).
  AppLanguage get language => _language;

  /// The [Locale] to hand to `MaterialApp.locale`.
  Locale get locale => _language.locale;

  /// App-wide text direction — RTL while Arabic is selected.
  TextDirection get textDirection => _language.textDirection;

  /// The persistence key of the active language, used by the picker to mark the
  /// selected radio.
  String get selectedKey => AppLanguages.keyOf(_language);

  /// True once the persisted choice has been read from storage.
  bool get isLoaded => _loaded;

  /// Hydrate the saved language from on-device storage. Safe to call more than
  /// once — subsequent calls are no-ops. Falls back to English when nothing is
  /// stored or the platform plugin is unavailable (e.g. a headless web render).
  Future<void> load() async {
    if (_loaded) return;
    String? stored;
    try {
      final prefs = await SharedPreferences.getInstance();
      stored = prefs.getString(_key);
    } catch (_) {
      stored = null;
    }
    _language = AppLanguages.fromKey(stored);
    _loaded = true;
    notifyListeners();
  }

  /// Apply [language] app-wide and persist it. No-ops (and does not notify) when
  /// the selection is unchanged, so tapping the already-active row is cheap.
  void select(AppLanguage language) {
    if (AppLanguages.keyOf(language) == AppLanguages.keyOf(_language)) return;
    _language = language;
    notifyListeners();
    _persist(language);
  }

  Future<void> _persist(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, AppLanguages.keyOf(language));
    } catch (_) {
      // Best-effort persistence — ignore write failures (the in-memory choice
      // still applies for this session).
    }
  }
}

/// Provides a [LocaleController] to the subtree and rebuilds dependents (the
/// root [MaterialApp] and the Language picker) when the language changes.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope?.notifier != null, 'No LocaleScope found in context');
    return scope!.notifier!;
  }

  /// Read the controller without subscribing to rebuilds.
  static LocaleController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<LocaleScope>()
        ?.widget as LocaleScope?;
    assert(scope?.notifier != null, 'No LocaleScope found in context');
    return scope!.notifier!;
  }
}
