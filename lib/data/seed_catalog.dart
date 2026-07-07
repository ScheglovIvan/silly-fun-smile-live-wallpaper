import 'catalog_endpoints.dart';
import 'models/catalog_manifest.dart';
import 'models/catalog_mode.dart';
import 'models/category.dart';
import 'models/wallpaper.dart';

/// Bundled fallback catalog used when the remote CDN manifest cannot be reached
/// (offline, CORS in the web preview, first-run before the fetch resolves).
///
/// It reproduces the 20 real categories from app_spec `content_inventory`
/// across both Live and 4K modes, and generates deterministic wallpaper items
/// whose remote URLs follow the real CDN media path
/// (`…/Live_v4/<Category>/<name>.<ext>`). Each item also carries a bundled
/// `assets/media/seed_thumb_*.png` fallback so the grid renders standalone in
/// headless web.
class SeedCatalog {
  const SeedCatalog._();

  /// (name, emoji) for the 20 themed categories, in Home chip order.
  static const List<List<String>> _themes = [
    ['Smoking', '🚬'],
    ['Gun', '🔫'],
    ['World Cup', '🏆'],
    ['Smiley', '😀'],
    ['Demon Slayer', '⚔️'],
    ['Fantasy', '🐉'],
    ['Jujutsu Kaisen', '👊'],
    ['Naruto', '🍥'],
    ['Nature', '🌿'],
    ['Car', '🏎️'],
    ['Comics', '💥'],
    ['Cute', '🐰'],
    ['Space', '🌌'],
    ['Dark', '🌑'],
    ['Neon', '🌈'],
    ['Christmas', '🎄'],
    ['Ramadan', '🌙'],
    ['Minecraft', '⛏️'],
    ['Hacker', '💻'],
    ['Cartoon', '🎨'],
  ];

  /// Number of bundled `seed_thumb_*.png` fallbacks copied into assets/media.
  static const int _bundleThumbCount = 9;

  /// How many wallpapers to seed per category (per mode).
  static const int _itemsPerCategory = 12;

  static String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static String _folder(String name) => name.replaceAll(' ', '_');

  static CatalogManifest build() {
    final categories = <Category>[];
    final wallpapers = <Wallpaper>[];

    var order = 0;
    for (final mode in CatalogMode.values) {
      for (final theme in _themes) {
        final name = theme[0];
        final emoji = theme[1];
        final folder = _folder(name);
        final catId = '${mode.wire}_${_slug(name)}';
        categories.add(Category(
          id: catId,
          name: name,
          mode: mode,
          iconEmoji: emoji,
          order: order++,
          assetFolder: folder,
        ));

        final ext = CatalogEndpoints.mediaExtFor(mode);
        for (var i = 1; i <= _itemsPerCategory; i++) {
          final fileName = '${_slug(name)}_$i';
          // Distribute the bundled fallback thumbnails deterministically.
          final bundleIndex =
              ((order * 7 + i) % _bundleThumbCount) + 1; // 1..9
          wallpapers.add(Wallpaper(
            id: '${catId}_$i',
            title: '$name ${mode.shortLabel} #$i',
            categoryId: catId,
            mode: mode,
            thumbnailUrl:
                CatalogEndpoints.mediaUrl(folder, fileName, 'webp').toString(),
            mediaUrl:
                CatalogEndpoints.mediaUrl(folder, fileName, ext).toString(),
            isLive: mode == CatalogMode.live,
            // Every 3rd item is PRO-gated in the seed to exercise ad/paywall
            // gating on the free tier.
            isPremium: i % 3 == 0,
            resolution: mode == CatalogMode.fourK ? '4K Ultra HD' : 'HD Live',
            bundleAsset: 'assets/media/seed_thumb_$bundleIndex.png',
          ));
        }
      }
    }

    return CatalogManifest(
      version: '${CatalogEndpoints.manifestVersion}_seed',
      assetBasePath: CatalogEndpoints.mediaBase().toString(),
      categories: categories,
      wallpapers: wallpapers,
      fromCache: true,
    );
  }

  /// A curated cross-category "Trending" set (app_spec content_to_seed:
  /// ~10-20 featured hero references).
  static List<Wallpaper> trending(CatalogManifest manifest) {
    // First item of a spread of visually-distinct categories.
    const featured = [
      'World Cup',
      'Naruto',
      'Car',
      'Space',
      'Neon',
      'Demon Slayer',
      'Nature',
      'Jujutsu Kaisen',
      'Dark',
      'Cartoon',
    ];
    final picks = <Wallpaper>[];
    for (final name in featured) {
      final catId = 'live_${_slug(name)}';
      final match = manifest.wallpapers.firstWhere(
        (w) => w.categoryId == catId,
        orElse: () => manifest.wallpapers.isNotEmpty
            ? manifest.wallpapers.first
            : _placeholder(),
      );
      picks.add(match);
    }
    return picks;
  }

  static Wallpaper _placeholder() => const Wallpaper(
        id: 'placeholder',
        title: 'Wallpaper',
        categoryId: '',
        mode: CatalogMode.live,
        thumbnailUrl: '',
        mediaUrl: '',
        isLive: true,
        isPremium: false,
        resolution: 'HD',
        bundleAsset: 'assets/media/seed_thumb_1.png',
      );
}
