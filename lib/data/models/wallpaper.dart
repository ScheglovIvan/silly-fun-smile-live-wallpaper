import 'catalog_mode.dart';

/// A single wallpaper item in the catalog.
///
/// Maps the app_spec `Wallpaper` entity: `id`, `title`, `categoryId`, `mode`,
/// `thumbnailUrl` (webp), `mediaUrl` (webp/mp4), `isLive`, `isPremium`,
/// `resolution`.
///
/// A wallpaper's imagery may be remote (streamed/cached from the CDN, via
/// [thumbnailUrl] / [mediaUrl]) or bundled in the app archive (via [bundleAsset]
/// — a local `assets/media/*` path used as an offline fallback thumbnail).
class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.mode,
    required this.thumbnailUrl,
    required this.mediaUrl,
    required this.isLive,
    required this.isPremium,
    required this.resolution,
    this.bundleAsset,
  });

  final String id;
  final String title;
  final String categoryId;
  final CatalogMode mode;

  /// Remote webp thumbnail URL (may be empty for a purely-bundled item).
  final String thumbnailUrl;

  /// Remote full-resolution media URL — `.mp4`/`.webp` for live, `.webp`/`.jpg`
  /// for 4K.
  final String mediaUrl;

  final bool isLive;

  /// PRO-gated: only applyable/downloadable with an active PRO entitlement.
  final bool isPremium;

  /// Human label for the wallpaper resolution, e.g. `Ultra HD`, `4K`, `1080p`.
  final String resolution;

  /// Optional bundled asset path (`assets/media/…`) used as an offline / web
  /// fallback when the remote [thumbnailUrl] is unreachable.
  final String? bundleAsset;

  bool get hasRemoteThumb => thumbnailUrl.isNotEmpty;
  bool get hasBundleAsset => (bundleAsset ?? '').isNotEmpty;

  /// True when the full media is a streamed video (`.mp4`).
  bool get isVideoMedia => mediaUrl.toLowerCase().endsWith('.mp4');

  factory Wallpaper.fromJson(
    Map<String, dynamic> json, {
    String? categoryId,
    CatalogMode? mode,
  }) {
    final resolvedMode = mode ?? CatalogMode.fromWire(json['mode']);
    final isLive = json['isLive'] is bool
        ? json['isLive'] as bool
        : resolvedMode == CatalogMode.live;
    return Wallpaper(
      id: (json['id'] ?? json['name'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? json['id'] ?? 'Wallpaper')
          .toString(),
      categoryId:
          (json['categoryId'] ?? json['category'] ?? categoryId ?? '').toString(),
      mode: resolvedMode,
      thumbnailUrl:
          (json['thumbnailUrl'] ?? json['thumb'] ?? json['thumbnail'] ?? '')
              .toString(),
      mediaUrl: (json['mediaUrl'] ?? json['media'] ?? json['url'] ?? '')
          .toString(),
      isLive: isLive,
      isPremium: json['isPremium'] is bool
          ? json['isPremium'] as bool
          : (json['premium'] == true || json['pro'] == true),
      resolution: (json['resolution'] ?? (resolvedMode == CatalogMode.fourK
              ? '4K'
              : 'HD'))
          .toString(),
      bundleAsset: (json['bundleAsset'] ?? json['asset'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'mode': mode.wire,
        'thumbnailUrl': thumbnailUrl,
        'mediaUrl': mediaUrl,
        'isLive': isLive,
        'isPremium': isPremium,
        'resolution': resolution,
        if (bundleAsset != null) 'bundleAsset': bundleAsset,
      };

  @override
  bool operator ==(Object other) => other is Wallpaper && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
