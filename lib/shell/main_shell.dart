import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../screens/favourites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/trending_screen.dart';
import '../theme/app_theme.dart';

/// The floating pill bottom-tab shell that hosts the three primary
/// destinations: Home (0002), Trending (0007) and Favourite (0008), and owns
/// the persistent bottom tab bar (REQ-bottom-nav).
///
/// The three screens are kept alive in an [IndexedStack], so switching tabs is
/// instant and each tab preserves its own state (scroll offset, the Favourite /
/// History sub-tab, the Live / 4K toggle, carousel page). Deep links and the
/// `/#/screen/<id>` web preview enter here via [initialIndex] so the tab bar is
/// present exactly as captured natively (screens/0002, 0007, 0008).
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// Which tab is selected on first build: 0 = Home, 1 = Trending, 2 = Favourite.
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex.clamp(0, _tabs.length - 1);

  static const List<_TabItem> _tabs = <_TabItem>[
    _TabItem('Home', icon: Icons.home_outlined, screen: HomeScreen()),
    _TabItem(
      'Trending',
      // The native Trending glyph is a colour flame (Lottie when active); the
      // bundled static flame asset renders it faithfully in both states.
      assetIcon: 'assets/media/tab_trending_flame.png',
      screen: TrendingScreen(),
    ),
    _TabItem('Favourite', icon: Icons.favorite_border, screen: FavouritesScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Let each tab's content extend behind the floating pill tab bar, matching
      // the native layout where the bar hovers above the feed / carousel.
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: _PillTabBar(
        index: _index,
        tabs: _tabs,
        onTap: (i) {
          if (i != _index) setState(() => _index = i);
        },
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.label, {this.icon, this.assetIcon, required this.screen})
      : assert(icon != null || assetIcon != null);

  final String label;
  final IconData? icon;
  final String? assetIcon;
  final Widget screen;
}

// ---------------------------------------------------------------------------
// Floating pill tab bar (SmileyWallpaper.TabbarBottomView).
//
// Native ground truth (source/0007.json, 375pt reference width):
//   * RoundedGlassEffectView pill: x=20 y=577 w=335 h=56 r=28, frosted glass
//     over a near-black background, soft shadow (black, y+10, blur 18, 18%).
//   * Three equal tab items (~107 wide) each ALWAYS showing icon (24) + label
//     (Urbanist 16). Active label #efeff0 SemiBold; inactive #ffffffb3 Regular.
//   * The active item sits on a subtle green-tinted highlight capsule
//     (TabbarIndicatorView / GradientView, ~107x40 r=20).
// ---------------------------------------------------------------------------

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  final int index;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  /// Native reference width the pill geometry (335/56/28) is measured against.
  static const double _refWidth = 375;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final s = media.size.width / _refWidth;
    final bottomInset = media.padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, bottomInset + 12 * s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28 * s),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 56 * s,
            decoration: BoxDecoration(
              // Frosted dark glass — the #242424 surface at ~82% opacity so the
              // blurred feed shows through, as in the native capture.
              color: const Color(0xD1242424),
              borderRadius: BorderRadius.circular(28 * s),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000), // black @ ~18%
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _PillTab(
                      item: tabs[i],
                      selected: i == index,
                      scale: s,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.item,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final _TabItem item;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    // Inactive glyph / label = 70% white; active = the bright #efeff0 title
    // colour. The Trending flame keeps its own colours (asset), so tinting only
    // applies to the outline Material glyphs.
    final contentColor =
        selected ? AppColors.textSecondary : const Color(0xB3FFFFFF);

    final Widget iconWidget = item.assetIcon != null
        ? Image.asset(
            item.assetIcon!,
            width: 24 * s,
            height: 24 * s,
            fit: BoxFit.contain,
          )
        : Icon(item.icon, size: 24 * s, color: contentColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40 * s,
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          decoration: BoxDecoration(
            // Subtle green-tinted highlight capsule behind the active tab
            // (TabbarIndicatorView GradientView) — brand-consistent, low alpha
            // (#64FF77 @ ~13%).
            color: selected ? const Color(0x2164FF77) : Colors.transparent,
            borderRadius: BorderRadius.circular(20 * s),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              SizedBox(width: 6 * s),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(
                    color: contentColor,
                    fontFamily: AppFonts.body,
                    fontSize: 16 * s,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
