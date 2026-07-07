import 'package:flutter/widgets.dart';

import 'entitlement_controller.dart';

/// The ad formats served to free-tier users (AppLovin MAX / AdMob mediation).
///
/// Maps `monetization.ad_placements` in `app_spec.json`:
///  * [banner] — splash (0000) bottom banner, 375x80.
///  * [native] — embedded feed card in Home/Preview/Favourite (0002/0006/0008),
///    375x330 at y=337.
///  * [interstitial] — full-screen "Preparing the ad for you" before a preview
///    open (0005 → 0006).
///  * [appOpen] — app-open ad on cold start.
///  * [rewarded] — optional unlock of a premium wallpaper for free users (0006).
enum AdFormat { banner, native, interstitial, appOpen, rewarded }

/// App-wide ad-display controller.
///
/// Owns the single rule that separates the free and PRO experiences: **ads are
/// shown only while the [EntitlementController] reports no active PRO
/// entitlement** ("RevenueCat controls whether ads are shown based on
/// entitlement"). It listens to the entitlement so every ad slot in the tree
/// rebuilds the instant PRO is purchased or restored.
///
/// It also holds the interstitial frequency-cap bookkeeping (min interval +
/// per-session cap) so the "Preparing the ad" gate isn't shown on every single
/// preview open, and exposes where a native ad card should be injected into a
/// feed. There is no live ad SDK in this build, so these are gating decisions —
/// the actual ad surfaces are placeholder widgets rendered by the screen tasks.
class AdController extends ChangeNotifier {
  AdController({
    required EntitlementController entitlement,
    this.interstitialMinInterval = const Duration(seconds: 45),
    this.interstitialSessionCap = 6,
    this.nativeAdSlotIndex = 4,
  })  : _entitlement = entitlement,
        _proAtLastNotify = entitlement.isPro {
    _entitlement.addListener(_onEntitlementChanged);
  }

  final EntitlementController _entitlement;

  /// Minimum time between two interstitials (frequency cap, remote-config-like).
  final Duration interstitialMinInterval;

  /// Maximum interstitials shown per app session.
  final int interstitialSessionCap;

  /// Feed index after which a single native ad card is injected (one per feed).
  final int nativeAdSlotIndex;

  DateTime? _lastInterstitialAt;
  int _interstitialsShown = 0;

  bool _proAtLastNotify;

  /// Whether ads should be served at all (free tier only).
  bool get adsEnabled => !_entitlement.isPro;

  /// Whether the given [format] may be displayed right now.
  ///
  /// Every format is suppressed for PRO subscribers (ad-free experience). For
  /// [AdFormat.interstitial] this only reflects the entitlement gate — call
  /// [requestInterstitial] to also apply the frequency cap.
  bool canShow(AdFormat format) => adsEnabled;

  /// Persistent bottom banner on the splash screen (0000).
  bool get showSplashBanner => adsEnabled;

  /// Native ad card embedded in a feed (Home/Preview/Favourite).
  bool get showFeedNativeAd => adsEnabled;

  /// Whether a native ad card should be injected at [index] of a feed of
  /// [itemCount] items (a single card per feed, at [nativeAdSlotIndex] or the
  /// end of a short feed).
  bool shouldInjectNativeAt(int index, int itemCount) {
    if (!showFeedNativeAd || itemCount <= 0) return false;
    final slot = nativeAdSlotIndex < itemCount ? nativeAdSlotIndex : itemCount;
    return index == slot;
  }

  /// How many interstitials remain available this session (0 when capped/PRO).
  int get interstitialsRemaining {
    if (!adsEnabled) return 0;
    final remaining = interstitialSessionCap - _interstitialsShown;
    return remaining < 0 ? 0 : remaining;
  }

  /// Decide whether to gate a preview open behind the interstitial
  /// ("Preparing the ad for you", 0005). Applies the entitlement gate, the
  /// per-session cap and the minimum interval.
  ///
  /// Returns `true` when the caller should route through the interstitial;
  /// callers that get `true` must invoke [markInterstitialShown] once the ad
  /// has been presented.
  bool requestInterstitial() {
    if (!adsEnabled) return false;
    if (_interstitialsShown >= interstitialSessionCap) return false;
    final last = _lastInterstitialAt;
    if (last != null &&
        DateTime.now().difference(last) < interstitialMinInterval) {
      return false;
    }
    return true;
  }

  /// Record that an interstitial (or app-open) ad was presented — updates the
  /// frequency-cap bookkeeping.
  void markInterstitialShown() {
    _lastInterstitialAt = DateTime.now();
    _interstitialsShown++;
    notifyListeners();
  }

  void _onEntitlementChanged() {
    // Only rebuild ad slots when the PRO flag actually flips.
    if (_entitlement.isPro == _proAtLastNotify) return;
    _proAtLastNotify = _entitlement.isPro;
    if (_entitlement.isPro) {
      // Reset caps so a lapse back to free starts clean.
      _lastInterstitialAt = null;
      _interstitialsShown = 0;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _entitlement.removeListener(_onEntitlementChanged);
    super.dispose();
  }
}

/// Provides an [AdController] to the widget subtree and rebuilds ad slots when
/// the gating changes (e.g. PRO purchased → ads disappear).
class AdScope extends InheritedNotifier<AdController> {
  const AdScope({
    super.key,
    required AdController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdScope>();
    assert(scope?.notifier != null, 'No AdScope found in context');
    return scope!.notifier!;
  }

  /// Read the controller without subscribing to rebuilds.
  static AdController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<AdScope>()
        ?.widget as AdScope?;
    assert(scope?.notifier != null, 'No AdScope found in context');
    return scope!.notifier!;
  }
}
