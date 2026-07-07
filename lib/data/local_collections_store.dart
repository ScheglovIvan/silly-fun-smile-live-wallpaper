import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/collection_entry.dart';

/// Immutable snapshot of both local collections, as read from / written to
/// on-device storage.
@immutable
class LocalCollectionsSnapshot {
  const LocalCollectionsSnapshot({
    this.favourites = const [],
    this.history = const [],
  });

  /// Favourited wallpapers, most-recently-added first.
  final List<Favourite> favourites;

  /// Recently-viewed wallpapers, most-recently-viewed first.
  final List<HistoryItem> history;
}

/// Device-local persistence for the Favourites and History collections.
///
/// app_spec `persistence`: "Favourites and History stored locally on device".
/// Backed by [SharedPreferences] (browser `localStorage` on the web preview,
/// `NSUserDefaults` / `SharedPreferences` on device) and serialised as JSON.
///
/// Every method is defensive: if the platform plugin is unavailable (e.g. a
/// headless render before plugins register) reads yield empty collections and
/// writes silently no-op, so the in-memory controller keeps working and simply
/// forgoes durability for that session.
class LocalCollectionsStore {
  LocalCollectionsStore();

  static const String _favouritesKey = 'local.favourites.v1';
  static const String _historyKey = 'local.history.v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences?> _instance() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
    return _prefs;
  }

  /// Load both collections from disk. Returns empty collections on first launch
  /// or when storage is unavailable.
  Future<LocalCollectionsSnapshot> load() async {
    final prefs = await _instance();
    if (prefs == null) return const LocalCollectionsSnapshot();
    return LocalCollectionsSnapshot(
      favourites: _decodeList(
        prefs.getString(_favouritesKey),
        Favourite.fromJson,
      ),
      history: _decodeList(
        prefs.getString(_historyKey),
        HistoryItem.fromJson,
      ),
    );
  }

  Future<void> saveFavourites(List<Favourite> favourites) =>
      _writeList(_favouritesKey, favourites.map((f) => f.toJson()));

  Future<void> saveHistory(List<HistoryItem> history) =>
      _writeList(_historyKey, history.map((h) => h.toJson()));

  Future<void> _writeList(
    String key,
    Iterable<Map<String, dynamic>> entries,
  ) async {
    final prefs = await _instance();
    if (prefs == null) return;
    try {
      await prefs.setString(key, jsonEncode(entries.toList()));
    } catch (_) {
      // Best-effort persistence — ignore write failures.
    }
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      return decoded
          .whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .where((e) => (e as dynamic).wallpaperId != '')
          .toList();
    } catch (_) {
      return <T>[];
    }
  }
}
