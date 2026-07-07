import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'locale_controller.dart';

/// The small set of UI labels the app renders in chrome the user sees on every
/// screen (the Home toggle, the Favourite/History tabs, the Trending CTA, the
/// Settings list, the native-ad attribution, …).
///
/// This is a lightweight, dependency-free localization table: each supported
/// language from the picker ([AppLanguages]) maps to an [AppStrings] bundle,
/// resolved by language `code` with an English fallback for any language whose
/// bundle isn't provided. Screens read the active bundle through
/// [AppStrings.of], which subscribes to the [LocaleController] so every label
/// re-renders — and, for Arabic, re-lays-out right-to-left — the instant the
/// user picks a language (REQ-language-selection).
@immutable
class AppStrings {
  const AppStrings({
    required this.live,
    required this.fourK,
    required this.favourite,
    required this.history,
    required this.noDataYet,
    required this.tryNow,
    required this.apply,
    required this.ad,
    required this.setting,
    required this.general,
    required this.upgradeNow,
    required this.upgradeTagline,
    required this.rateUs,
    required this.language,
    required this.feedback,
    required this.shareApp,
    required this.privacyPolicy,
  });

  final String live;
  final String fourK;
  final String favourite;
  final String history;
  final String noDataYet;
  final String tryNow;
  final String apply;
  final String ad;
  final String setting;
  final String general;
  final String upgradeNow;
  final String upgradeTagline;
  final String rateUs;
  final String language;
  final String feedback;
  final String shareApp;
  final String privacyPolicy;

  /// Base localization (English) and the fallback for any unmapped language.
  static const AppStrings _en = AppStrings(
    live: 'Live',
    fourK: '4K Wallpaper',
    favourite: 'Favourite',
    history: 'History',
    noDataYet: 'No data yet',
    tryNow: 'Try Now',
    apply: 'Apply',
    ad: 'Ad',
    setting: 'Setting',
    general: 'General',
    upgradeNow: 'Upgrade Now',
    upgradeTagline: 'Upgrade your vibe with premium wallpapers',
    rateUs: 'Rate Us',
    language: 'Language',
    feedback: 'Feedback',
    shareApp: 'Share this app',
    privacyPolicy: 'Privacy Policy',
  );

  static const AppStrings _de = AppStrings(
    live: 'Live',
    fourK: '4K-Hintergrund',
    favourite: 'Favorit',
    history: 'Verlauf',
    noDataYet: 'Noch keine Daten',
    tryNow: 'Jetzt testen',
    apply: 'Anwenden',
    ad: 'Anzeige',
    setting: 'Einstellungen',
    general: 'Allgemein',
    upgradeNow: 'Jetzt upgraden',
    upgradeTagline: 'Werte deinen Style mit Premium-Hintergründen auf',
    rateUs: 'Bewerten',
    language: 'Sprache',
    feedback: 'Feedback',
    shareApp: 'App teilen',
    privacyPolicy: 'Datenschutz',
  );

  static const AppStrings _pt = AppStrings(
    live: 'Live',
    fourK: 'Papel 4K',
    favourite: 'Favorito',
    history: 'Histórico',
    noDataYet: 'Nenhum dado ainda',
    tryNow: 'Testar agora',
    apply: 'Aplicar',
    ad: 'Anúncio',
    setting: 'Configuração',
    general: 'Geral',
    upgradeNow: 'Assinar agora',
    upgradeTagline: 'Eleve seu estilo com papéis de parede premium',
    rateUs: 'Avalie-nos',
    language: 'Idioma',
    feedback: 'Feedback',
    shareApp: 'Compartilhar app',
    privacyPolicy: 'Política de Privacidade',
  );

  static const AppStrings _nl = AppStrings(
    live: 'Live',
    fourK: '4K-wallpaper',
    favourite: 'Favoriet',
    history: 'Geschiedenis',
    noDataYet: 'Nog geen gegevens',
    tryNow: 'Nu proberen',
    apply: 'Toepassen',
    ad: 'Advertentie',
    setting: 'Instellingen',
    general: 'Algemeen',
    upgradeNow: 'Nu upgraden',
    upgradeTagline: 'Upgrade je stijl met premium wallpapers',
    rateUs: 'Beoordeel ons',
    language: 'Taal',
    feedback: 'Feedback',
    shareApp: 'App delen',
    privacyPolicy: 'Privacybeleid',
  );

  /// Arabic — selecting this flips the whole app to right-to-left
  /// ([AppLanguage.rtl]); the localized labels below are what makes that mirror
  /// meaningful rather than cosmetic.
  static const AppStrings _ar = AppStrings(
    live: 'مباشر',
    fourK: 'خلفية 4K',
    favourite: 'المفضلة',
    history: 'السجل',
    noDataYet: 'لا توجد بيانات بعد',
    tryNow: 'جرّب الآن',
    apply: 'تطبيق',
    ad: 'إعلان',
    setting: 'الإعدادات',
    general: 'عام',
    upgradeNow: 'الترقية الآن',
    upgradeTagline: 'طوّر أجواءك بخلفيات مميزة',
    rateUs: 'قيّمنا',
    language: 'اللغة',
    feedback: 'ملاحظات',
    shareApp: 'مشاركة التطبيق',
    privacyPolicy: 'سياسة الخصوصية',
  );

  /// Bundles keyed by BCP-47 language subtag. Languages without an entry
  /// (Afrikaans, Korean, Vietnamese, Canadian English) fall back to [_en].
  static const Map<String, AppStrings> _byCode = {
    'en': _en,
    'de': _de,
    'pt': _pt,
    'nl': _nl,
    'ar': _ar,
  };

  /// The bundle for a given [language] (its `code`), or English.
  static AppStrings forLanguage(AppLanguage language) =>
      _byCode[language.code] ?? _en;

  /// The active bundle, subscribing the caller to language changes so labels
  /// re-render when the picker selection changes.
  static AppStrings of(BuildContext context) =>
      forLanguage(LocaleScope.of(context).language);
}
