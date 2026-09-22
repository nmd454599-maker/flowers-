import '../../data/app_repository.dart';
import '../../models/models.dart';
import '../operation_runner.dart';

/// Catalog data and mutations; storage and notifications are injected.
class CatalogState {
  final AppRepository repository;
  final OperationRunner _run;
  final void Function() onChanged;
  List<Store> stores = [];
  List<Product> products = [];
  String selectedCity = 'بغداد';
  int _loadId = 0;
  CatalogState(
      {required this.repository,
      required OperationRunner run,
      required this.onChanged})
      : _run = run;
  Future<void> loadCatalog() => _run(loadForSession);

  Future<void> loadForSession(OperationToken token) async {
    final loadId = ++_loadId;
    final city = selectedCity;
    final results = await token.wait(Future.wait([
      repository.fetchStores(city),
      repository.fetchProducts(),
    ]));
    if (loadId != _loadId) return;
    stores = results[0] as List<Store>;
    products = results[1] as List<Product>;
  }

  Future<void> selectCity(String city) async {
    if (city == selectedCity) return;
    selectedCity = city;
    onChanged();
    await loadCatalog();
  }

  Future<void> saveStoreProduct(Product product) async {
    await _run((token) async {
      final saved = await token.wait(repository.saveProduct(product));
      products = await token.wait(repository.fetchProducts());
      final index = products.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        products.add(saved);
      } else {
        products[index] = saved;
      }
    });
  }
}
