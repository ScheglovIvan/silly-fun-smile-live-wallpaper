import 'package:flutter/widgets.dart';

import 'catalog_repository.dart';
import 'media_cache.dart';
import 'models/catalog_mode.dart';
import 'models/category.dart';
import 'models/wallpaper.dart';

/// Loading lifecycle of the catalog.
enum CatalogStatus { idle, loading, ready, error }

/// UI-facing state holder for the wallpaper catalog.
///
/// Wraps [CatalogRepository] as a [ChangeNotifier] and tracks the Home
/// selection state: the active [CatalogMode] (Live / 4K toggle) and the
/// selected category chip. Screens read it via [CatalogScope.of].
class CatalogController extends ChangeNotifier {
  CatalogController({CatalogRepository? repository})
      : repository = repository ?? CatalogRepository();

  final CatalogRepository repository;

  CatalogStatus _status = CatalogStatus.idle;
  CatalogStatus get status => _status;

  /// Non-null when the last load fell back to the bundled seed (offline).
  String? _offlineReason;
  String? get offlineReason => _offlineReason;
  bool get isOffline => _offlineReason != null;

  CatalogMode _mode = CatalogMode.live;
  CatalogMode get mode => _mode;

  /// Selected category id for the active mode, or null for "all".
  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  MediaCache get media => repository.media;
  bool get isReady => _status == CatalogStatus.ready;

  /// Kick off a catalog load. Renders the seed synchronously first so the UI
  /// never blocks on the network, then refreshes from the CDN.
  Future<void> load() async {
    if (_status == CatalogStatus.loading) return;
    _status = CatalogStatus.loading;
    // Immediate seed so the first frame has content (esp. web preview).
    if (!repository.isLoaded) repository.loadSeed();
    notifyListeners();

    final error = await repository.load();
    _offlineReason = error?.message;
    _status = CatalogStatus.ready;
    _ensureSelectionValid();
    notifyListeners();
  }

  /// Switch the Live / 4K toggle. Resets the category selection to "all".
  void setMode(CatalogMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _selectedCategoryId = null;
    notifyListeners();
  }

  /// Select a category chip (null clears the filter).
  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // ---- Derived views used by screens --------------------------------------

  List<Category> get categories => repository.categories(_mode);

  /// Wallpapers for the active mode + selected category.
  List<Wallpaper> get wallpapers =>
      repository.wallpapers(_mode, categoryId: _selectedCategoryId);

  List<Wallpaper> get trending => repository.trending();

  Wallpaper? wallpaperById(String id) => repository.wallpaperById(id);
  List<Wallpaper> resolveIds(Iterable<String> ids) =>
      repository.resolveIds(ids);

  void _ensureSelectionValid() {
    if (_selectedCategoryId == null) return;
    final stillExists =
        categories.any((c) => c.id == _selectedCategoryId);
    if (!stillExists) _selectedCategoryId = null;
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}

/// Provides a [CatalogController] to the widget subtree and rebuilds dependents
/// when it changes.
///
/// Usage:
/// ```dart
/// CatalogScope(
///   controller: controller,
///   child: MaterialApp(...),
/// );
/// // in a screen:
/// final catalog = CatalogScope.of(context);
/// ```
class CatalogScope extends InheritedNotifier<CatalogController> {
  const CatalogScope({
    super.key,
    required CatalogController controller,
    required super.child,
  }) : super(notifier: controller);

  static CatalogController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CatalogScope>();
    assert(scope?.notifier != null, 'No CatalogScope found in context');
    return scope!.notifier!;
  }

  /// Read the controller without subscribing to rebuilds.
  static CatalogController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<CatalogScope>()
        ?.widget as CatalogScope?;
    assert(scope?.notifier != null, 'No CatalogScope found in context');
    return scope!.notifier!;
  }
}
