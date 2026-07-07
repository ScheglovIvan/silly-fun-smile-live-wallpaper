import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens captured from the native "SILLY SMILES" UI
/// (see app_spec.json `design_tokens.color`). All values are the real
/// #RRGGBB(AA) colors observed in the source app — the app ships a fixed
/// dark theme with no light-mode variant.
class AppColors {
  AppColors._();

  /// Brand green accent — active tab pill, selected plan outline, primary
  /// CTAs and the splash progress bar. (#64ff77ff)
  static const Color primary = Color(0xFF64FF77);

  /// 10% green tint used as the segmented-control track / subtle backgrounds.
  static const Color primaryDim = Color(0x1A64FF77);

  /// Primary near-black app background. (#0a0a0aff)
  static const Color background = Color(0xFF0A0A0A);

  /// Paywall background. (#0c0c0cff)
  static const Color backgroundAlt = Color(0xFF0C0C0C);

  /// Nav / tab-bar and control surface. (#242424ff)
  static const Color surface = Color(0xFF242424);

  /// Selected / green-tinted plan card background. (#202821ff)
  static const Color surfaceSelected = Color(0xFF202821);

  /// Secondary control / badge background. (#3a3a3aff)
  static const Color surfaceMuted = Color(0xFF3A3A3A);

  /// Base tone for loading skeletons / placeholder blocks on the dark UI —
  /// a hair lighter than [surface] so shapes read while still feeling "empty".
  static const Color skeletonBase = Color(0xFF3A3A3A);

  /// Sweep highlight tone for the shimmer that animates over [skeletonBase].
  static const Color skeletonHighlight = Color(0xFF515151);

  /// Amber "Ad" attribution chip on native-ad placeholders.
  static const Color adLabel = Color(0xFFF4C20D);

  /// Subtle white overlay on cells / badges / back buttons. (#ffffff12)
  static const Color overlay = Color(0x12FFFFFF);

  /// Primary text on dark. (#ffffffff)
  static const Color text = Color(0xFFFFFFFF);

  /// Title / label text. (#efeff0ff)
  static const Color textSecondary = Color(0xFFEFEFF0);

  /// Pink "PRO" badge accent.
  static const Color accentPro = Color(0xFFFF2D66);

  /// True-black fills. (#000000ff)
  static const Color black = Color(0xFF000000);
}

/// Corner-radius and sizing tokens from `design_tokens.dimension`.
class AppRadii {
  AppRadii._();
  static const double sm = 8;
  static const double md = 16;
  static const double pill = 28;
}

/// Bundled type families (declared in pubspec `fonts:`).
class AppFonts {
  AppFonts._();

  /// Display / logo family used for "SILLY SMILES".
  static const String display = 'Future Edge';

  /// Primary UI/body family — set as the app-wide default so every screen
  /// inherits it.
  static const String body = 'Urbanist';
}

/// The single, fixed dark [ThemeData] for the whole app.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.black,
      secondary: AppColors.primary,
      onSecondary: AppColors.black,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.accentPro,
      onError: AppColors.text,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashColor: AppColors.primaryDim,
      highlightColor: AppColors.primaryDim,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: _textTheme(base.textTheme),
      iconTheme: const IconThemeData(color: AppColors.text),
      dividerColor: AppColors.overlay,
      cardColor: AppColors.surface,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    // Body / heading text uses Urbanist (the default fontFamily); individual
    // screens opt into the Future Edge display family where the design calls
    // for the branded logo type.
    return base
        .apply(
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
          fontFamily: AppFonts.body,
        )
        .copyWith(
          titleLarge: base.titleLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        );
  }
}
