import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/data/mock_data.dart' as fixtures;
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';

class RejectingOrderRepository extends DemoRepository {
  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    throw StateError('offline');
  }
}

void main() {
  test('module changes notify existing screens through AppState', () async {
    final state = AppState(repository: DemoRepository());
    addTearDown(state.dispose);
    final loading = <bool>[];
    state.addListener(() => loading.add(state.busy));
    await state.catalog.loadCatalog();
    expect(state.products, same(state.catalog.products));
    expect(state.products, isNotEmpty);
    expect(loading, [true, false]);
    await state.loadAdminData();
    expect(state.adminProducts, same(state.admin.adminProducts));
    expect(state.adminProducts, isNotEmpty);
  });

  test('logout clears records in the separated modules before another session',
      () async {
    final state = AppState(repository: DemoRepository());
    addTearDown(state.dispose);
    await state.requestOtp('07501234567');
    await state.verifyOtp('07501234567', '1234', UserRole.superAdmin);
    await state.loadAdminData();
    await state.saveAdminRecord('finance', 'commission', {'percentage': 12});
    state.addToCart(fixtures.products.first);
    await state.logout();
    expect(state.session.user, isNull);
    expect(state.session.authChallenge, isNull);
    expect(state.admin.adminUsers, isEmpty);
    expect(state.admin.adminProducts, isEmpty);
    expect(state.admin.adminRecords, isEmpty);
    expect(state.admin.adminMetrics, isEmpty);
    expect(state.admin.storeSettlements, isEmpty);
    expect(state.admin.paymentTransactions, isEmpty);
    expect(state.admin.refundRequests, isEmpty);
    expect(state.orderState.orders, isEmpty);
    expect(state.cart, isEmpty);
  });

  test('failed order update restores status and notifies observers', () async {
    final state = AppState(repository: RejectingOrderRepository());
    addTearDown(state.dispose);
    final order = AppOrder(
        id: 'test',
        items: [OrderItem(fixtures.products.first, 1)],
        deliveryFee: 5000,
        address: 'بغداد');
    final statuses = <OrderStatus>[];
    state.addListener(() => statuses.add(order.status));
    await expectLater(state.updateOrderStatus(order, OrderStatus.preparing),
        throwsStateError);
    expect(order.status, OrderStatus.newOrder);
    expect(statuses, [
      OrderStatus.newOrder,
      OrderStatus.preparing,
      OrderStatus.newOrder,
      OrderStatus.newOrder
    ]);
  });
}
