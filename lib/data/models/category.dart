import 'catalog_mode.dart';

/// A themed category chip (e.g. World Cup, Smoking, Naruto).
///
/// Maps the app_spec `Category` entity: `id`, `name`, `mode`, `iconEmoji`,
/// `order`. Each category belongs to exactly one [CatalogMode]; the same theme
/// name may exist under both Live and 4K as two distinct categories.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.mode,
    required this.iconEmoji,
    required this.order,
    this.assetFolder,
  });

  final String id;
  final String name;
  final CatalogMode mode;
  final String iconEmoji;
  final int order;

  /// CDN folder segment for this category's media
  /// (`/il07-smilley-ios/Live_v4/<assetFolder>/...`). Defaults to [name] with
  /// spaces replaced by underscores when absent.
  final String? assetFolder;

  String get folder => assetFolder ?? name.replaceAll(' ', '_');

  factory Category.fromJson(Map<String, dynamic> json, {int fallbackOrder = 0}) {
    return Category(
      id: (json['id'] ?? json['slug'] ?? json['name'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? json['id'] ?? '').toString(),
      mode: CatalogMode.fromWire(json['mode']),
      iconEmoji: (json['iconEmoji'] ?? json['icon'] ?? json['emoji'] ?? '✨')
          .toString(),
      order: json['order'] is num
          ? (json['order'] as num).toInt()
          : fallbackOrder,
      assetFolder: (json['assetFolder'] ?? json['folder'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.wire,
        'iconEmoji': iconEmoji,
        'order': order,
        if (assetFolder != null) 'assetFolder': assetFolder,
      };

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
