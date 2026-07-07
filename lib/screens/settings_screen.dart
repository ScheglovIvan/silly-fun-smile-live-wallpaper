import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

/// Screen 0003 — Settings.
///
/// Rebuilt to match the native "SILLY SMILES" SettingController captured in
/// `source/0003.json`. All geometry is expressed against the 375pt reference
/// width and scaled to the device:
///  * a top bar — glass back button (pops the stack) and a centered "Setting"
///    title (Urbanist-SemiBold 20pt);
///  * a green-tinted PRO upgrade banner (335x136, r16, #204125 fill with a
///    #71FA8A border) carrying the SILLY SMILES wordmark, a pink PRO pill, a
///    value-prop line, the gold crown artwork and a green "Upgrade Now" pill —
///    the whole card opens the subscription paywall (0009);
///  * a "General" section title;
///  * a grouped list (#FFFFFF0D, r16) of 72pt rows — Rate Us, Language,
///    Feedback, Share this app, Privacy Policy — each with a leading icon,
///    an Urbanist-Regular 16pt label and a trailing chevron.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Native reference width all `source/0003.json` frames are measured in.
  static const double _refWidth = 375;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Scale native (375pt) frames to the real width so the layout matches the
    // captured geometry on any device / in the headless web preview.
    final s = media.size.width / _refWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: media.padding.top),
            const _NavBar(),
            SizedBox(height: 10 * s),
            _UpgradeBanner(scale: s),
            SizedBox(height: 40 * s),
            _SectionHeader(scale: s),
            SizedBox(height: 18 * s),
            _SettingsList(scale: s),
            SizedBox(height: media.padding.bottom + 24 * s),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav bar (NavigationCustomView, y=20 h=64): glass back button at x=20 y=36
