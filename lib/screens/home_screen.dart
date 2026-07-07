import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/catalog_controller.dart';
import '../data/models/catalog_mode.dart';
import '../data/models/category.dart';
import '../data/models/wallpaper.dart';
import '../flow/browse_apply_flow.dart';
import '../localization/app_strings.dart';
import '../monetization/ad_controller.dart';
import '../data/local_collections_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_card.dart';
import '../widgets/shimmer.dart';

/// Screen 0002 — Home hub.
///
/// Rebuilt to match the native "SILLY SMILES" home hub captured in
/// `source/0002.json` (all geometry is expressed against the 375pt reference
/// width and scaled to the device):
///  * a fixed top bar — glass settings button (→ Settings), the SILLY SMILES
///    wordmark logo, and the crown/PRO button (→ Paywall);
///  * a Live / 4K Wallpaper segmented toggle (green selected pill);
///  * a horizontally-scrolling category chip row (emoji + label, green
///    underline under the active chip);
///  * a 3-column wallpaper grid of tall cards (LIVE badge + heart), with a
///    single native-ad card injected into the free-tier feed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Native reference width all `source/0002.json` frames are measured in.
  static const double _refWidth = 375;

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    final media = MediaQuery.of(context);
    // Scale native (375pt) frames to the real width so the layout matches the
    // captured geometry on any device / in the headless web preview.
    final s = media.size.width / _refWidth;

    final categories = catalog.categories;
    // Native default: the first category (Smoking) is active until the user
    // taps another chip.
    final effectiveCategoryId =
        catalog.selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    final wallpapers = catalog.repository
        .wallpapers(catalog.mode, categoryId: effectiveCategoryId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: media.padding.top),
          _Header(scale: s),
          SizedBox(height: 6 * s),
          _ModeToggle(scale: s, mode: catalog.mode, onChanged: catalog.setMode),
          SizedBox(height: 16 * s),
          _CategoryChips(
            scale: s,
            categories: categories,
            selectedId: effectiveCategoryId,
            onSelect: catalog.selectCategory,
          ),
          SizedBox(height: 12 * s),
          Expanded(
            // Show the shimmering skeleton grid until the catalog resolves its
            // first wallpapers, then swap in the real feed (same cell geometry,
            // so the layout doesn't jump).
            child: wallpapers.isEmpty && !catalog.isReady
                ? WallpaperGridSkeleton(scale: s)
                : _WallpaperGrid(scale: s, wallpapers: wallpapers),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar (NavigationCustomView, y=20 h=64) — glass settings button, centered
// wordmark logo, crown/PRO button.
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
          // SILLY SMILES wordmark (187x25) centered.
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
// Live / 4K Wallpaper segmented toggle (SegmentCustomView).
// Track x=50 w=276 h=44 r=22 bg #64ff771a; selected green pill #64ff77 with
// dark #252525 label.
// ---------------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.scale,
    required this.mode,
    required this.onChanged,
  });

  final double scale;
  final CatalogMode mode;
  final ValueChanged<CatalogMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = AppStrings.of(context);
    return Center(
      child: Container(
        width: 276 * s,
        height: 44 * s,
        padding: EdgeInsets.all(6 * s),
        decoration: BoxDecoration(
          color: AppColors.primaryDim,
          borderRadius: BorderRadius.circular(22 * s),
        ),
        child: Row(
          children: [
            _segment(CatalogMode.live, t.live),
            _segment(CatalogMode.fourK, t.fourK),
          ],
        ),
      ),
    );
  }

  Widget _segment(CatalogMode value, String label) {
    final selected = mode == value;
    final s = scale;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16 * s),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF252525) : const Color(0xFFA6A6A6),
              fontFamily: AppFonts.body,
              fontSize: (selected ? 18 : 16) * s,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip row (CategorySegmentView, y=150 h~28).
