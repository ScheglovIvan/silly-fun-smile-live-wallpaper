import 'package:flutter/material.dart';

import '../monetization/entitlement_controller.dart';
import '../monetization/purchase_flow.dart';
import '../theme/app_theme.dart';

/// Screen 0009 — Full PRO subscription paywall (RevenueCatUI
/// `PaywallContainerView`) for **SILLY SMILES PRO**.
///
/// Geometry is taken from `source/0009.json` (375×667 pt, scale 2): a full-bleed
/// wallpaper collage hero fading into the paywall background (#0c0c0c), a
/// branded wordmark + pink PRO badge, subtitle, three benefit rows, and two
/// selectable plan cards (335×74, 20 pt side margins, bg #202821) — Weekly
/// (selected: green outline #64FF77 + glow, "Most Popular" green tab) and
/// Yearly ("Best Value" grey tab) — a "No commitment, cancel anytime"
/// reassurance line, a full-width green "Subcription Now" purchase button
/// (52 pt) and a Terms · Restore · Privacy footer split by vertical bars.
/// Colors and text match `screens/0009.png`. This is the full / scrolled form
/// of the same template as screen 0001.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum _Plan { weekly, yearly }

class _PaywallScreenState extends State<PaywallScreen> {
  // Weekly is the pre-selected, headlined "Most Popular" plan.
  _Plan _selected = _Plan.weekly;

  /// Muted secondary text (subtitle, reassurance, footer links).
  static const Color _muted = Color(0xFF8E8E93);

  /// Tall, dark wallpaper thumbnails bundled under `assets/media/` used to
  /// reconstruct the paywall hero collage (the native node is a SwiftUI-drawn
  /// image with no joined `asset_ref`).
  static const List<List<String>> _collage = <List<String>>[
    <String>['seed_thumb_8', 'seed_thumb_5'],
    <String>['seed_thumb_7', 'seed_thumb_3', 'seed_thumb_9'],
    <String>['seed_thumb_4', 'seed_thumb_6'],
  ];

  /// Dismiss the paywall — RevenueCat's paywall pops back to the crown /
  /// upgrade entry point (or falls through to Home in standalone / preview
  /// mode).
  void _dismiss() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/');
    }
  }

  /// Purchase the selected plan through StoreKit / RevenueCat and unlock PRO.
  /// The screen rebuilds into the [ProUnlockedView] automatically once the
  /// entitlement flips (it subscribes to [EntitlementScope] in [build]).
  Future<void> _purchase() async {
    final controller = EntitlementScope.read(context);
    await runPurchase(
      context,
      controller,
      _selected == _Plan.weekly ? 'weekly' : 'yearly',
    );
  }

  /// Restore a previously-purchased entitlement.
  Future<void> _restore() async {
    await runRestore(context, EntitlementScope.read(context));
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to the entitlement so the paywall reflects the purchase spinner
    // and flips to the unlocked confirmation the instant PRO becomes active.
    final entitlement = EntitlementScope.of(context);
    if (entitlement.isPro) {
      return ProUnlockedView(onContinue: _dismiss);
    }

    final media = MediaQuery.of(context);
    final heroHeight = (media.size.height * 0.44).clamp(280.0, 420.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(heroHeight),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWordmark(),
                  const SizedBox(height: 8),
                  const Text(
                    'Upgrade your vibe with premium wallpapers',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildBenefit(_AdGlyph(), 'Ad-free experience'),
                  const SizedBox(height: 16),
                  _buildBenefit(
                    const Icon(Icons.image_outlined,
                        size: 16, color: AppColors.text),
                    'Ultra HD & 4K quality',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefit(
                    const Icon(Icons.all_inclusive,
                        size: 16, color: AppColors.text),
                    'Unlimited access to all wallpapers',
                  ),
                  const SizedBox(height: 26),
                  _buildPlanCard(
                    plan: _Plan.weekly,
                    title: 'Weekly plan',
                    price: '\$4.99/week',
                    badgeText: 'Most Popular',
                    badgeColor: AppColors.primary,
                    badgeTextColor: AppColors.black,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    plan: _Plan.yearly,
                    title: 'Yearly plan',
                    price: '\$29.99/year',
                    badgeText: 'Best Value',
                    // #FFFFFF80 semi-transparent white → light grey chip.
                    badgeColor: const Color(0x80FFFFFF),
                    badgeTextColor: AppColors.text,
                  ),
                  const SizedBox(height: 20),
                  _buildReassurance(),
                  const SizedBox(height: 16),
                  _buildPurchaseButton(entitlement.purchaseInFlight),
                  const SizedBox(height: 18),
                  _buildFooterLinks(),
                  SizedBox(height: 16 + media.padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Hero collage --------------------------------------------------------

  Widget _buildHero(double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: OverflowBox(
              minHeight: height,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < _collage.length; col++)
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(0, col == 1 ? -26 : 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final name in _collage[col])
                              Padding(
                                padding: const EdgeInsets.all(3),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AspectRatio(
                                    aspectRatio: 0.62,
                                    child: Image.asset(
                                      'assets/media/$name.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Fade the collage into the paywall background at the bottom.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.55, 1.0],
                colors: [
                  Color(0x33000000),
                  Color(0x000C0C0C),
                  AppColors.backgroundAlt,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Wordmark ------------------------------------------------------------

  Widget _buildWordmark() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'SILLY SMILES',
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 30,
              height: 1.0,
              color: AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accentPro,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'PRO',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 16,
              color: AppColors.text,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- Benefit row ---------------------------------------------------------

  Widget _buildBenefit(Widget glyph, String label) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: glyph,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // --- Plan card -----------------------------------------------------------

  Widget _buildPlanCard({
    required _Plan plan,
    required String title,
    required String price,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    final bool selected = _selected == plan;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSelected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0x14FFFFFF),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x3364FF77),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _SelectIndicator(selected: selected),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            price,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = plan),
      child: Padding(
        // Reserve room for the badge that straddles the top-right edge.
        padding: const EdgeInsets.only(top: 9),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            Positioned(
              top: -9,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reassurance ---------------------------------------------------------

  Widget _buildReassurance() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 15, color: AppColors.black),
          ),
          const SizedBox(width: 10),
          const Text(
            'No commitment, cancel anytime',
            style: TextStyle(
              color: _muted,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Purchase CTA --------------------------------------------------------

  Widget _buildPurchaseButton(bool busy) {
    // Retains the source app's in-UI spelling ("Subcription"); swaps to a
    // spinner while the StoreKit round-trip is in flight.
    return PurchaseCtaButton(
      label: 'Subcription Now',
      busy: busy,
      onPressed: _purchase,
    );
  }

  // --- Footer links --------------------------------------------------------

  Widget _buildFooterLinks() {
    const style = TextStyle(
      color: AppColors.text,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    Widget bar() => Container(
          width: 1,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 22),
          color: const Color(0x33FFFFFF),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Terms of Use', style: style),
        bar(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _restore,
          child: Text('Restore', style: style),
        ),
        bar(),
        Text('Privacy Policy', style: style),
      ],
    );
  }
}

/// Green filled check (selected) / hollow ring (unselected) plan indicator.
class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 17, color: AppColors.black),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6E6E73), width: 2),
      ),
    );
  }
}

/// "AD" wordmark glyph used inside the ad-free benefit chip.
class _AdGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'AD',
      style: TextStyle(
        color: AppColors.text,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}
