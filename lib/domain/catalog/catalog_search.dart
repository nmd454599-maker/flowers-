import '../../models/models.dart';

/// Catalog matching rules, independent of Flutter widgets and storage.
class CatalogSearch {
  const CatalogSearch();

  List<Product> products(Iterable<Product> source, String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return source.take(6).toList();
    return source
        .where((item) =>
            item.name.toLowerCase().contains(value) ||
            item.category.toLowerCase().contains(value) ||
            item.description.toLowerCase().contains(value))
        .toList();
  }

  List<Store> stores(Iterable<Store> source, String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return const [];
    return source
        .where((item) =>
            item.name.toLowerCase().contains(value) ||
            item.city.toLowerCase().contains(value))
        .toList();
  }
}
