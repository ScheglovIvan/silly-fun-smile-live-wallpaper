import 'package:flutter/material.dart';

import '../data/local_collections_controller.dart';
import '../monetization/ad_controller.dart';
import '../screens/interstitial_screen.dart';
import '../screens/preview_screen.dart';

/// Browse → apply flow orchestrator (app_spec workflow "Browse and apply a
/// wallpaper", REQ-interstitial-before-preview / REQ-preview-and-apply).
///
/// Sequences the native tap-a-thumbnail path (0002 → 0005 → 0006):
///
///  1. Record the tapped wallpaper in local History (feeds the Favourite /
///     History screen).
///  2. Ask the [AdController] whether a free-tier user should be gated by the
///     "Preparing the ad for you" interstitial (0005). The controller applies
///     the entitlement gate, per-session cap and minimum-interval frequency cap,
///     so PRO users — and free users who have just seen an interstitial — skip
///     straight to the preview.
///  3. Open the full-screen swipeable preview (0006) focused on the tapped
///     wallpaper, from which the user can Apply / set it.
///
/// When gated, the interstitial is *pushed* over Home and then *replaces itself*
/// with the preview once the ad resolves, so pressing back from the preview
/// returns to Home (not to the ad gate) — matching native.
///
/// This is the single entry point every "open this wallpaper" affordance
/// (Home grid cell, and later Trending / Favourite / History) should call, so
/// the ad-gate rule lives in exactly one place.
Future<void> openWallpaperPreview(
  BuildContext context, {
  String? categoryId,
  String? wallpaperId,
  String? title,
}) {
  // Opening a wallpaper counts as viewing it — record it for History.
  if (wallpaperId != null && wallpaperId.isNotEmpty) {
    LocalCollectionsScope.read(context).recordView(wallpaperId);
  }

  final args = PreviewArgs(
    categoryId: categoryId,
    wallpaperId: wallpaperId,
    title: title,
  );

  final navigator = Navigator.of(context);
  final ads = AdScope.read(context);

  // Free-tier users hitting the frequency cap window get the interstitial gate;
  // everyone else (PRO, or within the cap cooldown) opens the preview directly.
  if (ads.requestInterstitial()) {
    return navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/screen/0005'),
        builder: (_) => InterstitialScreen(nextPreview: args),
      ),
    );
  }

  return navigator.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/screen/0006'),
      builder: (_) => PreviewScreen(args: args),
    ),
  );
}
