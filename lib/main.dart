import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/catalog_controller.dart';
import 'data/local_collections_controller.dart';
import 'localization/app_language.dart';
import 'localization/locale_controller.dart';
import 'monetization/ad_controller.dart';
import 'monetization/entitlement_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fixed dark UI — force a light (white) status/nav icon set over the
  // near-black background regardless of system appearance.
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const SillySmilesApp());
}

/// Root of the "SILLY SMILES" wallpaper app.
///
/// * Applies the single fixed dark [AppTheme] (Urbanist body / Future Edge
///   display fonts bundled in pubspec).
/// * Boots via [AppRouter.onGenerateInitialRoutes]: a plain launch enters the
///   [ColdStartFlow] (splash preload → onboarding paywall → Home), while a deep
///   link / `/#/screen/<id>` web-preview URL renders that screen standalone.
/// * Subsequent navigation flows through [AppRouter.onGenerateRoute], which
///   resolves the bottom-tab shell at `/`, `iosforge://screen/<id>` deep links,
///   and the canonical `/screen/:id` web preview route (`/#/screen/<id>`).
/// * Owns the app-wide [CatalogController] (wallpaper catalog data layer) and
///   exposes it to every screen through [CatalogScope]; the catalog begins
///   loading (seed first, then remote CDN manifest) on startup.
/// * Owns the [EntitlementController] (RevenueCat PRO subscription state) and
///   the [AdController] (banner/native/interstitial ad-gating), exposed through
///   [EntitlementScope] / [AdScope]; ads are shown only while there is no
///   active PRO entitlement.
class SillySmilesApp extends StatefulWidget {
  const SillySmilesApp({super.key});

  @override
  State<SillySmilesApp> createState() => _SillySmilesAppState();
}

class _SillySmilesAppState extends State<SillySmilesApp> {
  late final CatalogController _catalog;
  late final EntitlementController _entitlement;
  late final AdController _ads;
  late final LocalCollectionsController _local;
  late final LocaleController _locale;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogController();
    // Fire-and-forget: renders the bundled seed immediately, then refreshes
    // from the remote CDN manifest when reachable.
    _catalog.load();
    // Subscription entitlement + ad-gating. The ad controller derives its
    // gating from the entitlement, so it must be built after it.
    _entitlement = EntitlementController();
    _ads = AdController(entitlement: _entitlement);
    // Per-device Favourites & History; hydrate from on-device storage.
    _local = LocalCollectionsController();
    _local.load();
    // App-wide display language; hydrate the persisted choice so the app boots
    // in the language (and text direction) last selected.
    _locale = LocaleController();
    _locale.load();
  }

  @override
  void dispose() {
    _ads.dispose();
    _entitlement.dispose();
    _local.dispose();
    _catalog.dispose();
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntitlementScope(
      controller: _entitlement,
      child: AdScope(
        controller: _ads,
        child: CatalogScope(
          controller: _catalog,
          child: LocalCollectionsScope(
            controller: _local,
            // App-wide language selection sits above MaterialApp so a change in
            // the Language picker (screen 0004) rebuilds the whole app with the
            // new locale + text direction (REQ-language-selection).
            child: LocaleScope(
              controller: _locale,
              child: AnimatedBuilder(
                animation: _locale,
                builder: (context, _) => MaterialApp(
                  title: 'Silly Fun Smile Live Wallpaper',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.dark,
                  darkTheme: AppTheme.dark,
                  themeMode: ThemeMode.dark,
                  // The selected display language and the locales the picker
                  // offers.
                  locale: _locale.locale,
                  supportedLocales: <Locale>[
                    for (final language in AppLanguages.all) language.locale,
                  ],
                  // Apply the language's direction to the entire widget tree so
                  // selecting Arabic flips the UI to right-to-left.
                  builder: (context, child) => Directionality(
                    textDirection: _locale.textDirection,
                    child: child ?? const SizedBox.shrink(),
                  ),
                  initialRoute: '/',
                  onGenerateInitialRoutes: AppRouter.onGenerateInitialRoutes,
                  onGenerateRoute: AppRouter.onGenerateRoute,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
