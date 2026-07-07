import 'models/catalog_mode.dart';

/// Static CDN endpoint configuration for the wallpaper catalog.
///
/// Values are taken verbatim from app_spec `business_logic.domain_rules`:
/// "The wallpaper catalog is fetched from a versioned remote manifest
/// (cdn.leansoft-ai.com/il07-smilley-ios/data_live_v29_test.json); media assets
/// live under /il07-smilley-ios/Live_v4/<Category>/<name>.webp (and .mp4 for
/// live)."
class CatalogEndpoints {
  const CatalogEndpoints._();

  static const String cdnHost = 'cdn.leansoft-ai.com';
  static const String appPath = 'il07-smilley-ios';

  /// Current pinned manifest version (`data_live_v29_test.json`).
  static const String manifestVersion = 'data_live_v29';

  /// Fully-qualified versioned manifest URL.
  static Uri manifestUrl() =>
      Uri.https(cdnHost, '/$appPath/data_live_v29_test.json');

  /// Base URL for media assets: `https://cdn…/il07-smilley-ios/Live_v4/`.
  static Uri mediaBase() => Uri.https(cdnHost, '/$appPath/Live_v4/');

  /// Build a media URL for a category folder + file name.
  ///
  /// e.g. `mediaUrl('World_Cup', 'football_17', 'webp')` ->
  /// `https://cdn.leansoft-ai.com/il07-smilley-ios/Live_v4/World_Cup/football_17.webp`.
  static Uri mediaUrl(String folder, String name, String ext) =>
      Uri.https(cdnHost, '/$appPath/Live_v4/$folder/$name.$ext');

  /// Preferred media extension for a mode: `.mp4` streaming video for Live,
  /// `.webp` still for 4K.
  static String mediaExtFor(CatalogMode mode) =>
      mode == CatalogMode.live ? 'mp4' : 'webp';
}
