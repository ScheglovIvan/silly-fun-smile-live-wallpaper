import 'package:flutter/widgets.dart';

import 'models/wallpaper.dart';

/// Lightweight, platform-agnostic media cache for wallpaper imagery.
///
/// The catalog streams thumbnails/media from the remote CDN and caches them for
/// offline apply (app_spec `persistence`: "streamed media with local media
/// cache"). This layer keeps a bounded, order-preserving map of resolved
/// [ImageProvider]s keyed by their source so repeated grid/pager builds reuse
/// the same provider instance (which in turn shares Flutter's decoded
/// [ImageCache] entry). It works identically on mobile and in the web preview —
/// no `dart:io` file access, so bundled assets are the reliable offline layer.
class MediaCache {
  MediaCache({this.maxEntries = 256});

  /// Max number of distinct providers kept before the least-recently-used ones
  /// are evicted.
  final int maxEntries;

  final Map<String, ImageProvider> _providers = <String, ImageProvider>{};

  int get length => _providers.length;

  ImageProvider _remember(String key, ImageProvider Function() create) {
    final existing = _providers.remove(key);
    if (existing != null) {
      _providers[key] = existing; // move to most-recently-used
      return existing;
    }
    final provider = create();
    _providers[key] = provider;
    if (_providers.length > maxEntries) {
      _providers.remove(_providers.keys.first); // evict LRU
    }
    return provider;
  }

  /// Resolve the thumbnail image for [w].
  ///
  /// Prefers the bundled asset (reliable offline / in headless web); otherwise
  /// streams the remote CDN thumbnail. Screens that want the remote-first
  /// behaviour with a graceful fallback can use [remoteThumb] + [fallback]
  /// together in an `Image(errorBuilder:)`.
  ImageProvider thumb(Wallpaper w) {
    if (w.hasBundleAsset) {
      return _remember('asset:${w.bundleAsset}',
          () => AssetImage(w.bundleAsset!));
    }
    return remoteThumb(w);
  }

  /// The remote CDN thumbnail provider (falls back to the bundled asset when
  /// there is no remote URL).
  ImageProvider remoteThumb(Wallpaper w) {
    if (!w.hasRemoteThumb) return fallback(w);
    return _remember('net:${w.thumbnailUrl}',
        () => NetworkImage(w.thumbnailUrl));
  }

  /// The full-resolution still image provider (for 4K wallpapers / video
  /// poster frames), preferring the bundled fallback for offline reliability.
  ImageProvider full(Wallpaper w) {
    if (w.hasBundleAsset) {
      return _remember('asset:${w.bundleAsset}',
          () => AssetImage(w.bundleAsset!));
    }
    if (w.mediaUrl.isNotEmpty && !w.isVideoMedia) {
      return _remember('net:${w.mediaUrl}', () => NetworkImage(w.mediaUrl));
    }
    return remoteThumb(w);
  }

  /// The bundled-asset fallback provider for [w] (a neutral placeholder if the
  /// item has no bundled asset at all).
  ImageProvider fallback(Wallpaper w) {
    final asset = w.hasBundleAsset
        ? w.bundleAsset!
        : 'assets/media/seed_thumb_1.png';
    return _remember('asset:$asset', () => AssetImage(asset));
  }

  /// Warm the decoded-image cache for a set of wallpapers (e.g. the visible
  /// grid page or the next preview pages). Safe to call repeatedly.
  Future<void> precacheThumbs(
    BuildContext context,
    Iterable<Wallpaper> wallpapers,
  ) async {
    for (final w in wallpapers) {
      await precacheImage(thumb(w), context);
    }
  }

  void clear() => _providers.clear();
}
