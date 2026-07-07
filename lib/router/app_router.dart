import 'package:flutter/material.dart';

import '../flow/cold_start_flow.dart';
import '../screens/favourites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/interstitial_screen.dart';
import '../screens/language_screen.dart';
import '../screens/onboarding_paywall_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/preview_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/trending_screen.dart';
import '../shell/main_shell.dart';

/// Central registry mapping a screen `id` (the same ids used in
/// `app_spec.json` / `screens.json`) to the widget that renders it.
///
/// Deep links (`iosforge://screen/<id>`) and the canonical web preview route
/// (`/#/screen/<id>`) both resolve through this map, so every screen must be
/// buildable standalone. Screen-implementation tasks fill in these builders.
class AppScreens {
  AppScreens._();

  static final Map<String, WidgetBuilder> builders = <String, WidgetBuilder>{
    '0000': (_) => const SplashScreen(),
    '0001': (_) => const OnboardingPaywallScreen(),
    '0002': (_) => const HomeScreen(),
    '0003': (_) => const SettingsScreen(),
    '0004': (_) => const LanguageScreen(),
    '0005': (_) => const InterstitialScreen(),
    '0006': (_) => const PreviewScreen(),
    '0007': (_) => const TrendingScreen(),
    '0008': (_) => const FavouritesScreen(),
    '0009': (_) => const PaywallScreen(),
  };

  /// Human-friendly title per id, used for the standalone preview app bar
  /// where a screen has not yet supplied its own chrome.
  static const Map<String, String> titles = <String, String>{
    '0000': 'Splash / Loading',
    '0001': 'Onboarding Paywall',
    '0002': 'Home',
    '0003': 'Settings',
    '0004': 'Language Picker',
    '0005': 'Interstitial Ad',
    '0006': 'Wallpaper Preview',
    '0007': 'Trending',
    '0008': 'Favourites / History',
    '0009': 'Subscription Paywall',
  };
}

/// Routing + deep-link handling for the app. Supports:
///  * the bottom-tab shell at `/`,
///  * `iosforge://screen/<id>` custom-scheme deep links,
///  * the canonical `/screen/:id` web preview route (`/#/screen/<id>`).
class AppRouter {
  AppRouter._();

  static const String scheme = 'iosforge';

  /// The three screens that live inside the bottom-tab [MainShell], mapped to
  /// their tab index. Deep-linking / previewing one of these ids opens the shell
  /// with that tab selected so the persistent tab bar is present (REQ-bottom-nav)
  /// exactly as captured natively (screens/0002, 0007, 0008), instead of the
  /// bare screen with no way to switch tabs.
  static const Map<String, int> tabScreenIndex = <String, int>{
    '0002': 0, // Home
    '0007': 1, // Trending
    '0008': 2, // Favourite
  };

  /// Builds the route for a resolved screen [id]: a bottom-tab shell (with the
  /// matching tab selected) for the three main destinations, otherwise the
  /// stand-alone screen widget.
  static Route<dynamic> _screenRoute(RouteSettings settings, String id) {
    final tabIndex = tabScreenIndex[id];
    if (tabIndex != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => MainShell(initialIndex: tabIndex),
      );
    }
    return MaterialPageRoute<void>(
      settings: settings,
      builder: AppScreens.builders[id]!,
    );
  }

  /// Extracts a known screen id from any incoming route name or deep-link URI.
  ///
  /// Handles `iosforge://screen/0002`, `/screen/0002`, `screen/0002`,
  /// `/0002` and a bare `0002`. Returns `null` when no id is present.
  static String? parseScreenId(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    final segments = <String>[];
    if (uri != null) {
      if (uri.host.isNotEmpty) segments.add(uri.host);
      segments.addAll(uri.pathSegments);
    }
    if (segments.isEmpty) {
      segments.addAll(raw.split(RegExp(r'[/#?]')).where((s) => s.isNotEmpty));
    }

    for (final segment in segments.reversed) {
      if (AppScreens.builders.containsKey(segment)) return segment;
    }
    return null;
  }

  /// [MaterialApp.onGenerateInitialRoutes]. Decides what the app boots into.
  ///
  ///  * A deep link / web-preview URL that targets a specific screen
  ///    (`iosforge://screen/0002`, `/#/screen/0002`) renders that screen
  ///    directly, so headless verification and deep links land exactly where
  ///    asked — with no cold-start sequence in front of them. The three
  ///    bottom-tab destinations (0002/0007/0008) open inside [MainShell] with
  ///    the matching tab selected (see [_screenRoute]).
  ///  * A plain launch (`/`) boots the [ColdStartFlow]: splash preload →
  ///    onboarding paywall → Home.
  ///
  /// A single route is generated (no `/` shell underneath) so the flow owns a
  /// clean stack; the flow later replaces itself with `/` (the shell) via
  /// [onGenerateRoute] once onboarding completes.
  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) {
    final id = parseScreenId(initialRoute);
    if (id != null) {
      return <Route<dynamic>>[
        _screenRoute(RouteSettings(name: initialRoute), id),
      ];
    }
    return <Route<dynamic>>[
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const ColdStartFlow(),
      ),
    ];
  }

  /// [MaterialApp.onGenerateRoute]. Resolves deep links and the web preview
  /// route to the matching screen; everything else falls back to the shell.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final id = parseScreenId(settings.name);

    if (id != null) {
      return _screenRoute(settings, id);
    }

    // Root / unknown -> the bottom-tab shell (Home).
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const MainShell(),
    );
  }

  /// Navigate to a screen by id from anywhere in the app.
  static Future<void> goToScreen(BuildContext context, String id) {
    return Navigator.of(context).pushNamed('/screen/$id');
  }
}
