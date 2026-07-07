import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../localization/locale_controller.dart';
import '../theme/app_theme.dart';

/// Screen 0004 — Language picker.
///
/// Rebuilt from `source/0004.json` (native `SmileyWallpaper.LanguageCell`
/// table): a centred "Language" title with a rounded-glass back button, over a
/// scrolling list of language cells. Each cell is a 56pt rounded pill
/// (`#ffffff0d`, radius 12) holding a 28pt circular flag, an Urbanist‑Regular
/// 20 label (`#efeff0`) and a 24pt selection radio. Row order and geometry
/// mirror the captured hierarchy; the Arabic ("عربي") row keeps the same
/// LTR cell layout as the native app while its label shapes RTL.
///
/// Tapping a row applies that language app-wide through the [LocaleController]
/// (`MaterialApp.locale` + text direction — RTL for Arabic) and returns to
/// Settings (0004 → 0003), implementing REQ-language-selection.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // Flag/back media (media.json ids resolved to their bundled sha256 files).
  static const String _flagDir = 'assets/media';
  static const String _radioIcon =
      '$_flagDir/ed27724bd09635527d19ab2981761cff6613136f81df126be0689ae175f046a0.png';
  static const String _backIcon =
      '$_flagDir/af7a0d666849c44885be4aefe767690c44fab746ccb1ef5b4b51fc96b01aeb86.png';

  // Cells in the exact top-to-bottom order of the native `UITableView`, shared
  // with the app-wide localization layer.
  static const List<AppLanguage> _languages = AppLanguages.all;

  /// Apply [language] app-wide and dismiss back to Settings. The radio updates
  /// first (via the controller's notification) so the choice is visibly marked
  /// before the picker pops.
  void _choose(AppLanguage language) {
    LocaleScope.read(context).select(language);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe so the selected radio reflects the app-wide language and
    // updates instantly on tap.
    final selectedKey = LocaleScope.of(context).selectedKey;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _cell(_languages[i], selectedKey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom nav bar: rounded-glass back button (left) + centred title.
  Widget _header(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Language',
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.textSecondary,
            ),
          ),
          Positioned(
            left: 20,
            child: _BackButton(icon: _backIcon),
          ),
        ],
      ),
    );
  }

  Widget _cell(AppLanguage lang, String selectedKey) {
    final bool selected = AppLanguages.keyOf(lang) == selectedKey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _choose(lang),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  lang.flagAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  lang.name,
                  textDirection:
                      lang.rtl ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Radio(selected: selected, icon: _radioIcon),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-glass circular back button (32pt, `#ffffff12`, radius 16) with the
/// captured chevron glyph; pops the navigation stack when available.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.overlay,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
        },
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Image.asset(
              icon,
              width: 24,
              height: 24,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Trailing selection indicator. Unselected renders the captured empty-circle
/// icon; selected paints the brand-green filled radio.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.icon});

  final bool selected;
  final String icon;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Image.asset(icon, width: 24, height: 24);
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
