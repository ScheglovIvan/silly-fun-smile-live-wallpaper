import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../monetization/ad_controller.dart';
import '../theme/app_theme.dart';
import 'shimmer.dart';

/// The single, shared native-ad placeholder embedded into the free-tier feeds
/// (Home grid — screen 0002 — and the Favourite/History collections — screen
/// 0008; AppLovin MAX / AdMob native format, ~375×330).
///
/// There is no live ad SDK in this build, so the card renders the shimmering
/// "loading native ad" surface the free tier sees: an icon + headline/body
/// skeleton, a large media rectangle and a CTA button, with an "Ad" attribution
/// chip, all sweeping under a [Shimmer].
///
/// Crucially it is **self-gating**: it reads the [AdController] and collapses to
/// nothing the moment PRO is active, so every screen that drops a
/// [NativeAdCard] into its feed inherits the ad-free PRO experience without
/// repeating the entitlement check ("RevenueCat controls whether ads are
/// shown").
class NativeAdCard extends StatelessWidget {
  const NativeAdCard({
    super.key,
    required this.scale,
    this.filled = false,
    this.mediaHeight = 200,
  });

  final double scale;

  /// When true the card sits on its own [AppColors.surface] panel with inset
  /// padding (the Favourite/History layout). When false it renders inline in
  /// the Home grid with a transparent background.
  final bool filled;

  /// Height of the large media rectangle in native points (scaled by [scale]).
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    // Ads (this native slot included) are suppressed entirely for PRO.
    final ads = AdScope.of(context);
    if (!ads.showFeedNativeAd) return const SizedBox.shrink();

    final s = scale;
    final t = AppStrings.of(context);

    final skeleton = Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad header: app icon + headline / body lines.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 48 * s, height: 48 * s, radius: 8 * s),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SkeletonBox(height: 14 * s, radius: 4 * s),
                    SizedBox(height: 8 * s),
                    SkeletonBox(height: 28 * s, radius: 4 * s),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          // Large media surface.
          SkeletonBox(height: mediaHeight * s, radius: 8 * s),
          SizedBox(height: 12 * s),
          // CTA button placeholder.
          SkeletonBox(height: 40 * s, radius: 20 * s),
        ],
      ),
    );

    final card = Stack(
      children: [
        skeleton,
        // "Ad" attribution chip (amber), pinned to the leading top corner and
        // mirrored under RTL. Drawn over the shimmer, not swept by it.
        PositionedDirectional(
          top: 0,
          start: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              color: AppColors.adLabel,
              borderRadius: BorderRadius.circular(3 * s),
            ),
            child: Text(
              t.ad,
              style: TextStyle(
                color: AppColors.black,
                fontFamily: AppFonts.body,
                fontSize: 10 * s,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );

    if (!filled) return card;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md * s),
      ),
      padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 12 * s),
      child: card,
    );
  }
}