// (32x32 r16) + centered "Setting" title (Urbanist-SemiBold 20pt #EFEFF0).
// ---------------------------------------------------------------------------

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / SettingsScreen._refWidth;
    return SizedBox(
      height: 64 * s,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 20 * s,
            top: 16 * s,
            child: _GlassCircle(
              size: 32 * s,
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 24 * s,
                height: 24 * s,
                child: Image.asset(
                  'assets/media/af7a0d666849c44885be4aefe767690c44fab746ccb1ef5b4b51fc96b01aeb86.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              AppStrings.of(context).setting,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: AppFonts.body,
                fontSize: 20 * s,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted-glass rounded control matching the native
/// `RoundedGlassEffectView` — a subtle white overlay fill with a soft shadow.
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
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.overlay,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRO upgrade banner (x=20 y=94 w=335 h=136 r16): #204125 fill, #71FA8A 1pt
// border. Tapping the whole card opens the subscription paywall (0009).
// ---------------------------------------------------------------------------

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.scale});

  final double scale;

  static const Color _bannerBg = Color(0xFF204125);
  static const Color _bannerBorder = Color(0xFF71FA8A);
  static const Color _proPink = Color(0xFFFF3F6C);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pushNamed('/screen/0009'),
        child: SizedBox(
          height: 136 * s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card fill + border.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _bannerBg,
                    borderRadius: BorderRadius.circular(16 * s),
                    border: Border.all(color: _bannerBorder, width: 1),
                  ),
                ),
              ),
              // Gold crown artwork (n34) x=201 y=94 w=150 h=130 (banner-local
              // x=181 y=0).
              Positioned(
                left: 181 * s,
                top: 0,
                width: 150 * s,
                height: 130 * s,
                child: Image.asset(
                  'assets/media/0164bccf167265186ae085a1b0f8dc87ec1f059146258e685f670932333ae823.png',
                  fit: BoxFit.contain,
                ),
              ),
              // SILLY SMILES wordmark (Future Edge 20pt) x=40 y=110 (local
              // x=20 y=16).
              Positioned(
                left: 20 * s,
                top: 16 * s,
                child: Text(
                  'SILLY SMILES',
                  style: TextStyle(
                    color: AppColors.text,
                    fontFamily: AppFonts.display,
                    fontSize: 20 * s,
                    height: 1.0,
                  ),
                ),
              ),
              // Pink PRO pill x=176 y=111 w=49 h=24 r12 (local x=156 y=17).
              Positioned(
                left: 156 * s,
                top: 17 * s,
                width: 49 * s,
                height: 24 * s,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _proPink,
                    borderRadius: BorderRadius.circular(12 * s),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: AppColors.text,
                      fontFamily: AppFonts.body,
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Value-prop subtitle (Urbanist 12pt) x=40 y=139 w=151 (local
              // x=20 y=45).
              Positioned(
                left: 20 * s,
                top: 45 * s,
                width: 151 * s,
                child: Text(
                  AppStrings.of(context).upgradeTagline,
                  style: TextStyle(
                    color: AppColors.text,
                    fontFamily: AppFonts.body,
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              ),
              // Green "Upgrade Now" pill (button image n35) x=40 y=182 w=116
              // h=32 (local x=20 y=88) with its label (Urbanist-SemiBold 14pt)
              // overlaid.
              Positioned(
                left: 20 * s,
                top: 88 * s,
                width: 116 * s,
                height: 32 * s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/media/2c398eb1869d31d57ad1121df38b9c9595a429040d75e870241138d2a9d82b0d.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    Text(
                      AppStrings.of(context).upgradeNow,
                      style: TextStyle(
                        color: AppColors.text,
                        fontFamily: AppFonts.body,
                        fontSize: 14 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
// "General" section title (Urbanist-Regular 20pt #FFFFFF) x=20 y=270.
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Text(
        AppStrings.of(context).general,
        style: TextStyle(
          color: AppColors.text,
          fontFamily: AppFonts.body,
          fontSize: 20 * s,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grouped settings list (UITableView x=20 y=312 w=335 r16, bg #FFFFFF0D) of
// 72pt SettingTableCell rows. Order top→bottom: Rate Us, Language, Feedback,
// Share this app, Privacy Policy.
// ---------------------------------------------------------------------------

class _SettingsItem {
  const _SettingsItem(this.icon, this.label, [this.onTap]);
  final String icon;
  final String label;
  final VoidCallback? onTap;
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.scale});

  final double scale;

  static const Color _listBg = Color(0x0DFFFFFF);
  static const String _chevron =
      'assets/media/867dafae4a76fecb254f7a4225daff09b18d0c94bfab31239ea70a175452ed62.png';

  List<_SettingsItem> _items(BuildContext context) {
    final t = AppStrings.of(context);
    return <_SettingsItem>[
      _SettingsItem(
        'assets/media/c34296fbc4736ba703061c2d22fa7dc4301f97f1bc9a02f19fca91fb1d50c902.png',
        t.rateUs,
      ),
      _SettingsItem(
        'assets/media/8abbba616ecabe954f555d7325d65f47d4b4d24231a9859f0499b0f27d87e50e.png',
        t.language,
        () => Navigator.of(context).pushNamed('/screen/0004'),
      ),
      _SettingsItem(
        'assets/media/88431208a7d4b8a4d7eb9796c4bd30f249aa54dc30ebaccb7c244d16680dde6d.png',
        t.feedback,
      ),
      _SettingsItem(
        'assets/media/39bec082d74184a2ba7f40a210e64ee310fa4b81b9319efc3b60807c005d6441.png',
        t.shareApp,
      ),
      _SettingsItem(
        'assets/media/f2727882e9d9d1bb1b8b846bd162c0921ebae10604dd77f0fd6c483013d36ed8.png',
        t.privacyPolicy,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final items = _items(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Container(
        decoration: BoxDecoration(
          color: _listBg,
          borderRadius: BorderRadius.circular(16 * s),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _SettingsRow(scale: s, item: items[i]),
              if (i != items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.overlay,
                  indent: 8 * s,
                  endIndent: 8 * s,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.scale, required this.item});

  final double scale;
  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: SizedBox(
        height: 72 * s,
        child: Row(
          children: [
            SizedBox(width: 20 * s),
            // Leading icon 24x24 at x=40 (list-local x=20).
            SizedBox(
              width: 24 * s,
              height: 24 * s,
              child: Image.asset(item.icon, fit: BoxFit.contain),
            ),
            // Label at x=76 (16pt gap from the icon).
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: AppFonts.body,
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Trailing chevron 24x24 at x=311 (right edge, 4pt inset).
            SizedBox(
              width: 24 * s,
              height: 24 * s,
              child: Image.asset(_SettingsList._chevron, fit: BoxFit.contain),
            ),
            SizedBox(width: 20 * s),
          ],
        ),
      ),
    );
  }
}
