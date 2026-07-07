import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/catalog_controller.dart';
import '../data/local_collections_controller.dart';
import '../data/models/wallpaper.dart';
import '../localization/app_strings.dart';
import '../monetization/ad_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_card.dart';

/// Screen 0008 — Favourites / History.
///
/// Rebuilt to match the native "SILLY SMILES" collections screen captured in
/// `source/0008.json` (all geometry is expressed against the 375pt reference
/// width and scaled to the device):
///  * the shared top bar — glass settings button (→ Settings), the SILLY SMILES
///    wordmark logo, and the crown/PRO button (→ Paywall);
///  * a "Favourite" / "History" sub-tab segment (CategorySegmentView, y=100) —
///    the active label is Medium-weight with a short green underline;
///  * the per-tab list (WallpaperListView, y=152): a grid of the user's saved /
///    recently-viewed wallpapers, or the empty state — a glowing green heart
///    over a "No data yet" caption — when the collection is empty;
///  * a single native-ad surface pinned to the bottom of the free-tier feed
///    (AdsSDK.NativeAdViewContainer, y=337).
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  /// Native reference width all `source/0008.json` frames are measured in.
  static const double _refWidth = 375;

  /// 0 = Favourite, 1 = History.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Scale native (375pt) frames to the real width so the layout matches the
    // captured geometry on any device / in the headless web preview.
    final s = media.size.width / _refWidth;

    final catalog = CatalogScope.of(context);
    final local = LocalCollectionsScope.of(context);

    final ids = _tab == 0 ? local.favouriteIds : local.historyIds;
    final wallpapers = catalog.resolveIds(ids);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: media.padding.top),
          _Header(scale: s),
          SizedBox(height: 16 * s),
          _SubTabs(
            scale: s,
            index: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          SizedBox(height: 16 * s),
          // WallpaperListView (y=152 h=515) — the per-tab content sits above the
          // native ad, which overlaps the bottom of the empty state exactly as
          // captured in the source hierarchy.
          Expanded(
            child: _TabBody(scale: s, wallpapers: wallpapers),
          ),
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
// Sub-tab segment (CategorySegmentView, y=100 h=36). "Favourite" and "History"
// labels sit at x=20 / x=101; the active one is Urbanist-Medium with a short
// green underline (n17, 16x4) beneath it, the inactive one Urbanist-Regular.
// ---------------------------------------------------------------------------

class _SubTabs extends StatelessWidget {
  const _SubTabs({
    required this.scale,
    required this.index,
    required this.onSelect,
  });

  final double scale;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = AppStrings.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tab(0, t.favourite),
          SizedBox(width: 16 * s),
          _tab(1, t.history),
        ],
      ),
    );
  }

  Widget _tab(int i, String label) {
    final s = scale;
    final selected = i == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.text,
              fontFamily: AppFonts.body,
              fontSize: 16 * s,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          SizedBox(height: 4 * s),
          // Green underline indicator (n17) under the active tab only.
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
  }
}

// ---------------------------------------------------------------------------
// Per-tab content (WallpaperListView). Renders the collection grid when the
// active tab has entries, otherwise the empty state; a native ad is pinned to
// the bottom for the free tier, overlapping the empty state as in the capture.
// ---------------------------------------------------------------------------

class _TabBody extends StatelessWidget {
  const _TabBody({required this.scale, required this.wallpapers});

  final double scale;
  final List<Wallpaper> wallpapers;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final ads = AdScope.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: wallpapers.isEmpty
              ? _EmptyState(scale: s)
              : _CollectionGrid(scale: s, wallpapers: wallpapers),
        ),
        if (ads.showFeedNativeAd)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 * s,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * s),
              child: NativeAdCard(scale: s, filled: true),
            ),
          ),
      ],
    );
  }
}

/// Empty state — the glowing green heart (media m03a51089b2fe897, 164x164) over
/// a "No data yet" caption (#747474, Urbanist-Regular 16).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    // Heart top is at native y=196 within the y=152 list → ~44pt down; nudge the
    // block toward the upper centre to match the capture.
    return Padding(
      padding: EdgeInsets.only(top: 44 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/media/favourites_heart.png',
            width: 164 * s,
            height: 164 * s,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 10 * s),
          Text(
            AppStrings.of(context).noDataYet,
            style: TextStyle(
              color: const Color(0xFF747474),
              fontFamily: AppFonts.body,
              fontSize: 16 * s,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// A 3-column grid of the collection's wallpapers, matching the Home feed cell
/// (106x185, r=8) so saved / recently-viewed items read consistently.
class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({required this.scale, required this.wallpapers});

  final double scale;
  final List<Wallpaper> wallpapers;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final rows = <List<Wallpaper>>[];
    for (var i = 0; i < wallpapers.length; i += 3) {
      rows.add(wallpapers.sublist(i, (i + 3).clamp(0, wallpapers.length)));
    }

    final colSpacing = 11.0 * s;
    final rowSpacing = 14.0 * s;
    final blocks = <Widget>[];
    for (var r = 0; r < rows.length; r++) {
      blocks.add(_row(rows[r], colSpacing, s));
      if (r < rows.length - 1) blocks.add(SizedBox(height: rowSpacing));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 120 * s),
      children: blocks,
    );
  }

  Widget _row(List<Wallpaper> items, double colSpacing, double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) SizedBox(width: colSpacing),
          Expanded(
            child: i < items.length
                ? _CollectionCell(scale: s, wallpaper: items[i])
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _CollectionCell extends StatelessWidget {
  const _CollectionCell({required this.scale, required this.wallpaper});

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
      onTap: () {
        LocalCollectionsScope.read(context).recordView(wallpaper.id);
        Navigator.of(context).pushNamed('/screen/0006');
      },
      child: AspectRatio(
        aspectRatio: 106 / 185,
        child: Stack(
          children: [
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
            // Heart / favourite — glass circle, trailing-top with 6pt inset.
            PositionedDirectional(
              end: 6 * s,
              top: 6 * s,
              child: _GlassCircle(
                size: 20 * s,
                onTap: () => LocalCollectionsScope.read(context)
                    .toggleFavourite(wallpaper.id),
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

