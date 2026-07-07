/// A purchasable RevenueCat subscription package shown on the paywalls.
///
/// Mirrors the two products captured in `app_spec.json`
/// (`monetization.packages`): **Weekly PRO (Most Popular)** at `$4.99/week` and
/// **Yearly PRO (Best Value)** at `$29.99/year`. Both unlock the identical PRO
/// entitlement (ad-free, Ultra HD & 4K, unlimited access) — only the billing
/// period and marketing badge differ.
class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    required this.period,
    required this.includes,
    this.badge,
    this.highlighted = false,
  });

  /// Stable identifier used by the UI / analytics (`weekly`, `yearly`).
  final String id;

  /// RevenueCat / App Store product identifier reported in a purchase.
  final String productId;

  /// Display name, e.g. `Weekly PRO`.
  final String title;

  /// Formatted price string exactly as merchandised, e.g. `$4.99`.
  final String price;

  /// Billing period unit (`week` | `year`).
  final String period;

  /// Feature bullets unlocked by the package (all packages unlock the same PRO
  /// entitlement, so these match `monetization.free_vs_premium` premium tier).
  final List<String> includes;

  /// Optional merchandising badge (`Most Popular`, `Best Value`).
  final String? badge;

  /// Whether this package is visually promoted as the default selection.
  final bool highlighted;

  /// `$4.99 / week` — convenience label for a plan row.
  String get pricePerPeriod => '$price / $period';
}

/// The default PRO offering — the ordered list of packages presented on the
/// onboarding paywall (0001) and the full paywall (0009).
///
/// Kept as static data (rather than fetched) because there is no live
/// RevenueCat SDK in this build; the prices/badges are the real observed values.
const List<SubscriptionPackage> kProOffering = <SubscriptionPackage>[
  SubscriptionPackage(
    id: 'weekly',
    productId: 'pro_weekly',
    title: 'Weekly PRO',
    price: '\$4.99',
    period: 'week',
    badge: 'Most Popular',
    highlighted: true,
    includes: <String>[
      'Ad-free experience',
      'Ultra HD & 4K quality',
      'Unlimited access to all wallpapers',
    ],
  ),
  SubscriptionPackage(
    id: 'yearly',
    productId: 'pro_yearly',
    title: 'Yearly PRO',
    price: '\$29.99',
    period: 'year',
    badge: 'Best Value',
    includes: <String>[
      'Ad-free experience',
      'Ultra HD & 4K quality',
      'Unlimited access to all wallpapers',
    ],
  ),
];
