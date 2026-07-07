import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/catalog_controller.dart';
import '../data/local_collections_controller.dart';
import '../data/models/wallpaper.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen 0007 — Trending featured carousel.
///
/// Rebuilt to match the native "SILLY SMILES" trending page captured in
/// `source/0007.json` (all geometry expressed against the 375pt reference width
/// and scaled to the device / headless-web preview):
///  * the shared fixed top bar — glass settings button (→ Settings), the SILLY
///    SMILES wordmark, and the crown/PRO button (→ Paywall);
///  * a full-bleed `FSPagerView` featured carousel: a large centre card
///    (262×360, r16, 1pt #ffffff1a border over a black video surface) flanked by
///    dimmed (opacity ~0.6), down-scaled peeking neighbours — each card carries a
///    frosted "LIVE" badge (top-left) and a glass heart button (top-right);
///  * the green "Try Now" primary CTA (280×48, r24, #64ff77, black
///    Urbanist-SemiBold 20 label).
///
/// The bottom pill tab-bar is owned by [MainShell]; when this screen is shown
/// standalone via `/screen/0007` it renders just its own content (matching the
/// HomeScreen preview convention).
class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  /// Native reference width all `source/0007.json` frames are measured in.
  static const double _refWidth = 375;

  /// Centre card is 262/375 of the width; the slight extra leaves ~12pt gaps to
  /// the peeking neighbours (native centre card x=56..318, right card x=330).
  static const double _viewportFraction = 0.74;

  late final PageController _controller =
      PageController(viewportFraction: _viewportFraction, initialPage: _initialPage);
  static const int _initialPage = 0;

  double _page = _initialPage.toDouble();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _controller.hasClients ? (_controller.page ?? _page) : _page;
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  List<Wallpaper> _featured(CatalogController catalog) {
    final trending = catalog.trending;
    if (trending.isNotEmpty) return trending;
    return catalog.wallpapers;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    final media = MediaQuery.of(context);
    final s = media.size.width / _refWidth;

    final items = _featured(catalog);
    // Fall back to a handful of empty (black video) cards so the carousel is
    // still shaped correctly before the catalog seed resolves.
    final count = items.isEmpty ? 5 : items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: media.padding.top),
          _Header(scale: s),
          // Featured carousel (native FSPagerView, y=84 h=400).
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: count,
              padEnds: true,
              itemBuilder: (context, i) {
                final wallpaper = i < items.length ? items[i] : null;
                // Distance of this page from the settled centre → drives the
                // scale-down + fade of the neighbouring cards.
                final delta = (i - _page).abs().clamp(0.0, 1.0);
                final scale = 1.0 - 0.35 * delta; // centre 1.0 → sides ~0.65
                final opacity = 1.0 - 0.4 * delta; // centre 1.0 → sides ~0.6
                return Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: _FeaturedCard(scale: s, wallpaper: wallpaper),
                    ),
                  ),
                );
              },
            ),
          ),
          // "Try Now" primary CTA (native y=484 h=48 w=280).
          _TryNowButton(
            scale: s,
            onTap: () {
              final page = _page.round();
              final wallpaper = page < items.length ? items[page] : null;
              if (wallpaper != null) {
                LocalCollectionsScope.read(context).recordView(wallpaper.id);
              }
              Navigator.of(context).pushNamed('/screen/0006');
            },
          ),
          // Space reserved for the shell's floating pill tab-bar.
          SizedBox(height: 24 * s + media.padding.bottom),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar (NavigationCustomView, y=20 h=64) — glass settings button, centred