// Emoji + label; the active chip is Medium-weight with a green underline.
// ---------------------------------------------------------------------------

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.scale,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final double scale;
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    if (categories.isEmpty) return SizedBox(height: 28 * s);
    return SizedBox(
      height: 28 * s,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20 * s),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 16 * s),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c.id == selectedId;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(c.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.iconEmoji, style: TextStyle(fontSize: 16 * s)),
                    SizedBox(width: 6 * s),
                    Text(
                      c.name,
                      style: TextStyle(
                        color: AppColors.text,
                        fontFamily: AppFonts.body,
                        fontSize: 16 * s,
                        fontWeight:
                            selected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * s),
                // Green underline indicator under the active chip.
                Container(
                  width: 16 * s,
                  height: 4 * s,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2 * s),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wallpaper grid (WallpaperListView) — 3 columns of tall cards (106x185, r=8),
// with a single native-ad card injected into the free-tier feed.
// ---------------------------------------------------------------------------

class _WallpaperGrid extends StatelessWidget {
  const _WallpaperGrid({required this.scale, required this.wallpapers});

  final double scale;
  final List<Wallpaper> wallpapers;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final ads = AdScope.of(context);

    // Chunk wallpapers into rows of three and inject one full-width native ad
    // card after the first row on the free tier (ad_controller gating).
    final rows = <List<Wallpaper>>[];
    for (var i = 0; i < wallpapers.length; i += 3) {
      rows.add(wallpapers.sublist(i, (i + 3).clamp(0, wallpapers.length)));
    }

    final blocks = <Widget>[];
    final colSpacing = 11.0 * s;
    final rowSpacing = 14.0 * s;
    for (var r = 0; r < rows.length; r++) {
      blocks.add(_row(context, rows[r], colSpacing, s));
      if (r < rows.length - 1) blocks.add(SizedBox(height: rowSpacing));
      // Single native ad card after the first full row for free users. The
      // card self-gates on the entitlement, so it collapses for PRO.
      if (r == 0 && ads.showFeedNativeAd) {
        blocks.add(SizedBox(height: rowSpacing));
        blocks.add(NativeAdCard(scale: s, mediaHeight: 210));
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 24 * s),
      children: blocks,
    );
  }

  Widget _row(
    BuildContext context,
    List<Wallpaper> items,
    double colSpacing,
    double s,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: colSpacing),
          Expanded(
            child: i < items.length
                ? _WallpaperCell(scale: s, wallpaper: items[i])
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _WallpaperCell extends StatelessWidget {
  const _WallpaperCell({required this.scale, required this.wallpaper});

  final double scale;
  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final catalog = CatalogScope.of(context);
    final local = LocalCollectionsScope.of(context);
    final fav = local.isFavourite(wallpaper.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Route through the browse→apply flow: free users hit the interstitial
      // gate (0005) first, then the preview (0006) opens focused on this
      // wallpaper in its category. The flow records the History view.
      onTap: () => openWallpaperPreview(
        context,
        categoryId: wallpaper.categoryId,
        wallpaperId: wallpaper.id,
        title: catalog.repository.categoryById(wallpaper.categoryId)?.name,
      ),
      child: AspectRatio(
        aspectRatio: 106 / 185,
        child: Stack(
          children: [
            // Thumbnail — bundled seed asset (offline/web) or CDN thumb.
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8 * s),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0x1A8E8E8E),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8 * s),
                  ),
                  child: Image(
                    image: catalog.media.thumb(wallpaper),
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Image(
                      image: catalog.media.fallback(wallpaper),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            // LIVE badge (Live mode only), leading-top with 6pt inset.
            if (wallpaper.isLive)
              PositionedDirectional(
                start: 6 * s,
                top: 6 * s,
                child: _LiveBadge(scale: s),
              ),
            // Heart / favourite — glass circle, trailing-top with 6pt inset.
            PositionedDirectional(
              end: 6 * s,
              top: 6 * s,
              child: _GlassCircle(
                size: 20 * s,
                onTap: () =>
                    LocalCollectionsScope.read(context).toggleFavourite(wallpaper.id),
                child: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  size: 12 * s,
                  color: fav ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The frosted "LIVE" pill badge (RoundedGlassEffectView) shown on live cells.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8 * s),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 16 * s,
          padding: EdgeInsets.symmetric(horizontal: 6 * s),
          decoration: BoxDecoration(
            color: AppColors.overlay,
            borderRadius: BorderRadius.circular(8 * s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radio_button_checked,
                  size: 9 * s, color: AppColors.textSecondary),
              SizedBox(width: 3 * s),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: AppFonts.body,
                  fontSize: 10 * s,
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
/// header settings button and the per-cell heart button.
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

