import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A left-to-right shimmer sweep used to animate loading skeletons.
///
/// Wrap any tree of opaque [SkeletonBox]es in a [Shimmer]; the widget recolors
/// the child's opaque pixels with a moving [base] → [highlight] → [base]
/// gradient (via a [ShaderMask]), giving the "content is loading" pulse the
/// native app shows for its ad and feed placeholders. The sweep is direction
/// agnostic, so it reads correctly under both LTR and RTL layouts.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.base,
    this.highlight,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;

  /// Rest tone of the skeleton (defaults to [AppColors.skeletonBase]).
  final Color? base;

  /// Peak tone of the moving sweep (defaults to [AppColors.skeletonHighlight]).
  final Color? highlight;

  /// One full pass of the sweep across the child.
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.base ?? AppColors.skeletonBase;
    final highlight = widget.highlight ?? AppColors.skeletonHighlight;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Slide a soft highlight band across the full width of the child.
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (t - 0.30).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.30).clamp(0.0, 1.0),
              ],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single opaque placeholder block, tinted with [AppColors.skeletonBase] so a
/// surrounding [Shimmer] can sweep over it. Use for the rectangles/lines that
/// stand in for not-yet-loaded thumbnails, text and controls.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonBase,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
      ),
    );
  }
}

/// A shimmering 3-column placeholder grid shown in the wallpaper feed while the
/// catalog is still loading (before the seed/CDN wallpapers resolve). Mirrors
/// the real feed geometry — tall 106×185 cells, r8, 11pt column / 14pt row
/// gaps — so the transition to loaded content doesn't shift the layout.
class WallpaperGridSkeleton extends StatelessWidget {
  const WallpaperGridSkeleton({super.key, required this.scale, this.rows = 4});

  final double scale;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final colSpacing = 11.0 * s;
    final rowSpacing = 14.0 * s;
    return Shimmer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 24 * s),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) SizedBox(height: rowSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) SizedBox(width: colSpacing),
                  const Expanded(
                    child: AspectRatio(
                      aspectRatio: 106 / 185,
                      child: SkeletonBox(radius: 8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
