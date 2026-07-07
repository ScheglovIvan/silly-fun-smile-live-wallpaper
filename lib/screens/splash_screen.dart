import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Screen 0000 — Splash / Loading.
///
/// Geometry is taken verbatim from `source/0000.json` (reference canvas
/// 375×667pt):
///   * full-bleed near-black background (`UIView` #0a0a0a);
///   * a rounded gradient progress bar (`GradientProgressView`
///     x58 y599 w260 h8, corner_radius 4, dark-green track #19401e);
///   * the ad-disclosure label (`CommonLabel` "This action may contain ads",
///     Urbanist-Medium 12, #fafafa, centred under the bar).
///
/// The bar animates 0→1 to convey the asset-preload the native splash performs.
/// The screen renders standalone (deep link / `/screen/0000`), so it does not
/// auto-advance on its own — routing to the next screen is driven by the app
/// flow ([ColdStartFlow]) via [onComplete], which fires once the bar fills.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  /// Invoked once the preload progress bar reaches the end (the "preload done"
  /// signal). Null in standalone / web-preview mode, where the splash simply
  /// animates and never advances.
  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Reference canvas the native frames were captured on.
  static const double _refW = 375;
  static const double _refH = 667;

  // Dark-green progress track (`GradientProgressView` background #19401eff).
  static const Color _track = Color(0xFF19401E);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete?.call();
    })
    ..forward();

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final sx = w / _refW;
          final sy = h / _refH;

          final barWidth = 260 * sx;
          final barLeft = (w - barWidth) / 2; // native x58 ≈ centred
          final barTop = 599 * sy;
          final barHeight = 8 * sy;
          final textTop = 623 * sy;

          return Stack(
            children: [
              // Native VideoPlayerView background renders solid near-black in
              // the captured splash — matched with the token background fill.
              Positioned.fill(
                child: Container(color: AppColors.background),
              ),

              // Gradient progress bar.
              Positioned(
                left: barLeft,
                top: barTop,
                width: barWidth,
                height: barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4 * sy),
                  child: Container(
                    color: _track,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress.value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4 * sy),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8BFF9B), AppColors.primary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.45),
                                  blurRadius: 6 * sy,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Ad-disclosure label, centred beneath the bar.
              Positioned(
                left: 0,
                right: 0,
                top: textTop,
                child: Text(
                  'This action may contain ads',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: const Color(0xFFFAFAFA),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
