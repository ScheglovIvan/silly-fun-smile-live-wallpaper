import 'catalog_service.dart';
import 'media_cache.dart';
import 'models/catalog_manifest.dart';
import 'models/catalog_mode.dart';
import 'models/category.dart';
import 'models/wallpaper.dart';
import 'seed_catalog.dart';

/// Single source of truth for the wallpaper catalog.
///
/// Responsibilities:
///  * Load the catalog — try the remote CDN manifest via [CatalogService];
///    fall back to the bundled [SeedCatalog] when the network fails so the app
///    always has content (app_spec: "remote CDN catalog … with local media
///    cache").
///  * Cache the last-good manifest in memory and expose query helpers filtered
///    by [CatalogMode] and category.
///  * Own the [MediaCache] used to resolve/cache wallpaper imagery.
///
/// This is a plain (non-widget) object; [CatalogController] wraps it with
/// [ChangeNotifier] state for the UI.
class CatalogRepository {
  CatalogRepository({CatalogService? service, MediaCache? mediaCache})
      : _service = service ?? CatalogService(),
        media = mediaCache ?? MediaCache();

  final CatalogService _service;

  /// Shared media cache for thumbnails / full media.
  final MediaCache media;

  CatalogManifest _manifest = const CatalogManifest.empty();
  CatalogManifest get manifest => _manifest;

  bool get isLoaded => !_manifest.isEmpty;

  /// True when the currently-loaded catalog came from the bundled seed rather
  /// than a fresh CDN fetch.
  bool get isUsingSeed => _manifest.fromCache;

  /// Load the catalog, preferring the remote manifest. On any fetch/parse
  /// failure the bundled seed is used and the error is returned (non-throwing)
  /// so the UI can surface an offline notice while still rendering content.
  ///
  /// Returns the [CatalogFetchException] that forced the seed fallback, or null
  /// on a successful remote load.
  Future<CatalogFetchException?> load() async {
    try {
      _manifest = await _service.fetchManifest();
      return null;
    } on CatalogFetchException catch (e) {
      _manifest = SeedCatalog.build();
      return e;
    } catch (e) {
      _manifest = SeedCatalog.build();
      return CatalogFetchException('Unexpected catalog error: $e');
    }
  }

  /// Load the bundled seed immediately without any network call (used for the
  /// synchronous first paint / web preview).
  void loadSeed() => _manifest = SeedCatalog.build();

  // ---- Query helpers -------------------------------------------------------

  List<Category> categories(CatalogMode mode) => _manifest.categoriesFor(mode);

  List<Wallpaper> wallpapers(CatalogMode mode, {String? categoryId}) =>
      _manifest.wallpapersFor(mode, categoryId: categoryId);

  /// Curated cross-category trending set.
  List<Wallpaper> trending() => SeedCatalog.trending(_manifest);

  Wallpaper? wallpaperById(String id) {
    for (final w in _manifest.wallpapers) {
      if (w.id == id) return w;
    }
    return null;
  }

  Category? categoryById(String id) {
    for (final c in _manifest.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Resolve a list of wallpaper ids to wallpapers, preserving order and
  /// dropping ids no longer present in the catalog (used by Favourites/History).
  List<Wallpaper> resolveIds(Iterable<String> ids) {
    final out = <Wallpaper>[];
    for (final id in ids) {
      final w = wallpaperById(id);
      if (w != null) out.add(w);
    }
    return out;
  }

  void dispose() => _service.dispose();
}
