import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/main.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/data/app_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/screens/admin/admin_tools_screen.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Azharna app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AzharnaApp());

    expect(find.byType(AzharnaApp), findsOneWidget);
  });

  testWidgets('super admin center exposes all twelve tools',
      (WidgetTester tester) async {
    final state = AppState(repository: DemoRepository());
    await tester.pumpWidget(MaterialApp(home: AdminToolsScreen(state: state)));

    expect(find.byType(AdminToolsScreen), findsOneWidget);
    expect(AdminToolsScreen.tools, hasLength(12));
    expect(find.text('مركز الموافقات'), findsOneWidget);
    expect(AdminToolsScreen.tools.last.$2, 'الأمان وسجل التدقيق');
  });

  testWidgets('finance settings persist through the repository',
      (WidgetTester tester) async {
    final state = AppState(repository: DemoRepository());
    await tester.pumpWidget(MaterialApp(
        home: AdminToolScreen(
            state: state,
            tool: AdminTool.finance,
            title: 'المالية والعمولات')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ نسبة العمولة'));
    await tester.pumpAndSettle();

    expect(state.adminRecords['finance'], isNotEmpty);
    expect(state.adminRecords['finance']!.first.id, 'commission');
  });

  test('demo admin phone always resolves to the super admin account', () async {
    final repository = DemoRepository();
    final user = await repository.verifyOtp(
      challenge: const AuthChallenge('demo'),
      code: '1234',
      phone: '07501234567',
      role: UserRole.customer,
    );

    expect(user.role, UserRole.superAdmin);
  });

  test('admin can reject a product with a recorded reason', () async {
    final repository = DemoRepository();
    await repository.reviewAdminProduct(
        'p1', ProductApprovalStatus.rejected, 'صورة غير واضحة');

    final product =
        (await repository.fetchAdminProducts()).firstWhere((p) => p.id == 'p1');
    expect(product.status, ProductApprovalStatus.rejected);
    expect(product.rejectionReason, 'صورة غير واضحة');
    expect(product.active, isFalse);
    final audit = await repository.fetchAdminAuditLogs();
    expect(audit.first.action, 'product.review');
    expect(audit.first.targetId, 'p1');
  });

  test('store application starts pending and becomes visible after approval',
      () async {
    final repository = DemoRepository();
    final id = await repository.submitStoreApplication({
      'ownerId': 'store-1',
      'name': 'متجر جديد',
    });
    expect(await repository.fetchApprovedStoreApplications(), isEmpty);
    await repository.saveAdminRecord('store_applications', id, {
      'ownerId': 'store-1',
      'name': 'متجر جديد',
      'status': 'approved',
    });
    final approved = await repository.fetchApprovedStoreApplications();
    expect(approved.single.id, id);
  });

  test('financial settlement can be created, approved and paid', () async {
    final repository = DemoRepository();
    final now = DateTime(2026, 9, 4);
    final id = await repository.saveStoreSettlement(StoreSettlement(
      id: '',
      storeId: 's1',
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      grossSales: 1000000,
      commission: 120000,
      refunds: 0,
      adjustments: 0,
      netAmount: 880000,
      status: SettlementStatus.draft,
    ));
    await repository.updateSettlementStatus(
        id, SettlementStatus.approved, null);
    await repository.updateSettlementStatus(
        id, SettlementStatus.paid, 'TRX-001');

    final settlement = (await repository.fetchStoreSettlements()).single;
    expect(settlement.status, SettlementStatus.paid);
    expect(settlement.transferReference, 'TRX-001');
    expect(settlement.netAmount, 880000);
  });

  test('super admin controls the complete refund workflow', () async {
    final repository = DemoRepository();
    final id = await repository.createRefundRequest(const RefundRequest(
      id: '',
      orderId: 'order-1',
      customerId: 'customer-1',
      amount: 25000,
      reason: 'إلغاء الطلب',
      liability: RefundLiability.platform,
      status: RefundStatus.requested,
    ));
    await repository.updateRefundStatus(
        id, RefundStatus.approved, 'تمت الموافقة');
    await repository.updateRefundStatus(
        id, RefundStatus.completed, 'أعيد المبلغ');

    final refund = (await repository.fetchRefundRequests()).single;
    expect(refund.status, RefundStatus.completed);
    expect(refund.liability, RefundLiability.platform);
    expect(refund.completedAt, isNotNull);
  });

  test('customer store and admin share the same order lifecycle', () async {
    final repository = DemoRepository();
    final product = (await repository.fetchProducts()).first;
    final order = AppOrder(
      id: 'REL-001',
      items: [OrderItem(product, 2)],
      deliveryFee: 5000,
      address: 'بغداد - الكرادة',
    );
    await repository.createOrder(order);

    final storeOrders = await repository.fetchOrders(storeId: product.storeId);
    expect(storeOrders.single.id, 'REL-001');
    await repository.updateOrderStatus('REL-001', OrderStatus.preparing);

    final customerOrders =
        await repository.fetchOrders(customerId: 'customer-1');
    final adminOrders = await repository.fetchAdminOrders();
    expect(customerOrders.single.status, OrderStatus.preparing);
    expect(adminOrders.single.status, OrderStatus.preparing);
    expect(adminOrders.single.customerId, 'customer-1');
    expect(adminOrders.single.storeIds, contains(product.storeId));
  });
}
