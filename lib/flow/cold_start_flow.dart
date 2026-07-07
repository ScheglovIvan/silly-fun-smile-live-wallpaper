import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog_controller.dart';
import '../monetization/entitlement_controller.dart';
import '../screens/onboarding_paywall_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';

/// Cold-start orchestrator — the app's boot path.
///
/// Reproduces the native launch sequence (0000 → 0001 → 0002):
///
///  1. **Splash preload (0000)** — the splash bar animates while the catalog
///     first-load runs in the background (`CatalogController.load`, kicked off
///     in [main]). The flow leaves the splash only once *both* the bar animation
///     has finished *and* the catalog is ready (with a safety timeout so a hung
///     network never traps the user on the splash).
///  2. **Onboarding paywall (0001)** — the RevenueCat-style PRO paywall is shown
///     in-place. Dismissing it (Continue, purchase or the close X) advances the
///     flow. PRO users (e.g. a restored entitlement) skip this step entirely.
///  3. **Home (0002)** — the flow hands off to the bottom-tab shell by replacing
///     itself with the `/` route ([MainShell]).
///
/// Splash and paywall are rendered as in-place phases (not pushed routes), so
/// there is no back-stack between them — matching native, where you cannot
/// swipe back from the paywall to the splash. The individual screens remain
/// fully standalone (deep link / `/screen/<id>` web preview); this widget only
/// sequences them for a real cold start.
class ColdStartFlow extends StatefulWidget {
  const ColdStartFlow({super.key});

  @override
  State<ColdStartFlow> createState() => _ColdStartFlowState();
}

enum _Phase { splash, paywall }

class _ColdStartFlowState extends State<ColdStartFlow> {
  _Phase _phase = _Phase.splash;

  /// Guards the splash → next transition so it fires exactly once, whether it
  /// is triggered by the catalog becoming ready or by the safety timeout.
  bool _leftSplash = false;
  Timer? _preloadTimeout;

  /// Longest the flow will sit on the splash waiting for the catalog after the
  /// bar animation has finished, before advancing regardless (offline / slow
  /// network). The seed renders immediately, so Home is never empty.
  static const Duration _preloadGrace = Duration(seconds: 5);

  /// Cached so listeners can be detached in [dispose] without touching
  /// `context` after the element is torn down.
  CatalogController? _catalog;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _catalog = CatalogScope.read(context);
  }

  @override
  void dispose() {
    _preloadTimeout?.cancel();
    _catalog?.removeListener(_onCatalogChanged);
    super.dispose();
  }

  /// The splash preload bar has finished animating. Advance as soon as the
  /// catalog first-load is ready; otherwise wait (bounded) for it.
  void _onSplashPreloaded() {
    if (_leftSplash) return;
    final catalog = _catalog!;
    if (catalog.isReady) {
      _leaveSplash();
      return;
    }
    catalog.addListener(_onCatalogChanged);
    _preloadTimeout = Timer(_preloadGrace, _leaveSplash);
  }

  void _onCatalogChanged() {
    if (_catalog!.isReady) _leaveSplash();
  }

  void _leaveSplash() {
    if (_leftSplash || !mounted) return;
    _leftSplash = true;
    _preloadTimeout?.cancel();
    _catalog!.removeListener(_onCatalogChanged);

    // Already-subscribed users (restored entitlement) skip the onboarding
    // paywall and land straight on Home.
    if (EntitlementScope.read(context).isPro) {
      _finish();
      return;
    }
    setState(() => _phase = _Phase.paywall);
  }

  /// Hand off to the bottom-tab shell (Home). Replacing the flow route with `/`
  /// means the cold-start sequence is not left on the back stack.
  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _phase == _Phase.splash
            ? SplashScreen(
                key: const ValueKey<String>('cold-start-splash'),
                onComplete: _onSplashPreloaded,
              )
            : OnboardingPaywallScreen(
                key: const ValueKey<String>('cold-start-paywall'),
                onComplete: _finish,
              ),
      ),
    );
  }
}
