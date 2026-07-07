import 'dart:async';

import 'package:flutter/material.dart';

import '../monetization/ad_controller.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'preview_screen.dart';

/// Screen 0005 — Home with the interstitial ad gate.
///
/// This is the free-tier "ad gate" the user hits after tapping a wallpaper:
/// the live [HomeScreen] stays visible underneath while a modal loading
/// dialog ("Preparing the ad for you / Please wait in...") is shown, before
/// the interstitial resolves and the preview opens.
///
/// Geometry is taken verbatim from `source/0005.json` — the native
/// `SmileyWallpaper.AdsLoadingView` overlay (measured against the 375pt
/// reference width and scaled to the device):
///  * a full-bleed `#00000080` scrim over the home hub;
///  * a `#1a1a1aff` dialog card at x=75 y=248 w=225 h=172 (corner radius 16);
///  * a centered Urbanist-Medium 16 `#efeff0` two-line label;
///  * a small green Lottie-style loading dot pulsing below it.
///
/// When [nextPreview] is supplied (the browse→apply flow gating a preview
/// open, see `flow/browse_apply_flow.dart`) the gate is *live*: it records the
/// interstitial against the frequency cap, waits while the ad "prepares", then
/// replaces itself with the [PreviewScreen] for that target so back returns to
/// Home. When [nextPreview] is null — the standalone `/#/screen/0005` web
/// preview / deep link — it renders the static gate with no auto-navigation.
class InterstitialScreen extends StatefulWidget {
  const InterstitialScreen({super.key, this.nextPreview});

  /// The preview to open once the interstitial resolves. Null in the standalone
  /// preview so the screen renders as a static snapshot.
  final PreviewArgs? nextPreview;

  /// Native reference width all `source/0005.json` frames are measured in.
  static const double _refWidth = 375;

  /// How long the "Preparing the ad for you" gate is shown before resolving to
  /// the preview (stands in for the interstitial load + display, since this
  /// build ships without a live ad SDK).
  static const Duration _adDuration = Duration(milliseconds: 2200);

  @override
  State<InterstitialScreen> createState() => _InterstitialScreenState();
}

class _InterstitialScreenState extends State<InterstitialScreen> {
  Timer? _resolveTimer;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    // Only auto-resolve when we were opened as a gate in front of a preview.
    if (widget.nextPreview != null) {
      // Count this interstitial against the per-session / interval frequency
      // cap the moment it is presented.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AdScope.read(context).markInterstitialShown();
      });
      _resolveTimer = Timer(InterstitialScreen._adDuration, _openPreview);
    }
  }

  @override
  void dispose() {
    _resolveTimer?.cancel();
    super.dispose();
  }

  /// Interstitial dismissed → replace the gate with the preview so the back
  /// stack is Home → Preview (never Home → Ad → Preview).
  void _openPreview() {
    if (_resolved || !mounted) return;
    _resolved = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/screen/0006'),
        builder: (_) => PreviewScreen(args: widget.nextPreview),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / InterstitialScreen._refWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // The live home hub sits underneath the ad gate.
          const Positioned.fill(child: HomeScreen()),
          // Dimming scrim (#00000080) captured over the whole window.
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color(0x80000000)),
            ),
          ),
          // Centered "Preparing the ad" dialog card.
          Positioned(
            left: 75 * s,
            top: 248 * s,
            width: 225 * s,
            height: 172 * s,
            child: _AdLoadingCard(scale: s),
          ),
        ],
      ),
    );
  }
}

/// The `#1a1a1aff` rounded dialog (225x172, r=16) — label + loading dot.
class _AdLoadingCard extends StatelessWidget {
  const _AdLoadingCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Stack(
        children: [
          // Two-line label — CommonLabel x=83 (8pt into the card) y=248 (top),
          // w=209 h=94, Urbanist-Medium 16, #efeff0.
          Positioned(
            left: 8 * s,
            top: 0,
            width: 209 * s,
            height: 94 * s,
            child: Center(
              child: Text(
                'Preparing the ad for you\nPlease wait in...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFEFEFF0),
                  fontFamily: AppFonts.body,
                  fontSize: 16 * s,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Loading dot container — Lottie animation view at x=153 y=342 (78,94
          // into the card), 70x70. Rendered as a pulsing green dot.
          Positioned(
            left: 78 * s,
            top: 94 * s,
            width: 70 * s,
            height: 70 * s,
            child: Center(child: _LoadingDot(scale: s)),
          ),
        ],
      ),
    );
  }
}

/// A single pulsing green dot standing in for the native Lottie spinner shown
/// while the interstitial loads.
class _LoadingDot extends StatefulWidget {
  const _LoadingDot({required this.scale});

  final double scale;

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = 14 * widget.scale;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0..1..0
        return Opacity(
          opacity: 0.55 + 0.45 * t,
          child: Transform.scale(
            scale: 0.85 + 0.15 * t,
            child: Container(
              width: dot,
              height: dot,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
