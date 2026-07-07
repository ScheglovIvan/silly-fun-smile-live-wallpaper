import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/catalog_controller.dart';
import '../data/local_collections_controller.dart';
import '../data/models/wallpaper.dart';
import '../monetization/entitlement_controller.dart';
import '../theme/app_theme.dart';

/// Optional navigation payload for the preview pager.
///
/// When a wallpaper cell opens the preview it can pass which [categoryId] to
/// page through and which [wallpaperId] to open first. The screen renders
/// standalone without it (used by the `/#/screen/0006` web preview) by falling
/// back to the catalog's selected category.
class PreviewArgs {
  const PreviewArgs({this.categoryId, this.wallpaperId, this.title});

  final String? categoryId;
  final String? wallpaperId;
  final String? title;
}

/// Screen 0006 — full-screen swipeable wallpaper preview pager with Apply
/// action.
///
/// Rebuilt to match the native "SILLY SMILES" preview captured in
/// `source/0006.json` (all geometry is measured against the 375pt reference
/// width and scaled to the device):
///  * a fixed top bar — glass back button, the category title
///    ("Smoking", Urbanist SemiBold 20 / #efeff0) and the crown/PRO button;
///  * an `FSPagerView`-style carousel (center card 262×435, r16, 1pt
///    #ffffff1a border) with the neighbours peeking at 0.65 scale / 0.6 opacity;
///    each card carries a frosted LIVE badge and a heart/favourite button;
///  * a full-width green "Apply" primary button (327×56, r28, #64ff77) that
///    routes PRO-gated wallpapers to the paywall.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, this.args});

  final PreviewArgs? args;

  /// Native reference width all `source/0006.json` frames are measured in.
  static const double _refWidth = 375;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  PageController? _controller;
  int _index = 0;
  bool _initialised = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PreviewArgs? get _args =>
      widget.args ??
      (ModalRoute.of(context)?.settings.arguments as PreviewArgs?);

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    final media = MediaQuery.of(context);
    final s = media.size.width / PreviewScreen._refWidth;

    final args = _args;
    // Default to the catalog's active category (as Home does) so the standalone
    // web preview opens on the first category — "Smoking".
    final categories = catalog.categories;
    final categoryId = args?.categoryId ??
        catalog.selectedCategoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    final wallpapers =
        catalog.repository.wallpapers(catalog.mode, categoryId: categoryId);

    final title = args?.title ??
        catalog.repository.categoryById(categoryId ?? '')?.name ??
        'Preview';

    // One-time page controller set-up: open on the requested wallpaper.
    if (!_initialised && wallpapers.isNotEmpty) {
      _initialised = true;
      final start = args?.wallpaperId == null
          ? 0
          : wallpapers
              .indexWhere((w) => w.id == args!.wallpaperId)
              .clamp(0, wallpapers.length - 1);
      _index = start;
      _controller = PageController(
        initialPage: start,
        viewportFraction: 262 / PreviewScreen._refWidth,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        // GradientView (tint #0a84ff) — a faint top-down vignette for depth.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF141414), AppColors.background],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: media.padding.top),
            _TopBar(scale: s, title: title),
            Expanded(
              child: wallpapers.isEmpty
                  ? _EmptyState(scale: s)
                  : _Carousel(
                      scale: s,
                      controller: _controller!,
                      wallpapers: wallpapers,
                      onPageChanged: (i) => setState(() => _index = i),
                    ),
            ),
            _ApplyBar(
              scale: s,
              wallpaper: wallpapers.isEmpty
                  ? null
                  : wallpapers[_index.clamp(0, wallpapers.length - 1)],
              bottomInset: media.padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar (NavigationCustomView, y=20 h=64) — glass back button, centered
// category title, crown/PRO button.
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scale, required this.title});

  final double scale;
  final String title;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: 64 * s,
      child: Stack(
        children: [
          // Back — glass circle at x=20 y=16 (relative to the 64pt bar).
          Positioned(
            left: 20 * s,
            top: 16 * s,
            child: _GlassCircle(
              size: 32 * s,
              onTap: () {
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                } else {
                  nav.pushReplacementNamed('/');
                }
              },
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 15 * s,
                color: AppColors.text,
              ),
            ),
          ),
          // Category title — Urbanist SemiBold 20, #efeff0.
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 64 * s),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: AppFonts.body,
                  fontSize: 20 * s,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Crown / PRO — opens the subscription paywall.
          Positioned(
            right: 20 * s,
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
// FSPagerView carousel — center card enlarged, neighbours dimmed & scaled down.
// ---------------------------------------------------------------------------

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.scale,
    required this.controller,
    required this.wallpapers,
    required this.onPageChanged,
  });

  final double scale;
  final PageController controller;
  final List<Wallpaper> wallpapers;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    // Center card 262×435 (r16). Reserve a little vertical room for the badge.
    final cardHeight = 435 * s;

    return Center(
      child: SizedBox(
        height: cardHeight,
        child: PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          itemCount: wallpapers.length,
          padEnds: true,
          itemBuilder: (context, i) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                var page = controller.initialPage.toDouble();
                if (controller.hasClients &&
                    controller.position.haveDimensions) {
                  page = controller.page ?? page;
                }
                final delta = (page - i).abs().clamp(0.0, 1.0);
                final cardScale = ui.lerpDouble(1.0, 0.65, delta)!;
                final opacity = ui.lerpDouble(1.0, 0.6, delta)!;
                return Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: cardScale,
                      child: _PreviewCard(scale: s, wallpaper: wallpapers[i]),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A single wallpaper card in the pager (WallpaperCollectionCell): rounded
/// media, a 1pt #ffffff1a border, a frosted LIVE badge and a heart button.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.scale, required this.wallpaper});

  final double scale;
  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final catalog = CatalogScope.of(context);
    final local = LocalCollectionsScope.of(context);
    final fav = local.isFavourite(wallpaper.id);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * s),
          boxShadow: [
            BoxShadow(
              color: const Color(0x2E000000),
              blurRadius: 18 * s,
              offset: Offset(0, 10 * s),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16 * s),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Wallpaper media (video poster / thumbnail) — bundled seed asset
              // offline / in headless web, else the CDN thumbnail.
              ColoredBox(
                color: AppColors.black,
                child: Image(
                  image: catalog.media.thumb(wallpaper),
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Image(
                    image: catalog.media.fallback(wallpaper),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 1pt #ffffff1a hairline border.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(
                      color: const Color(0x1AFFFFFF),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // LIVE badge (live wallpapers), top-left with a 14pt inset.
              if (wallpaper.isLive)
                Positioned(
                  left: 14 * s,
                  top: 14 * s,
                  child: _LiveBadge(scale: s),
                ),
              // Heart / favourite — glass circle, top-right with a 14pt inset.
              Positioned(
                right: 14 * s,
                top: 14 * s,
                child: _GlassCircle(
                  size: 32 * s,
                  onTap: () => LocalCollectionsScope.read(context)
                      .toggleFavourite(wallpaper.id),
                  child: Icon(
                    fav ? Icons.favorite : Icons.favorite_border,
                    size: 17 * s,
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

/// The frosted "LIVE" pill badge (RoundedGlassEffectView).
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * s),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 32 * s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          alignment: Alignment.center,
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

// ---------------------------------------------------------------------------
// Apply bar — full-width green primary button (PrimaryButton, 327×56 r28).
// ---------------------------------------------------------------------------

class _ApplyBar extends StatelessWidget {
  const _ApplyBar({
    required this.scale,
    required this.wallpaper,
    required this.bottomInset,
  });

  final double scale;
  final Wallpaper? wallpaper;
  final double bottomInset;

  void _apply(BuildContext context) {
    final w = wallpaper;
    if (w == null) return;
    LocalCollectionsScope.read(context).recordView(w.id);

    final entitlement = EntitlementScope.read(context);
    // PRO-gated wallpapers route to the subscription paywall on the free tier.
    if (w.isPremium && !entitlement.isPro) {
      Navigator.of(context).pushNamed('/screen/0009');
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surface,
          content: Text(
            'Applying “${w.title}” as your wallpaper…',
            style: const TextStyle(color: AppColors.text),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final entitlement = EntitlementScope.of(context);
    final locked =
        (wallpaper?.isPremium ?? false) && !entitlement.isPro;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24 * s,
        16 * s,
        24 * s,
        (bottomInset > 0 ? bottomInset : 12) + 16 * s,
      ),
      child: SizedBox(
        height: 56 * s,
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28 * s),
          child: InkWell(
            borderRadius: BorderRadius.circular(28 * s),
            onTap: wallpaper == null ? null : () => _apply(context),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locked) ...[
                    Icon(Icons.lock, size: 18 * s, color: AppColors.black),
                    SizedBox(width: 8 * s),
                  ],
                  Text(
                    locked ? 'Unlock with PRO' : 'Apply',
                    style: TextStyle(
                      color: AppColors.black,
                      fontFamily: AppFonts.body,
                      fontSize: 20 * s,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits.
// ---------------------------------------------------------------------------

/// A frosted-glass circular control (RoundedGlassEffectView).
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No wallpapers to preview',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: AppFonts.body,
          fontSize: 16 * scale,
        ),
      ),
    );
  }
}
