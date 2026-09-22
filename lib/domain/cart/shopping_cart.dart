import '../../models/models.dart';

/// Owns quantity and price calculations. AppState handles UI notifications
/// and persists an order before clearing the basket.
class ShoppingCart {
  final Map<Product, int> items = {};
  final int deliveryCharge;

  ShoppingCart({this.deliveryCharge = 5000});

  int get count => items.values.fold(0, (sum, quantity) => sum + quantity);
  int get subtotal => items.entries
      .fold(0, (sum, entry) => sum + entry.key.price * entry.value);
  int get deliveryFee => items.isEmpty ? 0 : deliveryCharge;
  int get total => subtotal + deliveryFee;

  void add(Product product) => items[product] = (items[product] ?? 0) + 1;

  void decrement(Product product) {
    final current = items[product] ?? 0;
    if (current <= 1) {
      items.remove(product);
    } else {
      items[product] = current - 1;
    }
  }

  void remove(Product product) => items.remove(product);
  void clear() => items.clear();
}
