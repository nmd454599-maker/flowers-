import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/data/mock_data.dart' as fixtures;
import 'package:azharna_pro/domain/cart/shopping_cart.dart';
import 'package:azharna_pro/domain/catalog/catalog_search.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';

class FailingCheckoutRepository extends DemoRepository {
  @override
  Future<String> createOrder(AppOrder order) async =>
      throw StateError('offline');
}

void main() {
  group('ShoppingCart', () {
    test('delivery is charged once and removed when the last item is removed',
        () {
      final cart = ShoppingCart();
      final product = fixtures.products.first;
      expect(cart.total, 0);
      cart.add(product);
      cart.add(product);
      expect(cart.count, 2);
      expect(cart.total, product.price * 2 + 5000);
      cart.decrement(product);
      expect(cart.total, product.price + 5000);
      cart.decrement(product);
      expect(cart.items, isEmpty);
      expect(cart.deliveryFee, 0);
      cart.decrement(product);
      expect(cart.count, 0);
    });

    test('removing an item leaves other products and totals intact', () {
      final cart = ShoppingCart();
      cart.add(fixtures.products.first);
      cart.add(fixtures.products.last);
      cart.remove(fixtures.products.first);
      expect(cart.items.keys, [fixtures.products.last]);
      expect(cart.subtotal, fixtures.products.last.price);
      cart.clear();
      expect(cart.total, 0);
    });

    test('failed checkout retains the basket and creates no local order',
        () async {
      final state = AppState(repository: FailingCheckoutRepository());
      addTearDown(state.dispose);
      state.addToCart(fixtures.products.first);
      await expectLater(state.checkout('بغداد'), throwsStateError);
      expect(state.cartCount, 1);
      expect(state.orders, isEmpty);
      expect(state.busy, isFalse);
    });

    test('AppState notifies existing screens and clears the basket on logout',
        () async {
      final state = AppState(repository: DemoRepository());
      addTearDown(state.dispose);
      final quantities = <int>[];
      state.addListener(() => quantities.add(state.cartCount));
      state.addToCart(fixtures.products.first);
      state.addToCart(fixtures.products.first);
      state.decrement(fixtures.products.first);
      await state.logout();
      expect(quantities, [1, 2, 1, 0, 0]);
      expect(state.cartTotal, 0);
    });
  });

  group('CatalogSearch', () {
    const search = CatalogSearch();
    test('blank search preserves discovery limits and hides store results', () {
      expect(
          search.products([...fixtures.products, ...fixtures.products], '  '),
          hasLength(6));
      expect(search.stores(fixtures.stores, ''), isEmpty);
    });

    test('matches category and description while trimming whitespace', () {
      expect(search.products(fixtures.products, ' الزهور ').map((p) => p.id),
          ['p1', 'p2']);
      expect(search.products(fixtures.products, 'بلجيكية').single.id, 'p3');
      expect(search.products(fixtures.products, 'غير موجود'), isEmpty);
    });

    test('matches store name and city without changing the source', () {
      expect(search.stores(fixtures.stores, 'روز').single.id, 's1');
      expect(search.stores(fixtures.stores, ' بغداد '), hasLength(3));
      expect(fixtures.stores, hasLength(3));
    });
  });
}
