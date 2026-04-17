import 'package:wealthfolio_flutter/core/utils/json_parsing.dart';

/// A classification scheme (e.g. "Asset Classes", "Industries (GICS)").
/// Mirrors the server's `Taxonomy` (camelCase).
class Taxonomy {
  const Taxonomy({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.isSystem,
    required this.isSingleSelect,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Hex colour string, e.g. `#8abceb`.
  final String color;

  final String? description;

  /// System taxonomies cannot be deleted by the user.
  final bool isSystem;

  /// When true, only one category per asset is allowed in this taxonomy.
  final bool isSingleSelect;

  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory Taxonomy.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Taxonomy(
      id: parseString(map['id']),
      name: parseString(map['name']),
      color: parseString(map['color'], fallback: '#8abceb'),
      description: map['description'] as String?,
      isSystem: parseBool(map['isSystem']),
      isSingleSelect: parseBool(map['isSingleSelect']),
      sortOrder: parseInt(map['sortOrder']),
      createdAt: parseString(map['createdAt']),
      updatedAt: parseString(map['updatedAt']),
    );
  }
}

/// A hierarchical category inside a taxonomy.
class Category {
  const Category({
    required this.id,
    required this.taxonomyId,
    this.parentId,
    required this.name,
    required this.key,
    required this.color,
    this.description,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String taxonomyId;
  final String? parentId;
  final String name;
  final String key;
  final String color;
  final String? description;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory Category.fromJson(dynamic raw) {
    final map = parseMap(raw);
    return Category(
      id: parseString(map['id']),
      taxonomyId: parseString(map['taxonomyId']),
      parentId: map['parentId'] as String?,
      name: parseString(map['name']),
      key: parseString(map['key']),
      color: parseString(map['color'], fallback: '#808080'),
      description: map['description'] as String?,
      sortOrder: parseInt(map['sortOrder']),
      createdAt: parseString(map['createdAt']),
      updatedAt: parseString(map['updatedAt']),
    );
  }
}

/// Response from `GET /api/v1/taxonomies/{id}` — bundles a taxonomy with
/// its categories.
class TaxonomyWithCategories {
  const TaxonomyWithCategories({
    required this.taxonomy,
    required this.categories,
  });

  final Taxonomy taxonomy;
  final List<Category> categories;

  factory TaxonomyWithCategories.fromJson(dynamic raw) {
    final map = parseMap(raw);
    final rawCategories = parseList(map['categories']);
    return TaxonomyWithCategories(
      taxonomy: Taxonomy.fromJson(map['taxonomy']),
      categories: rawCategories.map(Category.fromJson).toList(),
    );
  }
}