// wordmark logo, crown/PRO button. Mirrors the shared header used on Home.
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: 64 * s,
      child: Stack(
        children: [
          // Settings — glass circle at x=20 y=16 (relative to the 64pt bar).
          // `start`/`end` so the header mirrors under RTL (Arabic).
          PositionedDirectional(
            start: 20 * s,
            top: 16 * s,
            child: _GlassCircle(
              size: 32 * s,
              onTap: () => Navigator.of(context).pushNamed('/screen/0003'),
              child: Padding(
                padding: EdgeInsets.all(4 * s),
                child: Image.asset(
                  'assets/media/header_settings.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // SILLY SMILES wordmark (187x25) centred.
          Center(
            child: Image.asset(
              'assets/media/header_logo.png',
              height: 25 * s,
              fit: BoxFit.contain,
            ),
          ),
          // Crown / PRO — opens the subscription paywall.
          PositionedDirectional(
            end: 20 * s,
            top: 16 * s,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pushNamed('/screen/0009'),
              child: SizedBox(
                width: 32 * s,
                height: 32 * s,
                child: Padding(
                  padding: EdgeInsets.all(4 * s),
                  child: Image.asset(
                    'assets/media/header_crown.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Featured carousel card (WallpaperCollectionCell) — a black video surface with
// a 1pt #ffffff1a border, rounded r16, carrying a frosted LIVE badge (top-left)
// and a glass heart button (top-right). Centre card is 262x360 in the native.
// ---------------------------------------------------------------------------

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.scale, required this.wallpaper});

  final double scale;
  final Wallpaper? wallpaper;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final local = wallpaper == null ? null : LocalCollectionsScope.of(context);
    final fav = wallpaper != null && local!.isFavourite(wallpaper!.id);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 20 * s),
      child: AspectRatio(
        aspectRatio: 262 / 360,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (wallpaper != null) {
              LocalCollectionsScope.read(context).recordView(wallpaper!.id);
            }
            Navigator.of(context).pushNamed('/screen/0006');
          },
          child: Stack(
            children: [
              // Video surface — black fill, r16, hairline #ffffff1a border.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: AppColors.overlay, width: 1),
                  ),
                ),
              ),
              // LIVE badge (RoundedGlassEffectView), leading-top inset 14pt.
              PositionedDirectional(
                start: 14 * s,
                top: 14 * s,
                child: _LiveBadge(scale: s),
              ),
              // Heart / favourite — glass circle, trailing-top inset ~13pt.
              PositionedDirectional(
                end: 13 * s,
                top: 14 * s,
                child: _GlassCircle(
                  size: 32 * s,
                  onTap: () {
                    if (wallpaper != null) {
                      LocalCollectionsScope.read(context)
                          .toggleFavourite(wallpaper!.id);
                    }
                  },
                  child: Icon(
                    fav ? Icons.favorite : Icons.favorite_border,
                    size: 16 * s,
                    color: fav ? AppColors.primary : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Try Now" primary CTA (SmileyWallpaper.PrimaryButton) — green #64ff77,
// 280x48, r24, black Urbanist-SemiBold 20 label.
// ---------------------------------------------------------------------------

class _TryNowButton extends StatelessWidget {
  const _TryNowButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 280 * s,
          height: 48 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24 * s),
          ),
          child: Text(
            AppStrings.of(context).tryNow,
            style: TextStyle(
              color: AppColors.black,
              fontFamily: AppFonts.body,
              fontSize: 20 * s,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared frosted-glass helpers (local to this screen, matching Home's chrome).
// ---------------------------------------------------------------------------

/// The frosted "LIVE" pill badge (RoundedGlassEffectView) — native centre card
/// badge is 81x32 r16.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * s),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 32 * s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          decoration: BoxDecoration(
            color: AppColors.overlay,
            borderRadius: BorderRadius.circular(16 * s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radio_button_checked,
                  size: 13 * s, color: AppColors.textSecondary),
              SizedBox(width: 5 * s),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: AppFonts.body,
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A frosted-glass circular control (RoundedGlassEffectView) — used for the
/// header settings button and the per-card heart button.
class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.size,
    required this.child,
    this.onTap,
  });

  final double size;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.overlay,
              shape: BoxShape.circle,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
