import 'package:flutter/widgets.dart';

import 'local_collections_store.dart';
import 'models/collection_entry.dart';

/// App-wide state holder for the two per-device collections: **Favourites**
/// (wallpapers the user hearted) and **History** (wallpapers recently viewed).
///
/// Mirrors the app_spec `Favourite` / `HistoryItem` entities and behaviour:
/// "Favouriting toggles a local Favourites collection reflected in the Favourite
/// tab" and both collections are "per-device (local) … empty until the user
/// acts". State is kept in memory for instant UI reaction and mirrored to
/// on-device storage via [LocalCollectionsStore] so it survives relaunch.
///
/// Screens read it through [LocalCollectionsScope.of] (subscribes to rebuilds)
/// or [LocalCollectionsScope.read] (one-shot). The favourite grids/preview call
/// [toggleFavourite]; opening a preview calls [recordView]; the Favourite screen
/// renders [favourites] / [history] and their empty states.
class LocalCollectionsController extends ChangeNotifier {
  LocalCollectionsController({
    LocalCollectionsStore? store,
    this.historyLimit = 100,
  }) : _store = store ?? LocalCollectionsStore();

  final LocalCollectionsStore _store;

  /// Maximum number of History entries retained; oldest views are trimmed.
  final int historyLimit;

  // Ordered most-recent-first, unique by wallpaper id.
  final List<Favourite> _favourites = <Favourite>[];
  final List<HistoryItem> _history = <HistoryItem>[];
  final Set<String> _favouriteIds = <String>{};

  bool _loaded = false;

  /// True once the initial load from storage has completed.
  bool get isLoaded => _loaded;

  /// Favourited wallpapers, most-recently-added first.
  List<Favourite> get favourites => List.unmodifiable(_favourites);

  /// Recently-viewed wallpapers, most-recently-viewed first.
  List<HistoryItem> get history => List.unmodifiable(_history);

  /// Ids of favourited wallpapers, most-recently-added first.
  List<String> get favouriteIds =>
      List.unmodifiable(_favourites.map((f) => f.wallpaperId));

  /// Ids of recently-viewed wallpapers, most-recently-viewed first.
  List<String> get historyIds =>
      List.unmodifiable(_history.map((h) => h.wallpaperId));

  int get favouriteCount => _favourites.length;
  int get historyCount => _history.length;

  bool get hasFavourites => _favourites.isNotEmpty;
  bool get hasHistory => _history.isNotEmpty;

  /// Whether [wallpaperId] is currently in the Favourites collection.
  bool isFavourite(String wallpaperId) => _favouriteIds.contains(wallpaperId);

  /// Hydrate both collections from on-device storage. Safe to call more than
  /// once — subsequent calls are no-ops.
  Future<void> load() async {
    if (_loaded) return;
    final snapshot = await _store.load();
    _favourites
      ..clear()
      ..addAll(snapshot.favourites);
    _history
      ..clear()
      ..addAll(snapshot.history.take(historyLimit));
    _rebuildIndex();
    _loaded = true;
    notifyListeners();
  }

  /// Toggle the favourite state of [wallpaperId] and return the new state.
  ///
  /// Adds a [Favourite] (to the front) when previously unset, removes it
  /// otherwise, then persists and notifies listeners so the heart and the
  /// Favourite tab update immediately.
  bool toggleFavourite(String wallpaperId, {DateTime? at}) {
    final next = !isFavourite(wallpaperId);
    setFavourite(wallpaperId, next, at: at);
    return next;
  }

  /// Force the favourite state of [wallpaperId] to [value].
  void setFavourite(String wallpaperId, bool value, {DateTime? at}) {
    if (wallpaperId.isEmpty) return;
    final currently = isFavourite(wallpaperId);
    if (currently == value) return;

    if (value) {
      _favourites.insert(
        0,
        Favourite(wallpaperId: wallpaperId, addedAt: at ?? DateTime.now()),
      );
      _favouriteIds.add(wallpaperId);
    } else {
      _favourites.removeWhere((f) => f.wallpaperId == wallpaperId);
      _favouriteIds.remove(wallpaperId);
    }
    _store.saveFavourites(_favourites);
    notifyListeners();
  }

  /// Record that [wallpaperId] was viewed, moving it to the front of History
  /// (de-duplicated) and trimming to [historyLimit].
  void recordView(String wallpaperId, {DateTime? at}) {
    if (wallpaperId.isEmpty) return;
    _history.removeWhere((h) => h.wallpaperId == wallpaperId);
    _history.insert(
      0,
      HistoryItem(wallpaperId: wallpaperId, viewedAt: at ?? DateTime.now()),
    );
    if (_history.length > historyLimit) {
      _history.removeRange(historyLimit, _history.length);
    }
    _store.saveHistory(_history);
    notifyListeners();
  }

  /// Empty the Favourites collection.
  void clearFavourites() {
    if (_favourites.isEmpty) return;
    _favourites.clear();
    _favouriteIds.clear();
    _store.saveFavourites(_favourites);
    notifyListeners();
  }

  /// Empty the History collection.
  void clearHistory() {
    if (_history.isEmpty) return;
    _history.clear();
    _store.saveHistory(_history);
    notifyListeners();
  }

  void _rebuildIndex() {
    _favouriteIds
      ..clear()
      ..addAll(_favourites.map((f) => f.wallpaperId));
  }
}

/// Provides a [LocalCollectionsController] to the subtree and rebuilds
/// dependents when Favourites / History change.
///
/// ```dart
/// final local = LocalCollectionsScope.of(context);
/// IconButton(
///   icon: Icon(local.isFavourite(w.id) ? Icons.favorite : Icons.favorite_border),
///   onPressed: () => LocalCollectionsScope.read(context).toggleFavourite(w.id),
/// );
/// ```
class LocalCollectionsScope
    extends InheritedNotifier<LocalCollectionsController> {
  const LocalCollectionsScope({
    super.key,
    required LocalCollectionsController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocalCollectionsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LocalCollectionsScope>();
    assert(scope?.notifier != null, 'No LocalCollectionsScope found in context');
    return scope!.notifier!;
  }

  /// Read the controller without subscribing to rebuilds.
  static LocalCollectionsController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<LocalCollectionsScope>()
        ?.widget as LocalCollectionsScope?;
    assert(scope?.notifier != null, 'No LocalCollectionsScope found in context');
    return scope!.notifier!;
  }
}
