import 'package:flutter/widgets.dart';

import 'subscription_package.dart';

/// Result of a purchase / restore attempt against the (simulated) RevenueCat
/// backend.
enum PurchaseOutcome {
  /// The PRO entitlement is now active.
  purchased,

  /// A prior purchase was found and the entitlement re-activated.
  restored,

  /// No active entitlement was found to restore.
  nothingToRestore,

  /// The user dismissed / aborted the store flow.
  cancelled,

  /// The store flow failed (network, billing, etc.).
  error,
}

/// Immutable snapshot of the RevenueCat subscriber / entitlement state.
///
/// Mirrors the `Subscriber` entity in `app_spec.json`
/// (`rcAnonymousId`, `entitlements (pro active?)`, `expiresAt`, `productId`).
/// Entitlements are device / anonymous scoped — no login is involved.
@immutable
class Entitlement {
  const Entitlement({
    required this.rcAnonymousId,
    required this.isPro,
    this.productId,
    this.expiresAt,
  });

  /// Free (no active entitlement) state for the given anonymous id.
  const Entitlement.free(this.rcAnonymousId)
      : isPro = false,
        productId = null,
        expiresAt = null;

  /// RevenueCat anonymous app-user id (`$RCAnonymousID:<id>`).
  final String rcAnonymousId;

  /// Whether the `PRO` entitlement is currently active.
  final bool isPro;

  /// Product identifier backing the active entitlement, when [isPro].
  final String? productId;

  /// Local expiry of the active entitlement, when known.
  final DateTime? expiresAt;

  Entitlement copyWith({
    bool? isPro,
    String? productId,
    DateTime? expiresAt,
  }) {
    return Entitlement(
      rcAnonymousId: rcAnonymousId,
      isPro: isPro ?? this.isPro,
      productId: productId ?? this.productId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// App-wide subscription / entitlement state holder.
///
/// Stands in for the RevenueCat SDK: it exposes the current PRO [entitlement],
/// the purchasable [offering], and simulated [purchase]/[restorePurchases]
/// flows. Ad-gating ([AdController]) and PRO content gates listen to this so the
/// whole app reacts the instant the entitlement flips.
///
/// This build ships without the native RevenueCat SDK, so entitlement changes
/// are held in memory for the session (not persisted); the purchase/restore
/// methods model the store round-trip with a short delay.
class EntitlementController extends ChangeNotifier {
  EntitlementController({
    String rcAnonymousId = r'$RCAnonymousID:preview',
    List<SubscriptionPackage> offering = kProOffering,
  })  : _entitlement = Entitlement.free(rcAnonymousId),
        offering = List.unmodifiable(offering) {
    _selected = this.offering.isEmpty
        ? null
        : this.offering.firstWhere(
            (p) => p.highlighted,
            orElse: () => this.offering.first,
          );
  }

  /// The `PRO` entitlement identifier used by RevenueCat offerings.
  static const String proEntitlementId = 'PRO';

  /// The packages presented on the paywalls, in display order.
  final List<SubscriptionPackage> offering;

  Entitlement _entitlement;
  Entitlement get entitlement => _entitlement;

  /// Shorthand: whether the PRO entitlement is active.
  bool get isPro => _entitlement.isPro;

  SubscriptionPackage? _selected;

  /// The currently-selected package on the paywall (defaults to the highlighted
  /// one — Weekly "Most Popular").
  SubscriptionPackage? get selectedPackage => _selected;

  bool _purchaseInFlight = false;

  /// True while a purchase / restore round-trip is running (drives spinners).
  bool get purchaseInFlight => _purchaseInFlight;

  SubscriptionPackage? packageById(String id) {
    for (final p in offering) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Select a package on the paywall.
  void selectPackage(SubscriptionPackage package) {
    if (_selected?.id == package.id) return;
    _selected = package;
    notifyListeners();
  }

  /// Attempt to purchase [package] (defaults to [selectedPackage]).
  ///
  /// Simulates the RevenueCat / StoreKit round-trip and, on success, activates
  /// the PRO entitlement for a period matching the package.
  Future<PurchaseOutcome> purchase([SubscriptionPackage? package]) async {
    if (_purchaseInFlight) return PurchaseOutcome.error;
    final target = package ?? _selected;
    if (target == null) return PurchaseOutcome.error;

    _purchaseInFlight = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final now = DateTime.now();
    final expiry = target.period == 'year'
        ? DateTime(now.year + 1, now.month, now.day)
        : now.add(const Duration(days: 7));
    _entitlement = _entitlement.copyWith(
      isPro: true,
      productId: target.productId,
      expiresAt: expiry,
    );
    _purchaseInFlight = false;
    notifyListeners();
    return PurchaseOutcome.purchased;
  }

  /// Restore a previously-purchased entitlement.
  ///
  /// With no persistence there is nothing to restore in a fresh session, so
  /// this reports [PurchaseOutcome.nothingToRestore] unless PRO is already
  /// active this session.
  Future<PurchaseOutcome> restorePurchases() async {
    if (_purchaseInFlight) return PurchaseOutcome.error;
    _purchaseInFlight = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _purchaseInFlight = false;
    notifyListeners();
    return _entitlement.isPro
        ? PurchaseOutcome.restored
        : PurchaseOutcome.nothingToRestore;
  }

  /// Debug / preview affordance: force the entitlement tier directly (used by
  /// preview tooling to demonstrate the ad-free vs. free experience).
  void debugSetPro(bool value) {
    if (_entitlement.isPro == value) return;
    _entitlement = value
        ? _entitlement.copyWith(
            isPro: true,
            productId: _selected?.productId ?? 'pro_weekly',
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          )
        : Entitlement.free(_entitlement.rcAnonymousId);
    notifyListeners();
  }
}

/// Provides an [EntitlementController] to the widget subtree and rebuilds
/// dependents when the entitlement changes.
///
/// ```dart
/// final entitlement = EntitlementScope.of(context);
/// if (!entitlement.isPro) showPaywall();
/// ```
class EntitlementScope extends InheritedNotifier<EntitlementController> {
  const EntitlementScope({
    super.key,
    required EntitlementController controller,
    required super.child,
  }) : super(notifier: controller);

  static EntitlementController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<EntitlementScope>();
    assert(scope?.notifier != null, 'No EntitlementScope found in context');
    return scope!.notifier!;
  }

  /// Read the controller without subscribing to rebuilds.
  static EntitlementController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<EntitlementScope>()
        ?.widget as EntitlementScope?;
    assert(scope?.notifier != null, 'No EntitlementScope found in context');
    return scope!.notifier!;
  }
}
