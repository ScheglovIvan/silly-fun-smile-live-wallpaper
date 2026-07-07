/// The two top-level content modes of the catalog.
///
/// Domain rule (app_spec `business_logic.domain_rules`):
/// "Content is split into two top-level modes: 'Live' (animated, webp/mp4,
/// badged LIVE) and '4K Wallpaper' (static high-resolution)."
enum CatalogMode {
  live,
  fourK;

  /// Wire value used in the remote CDN manifest / model JSON (`live` | `4k`).
  String get wire => this == CatalogMode.live ? 'live' : '4k';

  /// Label shown on the Home Live / 4K segmented toggle.
  String get label => this == CatalogMode.live ? 'Live' : '4K Wallpaper';

  /// Short chip / badge label.
  String get shortLabel => this == CatalogMode.live ? 'Live' : '4K';

  /// Parse the manifest wire value; unknown/absent values default to [live].
  static CatalogMode fromWire(Object? value) {
    final v = value?.toString().trim().toLowerCase();
    if (v == '4k' || v == 'fourk' || v == 'static' || v == 'hd') {
      return CatalogMode.fourK;
    }
    return CatalogMode.live;
  }
}
