import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:azharna_pro/data/sqlite_repository.dart';
import 'package:azharna_pro/data/local/database_schema.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/services/customer_account_service.dart';
import 'package:azharna_pro/services/local_store_chat.dart';
import 'support/test_sqlite.dart';

class AttachedRepository extends SqliteRepository {
  AttachedRepository(this.database);
  final Database database;
  @override
  Database get db => database;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'real SQLite: three accounts share orders, moderation, support, chat and durable finance',
      () async {
    final dir = await Directory('artifacts').createTemp('account-flow-');
    var database = await TestSqlite.open('${dir.path}/test.db');
    addTearDown(() async {
      await database.close();
      await dir.delete(recursive: true);
    });
    await DatabaseSchema.create(database);
    await database.insert('stores', {
      'id': 's1',
      'name': 'متجر الفحص',
      'city': 'بغداد',
      'rating': 0,
      'emoji': '🌷',
      'min_order': 0,
      'delivery_minutes': 30
    });
    var repo = AttachedRepository(database);
    Future<AppUser> login(UserRole role, String phone) async {
      await repo.signOut();
      return repo.verifyOtp(
          challenge: await repo.requestOtp(phone),
          code: '1234',
          phone: phone,
          role: role);
    }

    const product = Product(
        id: 'test-product',
        storeId: 's1',
        name: 'ورد',
        category: 'ورد',
        price: 20000,
        emoji: '🌷',
        rating: 0,
        description: 'منتج للفحص');
    final merchant = await login(UserRole.store, '07811234567');
    await repo.saveProduct(product);
    expect((await repo.fetchAdminProducts()).single.status,
        ProductApprovalStatus.pending);
    final customer = await login(UserRole.customer, '07701234567');
    expect(await repo.fetchProducts(), isEmpty);
    await expectLater(repo.saveProduct(product), throwsStateError);
    await login(UserRole.superAdmin, '07501234567');
    await repo.reviewAdminProduct(
        product.id, ProductApprovalStatus.approved, null);
    await login(UserRole.customer, customer.phone);
    expect((await repo.fetchProducts()).single.id, product.id);
    final id = await repo.createOrder(AppOrder(
        id: '',
        items: [OrderItem(product, 2)],
        deliveryFee: 5000,
        address: 'بغداد — عنوان الاختبار',
        status: OrderStatus.newOrder));
    expect(
        (await repo.fetchOrders(customerId: customer.id)).single.total, 45000);
    await expectLater(
        repo.updateOrderStatus(id, OrderStatus.preparing), throwsStateError);
    await CustomerAccountService(repo, customer)
        .submit('support', {'subject': 'سؤال عن الطلب', 'details': id});
    final conversation = <String, Object?>{
      'storeId': 's1',
      'storeName': 'متجر الفحص',
      'customerId': customer.id,
      'customerName': customer.name
    };
    await LocalStoreChat(repo)
        .send(user: customer, conversation: conversation, text: 'مرحبًا');
    await login(UserRole.store, merchant.phone);
    expect((await repo.fetchOrders(storeId: 's1')).single.id, id);
    expect((await LocalStoreChat(repo).messages(merchant)).single.data['text'],
        'مرحبًا');
    await LocalStoreChat(repo)
        .send(user: merchant, conversation: conversation, text: 'أهلًا بك');
    await repo.updateOrderStatus(id, OrderStatus.preparing);
    await expectLater(
        repo.updateOrderStatus(id, OrderStatus.delivered), throwsStateError);
    await repo.updateOrderStatus(id, OrderStatus.delivering);
    await repo.updateOrderStatus(id, OrderStatus.delivered);
    final admin = await login(UserRole.superAdmin, '07501234567');
    expect(
        (await repo.fetchAdminOrders()).single.status, OrderStatus.delivered);
    expect((await repo.fetchPaymentTransactions()).single.status,
        PaymentStatus.paid);
    expect((await repo.fetchAdminMetrics())['orders'], 1);
    expect(await repo.fetchAdminUsers(), hasLength(3));
    expect(await LocalStoreChat(repo).messages(admin), hasLength(2));
    final request = (await repo.fetchAdminRecords('customer_requests')).single;
    await repo.saveAdminRecord('customer_requests', request.id,
        {...request.data, 'reply': 'تمت المتابعة', 'status': 'replied'});
    final settlementId = await repo.saveStoreSettlement(StoreSettlement(
        id: '',
        storeId: 's1',
        periodStart: DateTime(2026, 1),
        periodEnd: DateTime(2026, 2),
        grossSales: 40000,
        commission: 4000,
        refunds: 0,
        adjustments: 0,
        netAmount: 36000,
        status: SettlementStatus.draft));
    await repo.updateSettlementStatus(
        settlementId, SettlementStatus.approved, null);
    final refund = await repo.createRefundRequest(RefundRequest(id: '', orderId: id, customerId: customer.id, amount: 5000, reason: 'فحص استرداد', liability: RefundLiability.platform, status: RefundStatus.requested));
    await expectLater(repo.updateRefundStatus(refund, RefundStatus.completed, null), throwsStateError);
    await repo.updateRefundStatus(refund, RefundStatus.approved, null);
    await repo.updateRefundStatus(refund, RefundStatus.completed, null);
    await repo.updateRefundStatus(refund, RefundStatus.completed, null);
    await database.close();
    database = await TestSqlite.open('${dir.path}/test.db');
    repo = AttachedRepository(database);
    await login(UserRole.customer, customer.phone);
    expect((await CustomerAccountService(repo, customer).read('benefits'))['balance'], 5000);
    expect((await repo.fetchOrders(customerId: customer.id)).single.status,
        OrderStatus.delivered);
    expect(
        (await CustomerAccountService(repo, customer).requests('support'))
            .single['reply'],
        'تمت المتابعة');
    expect(await LocalStoreChat(repo).messages(customer), hasLength(2));
    expect((await repo.fetchStoreSettlements()).single.status,
        SettlementStatus.approved);
    await repo.changeLocalPhone('07709999999', '123456');
    final same = await login(UserRole.customer, '07709999999');
    expect(same.id, customer.id);
    await login(UserRole.superAdmin, '07501234567');
    await repo.updateStoreApproval('s1', StoreApprovalStatus.suspended, null);
    await login(UserRole.customer, '07709999999');
    expect(await repo.fetchProducts(), isEmpty);
    await expectLater(
        repo.createOrder(AppOrder(
            id: '',
            items: [OrderItem(product, 1)],
            deliveryFee: 0,
            address: 'بغداد',
            status: OrderStatus.newOrder)),
        throwsStateError);
    await login(UserRole.superAdmin, '07501234567');
    await repo.updateStoreApproval('s1', StoreApprovalStatus.approved, null);
    await database.insert('stores', {
      'id': 's2',
      'name': 'متجر ثان',
      'city': 'بغداد',
      'rating': 0,
      'emoji': '🌷',
      'min_order': 0,
      'delivery_minutes': 30
    });
    const other = Product(
        id: 'other-product',
        storeId: 's2',
        name: 'هدية',
        category: 'هدايا',
        price: 10000,
        emoji: '🎁',
        rating: 0,
        description: 'فحص');
    await repo.saveProduct(other);
    await login(UserRole.customer, '07709999999');
    final multi = await repo.createOrder(AppOrder(
        id: '',
        items: [OrderItem(product, 1), OrderItem(other, 1)],
        deliveryFee: 0,
        address: 'بغداد',
        status: OrderStatus.newOrder));
    await login(UserRole.store, merchant.phone);
    for (final status in [
      OrderStatus.preparing,
      OrderStatus.delivering,
      OrderStatus.delivered
    ]) {
      await repo.updateOrderStatus(multi, status);
    }
    expect(
        (await repo.fetchOrders(storeId: 's1'))
            .firstWhere((o) => o.id == multi)
            .status,
        OrderStatus.delivered);
    expect(
        (await repo.fetchAdminOrders()).firstWhere((o) => o.id == multi).status,
        OrderStatus.newOrder);
    await login(UserRole.superAdmin, '07501234567');
    for (final status in [
      OrderStatus.preparing,
      OrderStatus.delivering,
      OrderStatus.delivered
    ]) {
      await repo.updateOrderStatus(multi, status);
    }
    expect(
        (await repo.fetchAdminOrders()).firstWhere((o) => o.id == multi).status,
        OrderStatus.delivered);
    await repo.saveAdminRecord('notifications', 'scheduled_test',
        {'scheduledFor': DateTime(2030), 'title': 'فحص'});
    expect(
        (await repo.fetchAdminRecords('notifications'))
            .single
            .data['scheduledFor'],
        '2030-01-01T00:00:00.000');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
