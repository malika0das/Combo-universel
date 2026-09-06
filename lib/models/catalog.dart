class Catalog {
  final int version;
  final String updatedAt;
  final String notice;
  final List<Category> categories;

  const Catalog({
    required this.version,
    required this.updatedAt,
    required this.notice,
    required this.categories,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        version: (json['version'] as num?)?.toInt() ?? 0,
        updatedAt: json['updatedAt'] as String? ?? '',
        notice: json['notice'] as String? ?? '',
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Flat list of every group with its category/brand context, used for search.
  List<SearchHit> search(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final hits = <SearchHit>[];
    for (final category in categories) {
      for (final brand in category.brands) {
        for (final group in brand.groups) {
          final matched = group.models
              .where((m) => m.toLowerCase().contains(query))
              .toList();
          final titleMatch = group.title.toLowerCase().contains(query) ||
              group.code.toLowerCase().contains(query);
          if (matched.isEmpty && !titleMatch) continue;
          hits.add(SearchHit(
            category: category,
            brand: brand,
            group: group,
            matchedModels: matched,
            exact: matched.any((m) => m.toLowerCase() == query),
          ));
        }
      }
    }
    hits.sort((a, b) {
      if (a.exact != b.exact) return a.exact ? -1 : 1;
      return b.matchedModels.length.compareTo(a.matchedModels.length);
    });
    return hits;
  }
}

class Category {
  final String id;
  final String name;
  final String icon;
  final List<Brand> brands;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.brands,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? 'display',
        brands: (json['brands'] as List<dynamic>? ?? [])
            .map((e) => Brand.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get modelCount =>
      brands.fold(0, (sum, b) => sum + b.groups.fold(0, (s, g) => s + g.models.length));
}

class Brand {
  final String id;
  final String name;
  final List<ComboGroup> groups;

  const Brand({required this.id, required this.name, required this.groups});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        groups: (json['groups'] as List<dynamic>? ?? [])
            .map((e) => ComboGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get modelCount => groups.fold(0, (s, g) => s + g.models.length);
}

class ComboGroup {
  final String code;
  final String title;
  final String quality;
  final String note;
  final List<String> models;

  const ComboGroup({
    required this.code,
    required this.title,
    required this.quality,
    required this.note,
    required this.models,
  });

  factory ComboGroup.fromJson(Map<String, dynamic> json) => ComboGroup(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        quality: json['quality'] as String? ?? '',
        note: json['note'] as String? ?? '',
        models: (json['models'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  String get shareText =>
      '$title ($code)\nCompatible models:\n${models.map((m) => '• $m').join('\n')}'
      '${note.isEmpty ? '' : '\n\nNote: $note'}\n\nvia Combo Universal app';
}

class SearchHit {
  final Category category;
  final Brand brand;
  final ComboGroup group;
  final List<String> matchedModels;
  final bool exact;

  const SearchHit({
    required this.category,
    required this.brand,
    required this.group,
    required this.matchedModels,
    required this.exact,
  });
}
