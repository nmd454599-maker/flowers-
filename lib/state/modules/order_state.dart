import '../../domain/orders/order_transitions.dart';
import '../../data/app_repository.dart';
import '../../models/models.dart';
import '../operation_runner.dart';
import '../../domain/cart/shopping_cart.dart';

class OrderState {
  final AppRepository repository;
  final OperationRunner _run;
  final ShoppingCart cart;
  final AppUser? Function() getUser;
  final void Function() onChanged;
  final List<AppOrder> orders = [];
  OrderState(
      {required this.repository,
      required OperationRunner run,
      required this.cart,
      required this.getUser,
      required this.onChanged})
      : _run = run;
  Future<void> refreshOrders() async {
    final signedIn = getUser();
    if (signedIn == null || signedIn.role == UserRole.superAdmin) return;
    await _run((token) async {
      final loaded = signedIn.role == UserRole.store
          ? await token.wait(repository.fetchOrders(storeId: signedIn.storeId))
          : await token.wait(repository.fetchOrders(customerId: signedIn.id));
      orders
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<AppOrder> checkout(String address,
      {PaymentMethod paymentMethod = PaymentMethod.cash,
      String? couponId,
      int discount = 0,
      int walletUsed = 0}) async {
    if (cart.items.isEmpty) throw StateError('السلة فارغة');
    if (address.trim().isEmpty) throw StateError('أدخل عنوان التوصيل');
    final order = AppOrder(
      couponId: couponId,
      discount: discount,
      walletUsed: walletUsed,
      id: '#${1025 + orders.length}',
      items: cart.items.entries.map((e) => OrderItem(e.key, e.value)).toList(),
      deliveryFee: cart.deliveryFee,
      address: address,
      status: OrderStatus.newOrder,
      paymentMethod: paymentMethod,
    );
    await _run((token) async {
      order.id = await token.wait(repository.createOrder(order));
      orders.insert(0, order);
      cart.clear();
    });
    return order;
  }

  Future<void> updateOrderStatus(AppOrder order, OrderStatus status) async {
    await _run((token) async {
      if (!canAdvanceOrder(order.status, status)) {
        throw StateError('انتقال حالة الطلب غير مسموح');
      }
      final previous = order.status;
      order.status = status;
      onChanged();
      try {
        await token.wait(repository.updateOrderStatus(order.id, status));
      } catch (_) {
        if (token.isCurrent) {
          order.status = previous;
          onChanged();
        }
        rethrow;
      }
    });
  }
}
