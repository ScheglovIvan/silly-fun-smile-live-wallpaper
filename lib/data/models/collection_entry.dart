/// Local-collection entries for the Favourites and History tabs.
///
/// Mirrors the app_spec `Favourite` (`wallpaperId`, `addedAt`) and `HistoryItem`
/// (`wallpaperId`, `viewedAt`) entities, both of which "reference Wallpaper
/// (local)". Per app_spec these are per-device collections stored locally on the
/// device — no auth / cloud sync — so each entry is just a wallpaper id plus the
/// moment the user acted on it.
library;

import 'package:flutter/foundation.dart';

/// A wallpaper the user has favourited (heart filled).
@immutable
class Favourite {
  const Favourite({required this.wallpaperId, required this.addedAt});

  final String wallpaperId;

  /// When the wallpaper was added to the Favourites collection.
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'wallpaperId': wallpaperId,
        'addedAt': addedAt.toUtc().toIso8601String(),
      };

  factory Favourite.fromJson(Map<String, dynamic> json) => Favourite(
        wallpaperId: (json['wallpaperId'] ?? json['id'] ?? '').toString(),
        addedAt: _parseTime(json['addedAt']),
      );

  @override
  bool operator ==(Object other) =>
      other is Favourite && other.wallpaperId == wallpaperId;

  @override
  int get hashCode => wallpaperId.hashCode;
}

/// A wallpaper the user has recently viewed (preview opened).
@immutable
class HistoryItem {
  const HistoryItem({required this.wallpaperId, required this.viewedAt});

  final String wallpaperId;

  /// When the wallpaper was last viewed.
  final DateTime viewedAt;

  Map<String, dynamic> toJson() => {
        'wallpaperId': wallpaperId,
        'viewedAt': viewedAt.toUtc().toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        wallpaperId: (json['wallpaperId'] ?? json['id'] ?? '').toString(),
        viewedAt: _parseTime(json['viewedAt']),
      );

  @override
  bool operator ==(Object other) =>
      other is HistoryItem && other.wallpaperId == wallpaperId;

  @override
  int get hashCode => wallpaperId.hashCode;
}

DateTime _parseTime(Object? raw) {
  if (raw is String) {
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  return DateTime.fromMillisecondsSinceEpoch(0);
}
