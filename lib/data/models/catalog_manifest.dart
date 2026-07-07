import 'catalog_mode.dart';
import 'category.dart';
import 'wallpaper.dart';

/// The parsed remote catalog: the set of [Category] chips and [Wallpaper]
/// items defined by the versioned CDN manifest
/// (`cdn.leansoft-ai.com/il07-smilley-ios/data_live_v29_test.json`).
///
/// Maps the app_spec `CatalogManifest` entity: `version`, `categories[]`,
/// `assetBasePath`.
class CatalogManifest {
  const CatalogManifest({
    required this.version,
    required this.assetBasePath,
    required this.categories,
    required this.wallpapers,
    this.fromCache = false,
  });

  final String version;
  final String assetBasePath;
  final List<Category> categories;
  final List<Wallpaper> wallpapers;

  /// True when this manifest was served from the on-device fallback / cache
  /// rather than freshly fetched from the CDN.
  final bool fromCache;

  bool get isEmpty => categories.isEmpty && wallpapers.isEmpty;

  const CatalogManifest.empty()
      : version = '',
        assetBasePath = '',
        categories = const [],
        wallpapers = const [],
        fromCache = false;

  /// Parse the remote manifest JSON. The real manifest is a nested structure of
  /// categories each containing an item list; this parser is tolerant of a few
  /// common shapes (`categories[].items[]`, flat `wallpapers[]`, `data[]`).
  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    final version =
        (json['version'] ?? json['v'] ?? json['manifestVersion'] ?? 'unknown')
            .toString();
    final assetBasePath = (json['assetBasePath'] ??
            json['baseUrl'] ??
            json['base'] ??
            '/il07-smilley-ios/Live_v4/')
        .toString();

    final categories = <Category>[];
    final wallpapers = <Wallpaper>[];

    final rawCategories =
        (json['categories'] ?? json['sections'] ?? json['data']);
    if (rawCategories is List) {
      for (var i = 0; i < rawCategories.length; i++) {
        final rc = rawCategories[i];
        if (rc is! Map) continue;
        final catJson = rc.cast<String, dynamic>();
        final category = Category.fromJson(catJson, fallbackOrder: i);
        categories.add(category);

        final rawItems =
            (catJson['items'] ?? catJson['wallpapers'] ?? catJson['list']);
        if (rawItems is List) {
          for (final item in rawItems) {
            if (item is! Map) continue;
            wallpapers.add(Wallpaper.fromJson(
              item.cast<String, dynamic>(),
              categoryId: category.id,
              mode: category.mode,
            ));
          }
        }
      }
    }

    // Also accept a flat top-level wallpaper list.
    final flat = (json['wallpapers'] ?? json['items']);
    if (flat is List) {
      for (final item in flat) {
        if (item is! Map) continue;
        wallpapers.add(Wallpaper.fromJson(item.cast<String, dynamic>()));
      }
    }

    return CatalogManifest(
      version: version,
      assetBasePath: assetBasePath,
      categories: categories,
      wallpapers: wallpapers,
    );
  }

  CatalogManifest copyWith({bool? fromCache}) => CatalogManifest(
        version: version,
        assetBasePath: assetBasePath,
        categories: categories,
        wallpapers: wallpapers,
        fromCache: fromCache ?? this.fromCache,
      );

  /// Categories available in [mode], ordered by their `order` field.
  List<Category> categoriesFor(CatalogMode mode) {
    final list = categories.where((c) => c.mode == mode).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Wallpapers in [mode], optionally filtered to a single [categoryId].
  List<Wallpaper> wallpapersFor(CatalogMode mode, {String? categoryId}) {
    return wallpapers
        .where((w) =>
            w.mode == mode &&
            (categoryId == null ||
                categoryId.isEmpty ||
                w.categoryId == categoryId))
        .toList();
  }
}
