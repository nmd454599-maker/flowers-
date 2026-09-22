import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../domain/accounts/reward_account.dart';
import '../../models/models.dart';
import '../demo_repository.dart';

/// Admin views use the same durable records as customers and merchants.
/// Financial actions here are local test records, not bank transfers.
mixin LocalAdminRepository on DemoRepository {
  Database get db;
  AppUser? get signedInUser;
  void requireLocalAdmin() {
    if (signedInUser?.role != UserRole.superAdmin)
      throw StateError('صلاحية الإدارة مطلوبة');
  }

  Future<void> localAudit(
      String action, String target, Map<String, Object?> details) async {
    await saveAdminRecord('account_audit', null, {
      ...details,
      'actorId': signedInUser?.id ?? '',
      'targetId': target,
      'action': action,
    });
  }

  Future<Map<String, Object?>> recordData(String scope, String id) async {
    return (await fetchAdminRecords(scope))
            .where((r) => r.id == id)
            .firstOrNull
            ?.data ??
        {};
  }

  @override
  Future<List<AdminStoreRecord>> fetchAdminStores() async {
    final rows = await db.query('stores');
    final users = await db.query('users');
    final reviews = {
      for (final r in await fetchAdminRecords('store_approvals')) r.id: r.data
    };
    return rows.map((s) {
      final owner = users.where((u) => u['store_id'] == s['id']).firstOrNull;
      final review = reviews[s['id']];
      return AdminStoreRecord(
          id: s['id'] as String,
          name: s['name'] as String,
          city: s['city'] as String,
          ownerName: '${owner?['name'] ?? ''}',
          ownerPhone: '${owner?['phone'] ?? ''}',
          status: StoreApprovalStatus.values
                  .where((v) => v.name == review?['status'])
                  .firstOrNull ??
              StoreApprovalStatus.approved,
          documentsComplete: review?['documentsComplete'] == true);
    }).toList();
  }

  @override
  Future<void> updateStoreApproval(
      String storeId, StoreApprovalStatus status, String? reason) async {
    requireLocalAdmin();
    if (!(await fetchAdminStores()).any((s) => s.id == storeId))
      throw StateError('المتجر غير موجود');
    await saveAdminRecord(
        'store_approvals', storeId, {'status': status.name, 'reason': reason});
    await localAudit('store.approval', storeId, {'status': status.name});
  }

  @override
  Future<List<AdminProductRecord>> fetchAdminProducts() async {
    final rows = await db.query('products');
    final reviews = {
      for (final r in await fetchAdminRecords('product_approvals')) r.id: r.data
    };
    return rows.map((p) {
      final review = reviews[p['id']];
      final status = ProductApprovalStatus.values
              .where((v) => v.name == review?['status'])
              .firstOrNull ??
          ProductApprovalStatus.approved;
      return AdminProductRecord(
          id: p['id'] as String,
          storeId: p['store_id'] as String,
          name: p['name'] as String,
          category: p['category'] as String,
          price: p['price'] as int,
          stock: int.tryParse(RegExp(r'المخزون:\s*(\d+)')
                      .firstMatch('${p['description']}')
                      ?.group(1) ??
                  '') ??
              0,
          imageUrl: p['image_url'] as String?,
          active: status == ProductApprovalStatus.approved,
          status: status,
          rejectionReason: review?['reason'] as String?);
    }).toList();
  }

  @override
  Future<void> reviewAdminProduct(
      String productId, ProductApprovalStatus status, String? reason) async {
    requireLocalAdmin();
    if (!(await fetchAdminProducts()).any((p) => p.id == productId))
      throw StateError('المنتج غير موجود');
    await saveAdminRecord('product_approvals', productId,
        {'status': status.name, 'reason': reason});
    await localAudit('product.review', productId, {'status': status.name});
  }

  @override
  Future<Map<String, num>> fetchAdminMetrics() async {
    final orders = await fetchAdminOrders();
    final sales = orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold<int>(0, (v, o) => v + o.total);
    return {
      'users': (await fetchAdminUsers()).length,
      'stores': (await fetchAdminStores()).length,
      'orders': orders.length,
      'grossSales': sales,
      'averageOrder': orders.isEmpty ? 0 : sales / orders.length,
      'cancellationRate': orders.isEmpty
          ? 0
          : orders.where((o) => o.status == OrderStatus.cancelled).length *
              100 /
              orders.length
    };
  }

  @override
  Future<List<PaymentTransaction>> fetchPaymentTransactions() async => [
        for (final o in await fetchAdminOrders())
          PaymentTransaction(
              id: 'payment_${o.id}',
              orderId: o.id,
              customerId: o.customerId,
              amount: o.total,
              method: o.paymentMethod,
              status: o.status == OrderStatus.delivered
                  ? PaymentStatus.paid
                  : o.status == OrderStatus.cancelled
                      ? PaymentStatus.cancelled
                      : PaymentStatus.pending,
              provider: 'local_cash_preview',
              createdAt: o.createdAt)
      ];
  @override
  Future<List<StoreSettlement>> fetchStoreSettlements() async => [
        for (final r in await fetchAdminRecords('local_settlements'))
          StoreSettlement(
              id: r.id,
              storeId: r.data['storeId'] as String,
              periodStart: DateTime.parse(r.data['periodStart'] as String),
              periodEnd: DateTime.parse(r.data['periodEnd'] as String),
              grossSales: r.data['grossSales'] as int,
              commission: r.data['commission'] as int,
              refunds: r.data['refunds'] as int,
              adjustments: r.data['adjustments'] as int,
              netAmount: r.data['netAmount'] as int,
              status:
                  SettlementStatus.values.byName(r.data['status'] as String),
              transferReference: r.data['transferReference'] as String?,
              createdAt: DateTime.tryParse('${r.data['createdAt']}'),
              paidAt: DateTime.tryParse('${r.data['paidAt']}'))
      ];
  @override
  Future<String> saveStoreSettlement(StoreSettlement s) async {
    requireLocalAdmin();
    final id =
        await saveAdminRecord('local_settlements', s.id.isEmpty ? null : s.id, {
      'storeId': s.storeId,
      'periodStart': s.periodStart.toIso8601String(),
      'periodEnd': s.periodEnd.toIso8601String(),
      'grossSales': s.grossSales,
      'commission': s.commission,
      'refunds': s.refunds,
      'adjustments': s.adjustments,
      'netAmount': s.netAmount,
      'status': s.status.name,
      'transferReference': s.transferReference,
      'createdAt': (s.createdAt ?? DateTime.now()).toIso8601String(),
      'paidAt': s.paidAt?.toIso8601String(),
    });
    await localAudit('settlement.save', id, {'storeId': s.storeId});
    return id;
  }

  @override
  Future<void> updateSettlementStatus(
      String id, SettlementStatus status, String? reference) async {
    requireLocalAdmin();
    final data = await recordData('local_settlements', id);
    if (data.isEmpty) throw StateError('التسوية غير موجودة');
    await saveAdminRecord('local_settlements', id, {
      ...data,
      'status': status.name,
      'transferReference': reference,
      if (status == SettlementStatus.paid)
        'paidAt': DateTime.now().toIso8601String()
    });
    await localAudit('settlement.status', id, {'status': status.name});
  }

  @override
  Future<List<RefundRequest>> fetchRefundRequests() async => [
        for (final r in await fetchAdminRecords('local_refunds'))
          RefundRequest(
              id: r.id,
              orderId: r.data['orderId'] as String,
              customerId: r.data['customerId'] as String,
              amount: r.data['amount'] as int,
              reason: r.data['reason'] as String,
              liability:
                  RefundLiability.values.byName(r.data['liability'] as String),
              status: RefundStatus.values.byName(r.data['status'] as String),
              note: r.data['note'] as String?,
              createdAt: DateTime.tryParse('${r.data['createdAt']}'),
              completedAt: DateTime.tryParse('${r.data['completedAt']}'))
      ];
  @override
  Future<String> createRefundRequest(RefundRequest r) async {
    requireLocalAdmin();
    final order = (await fetchAdminOrders())
        .where((o) => o.id == r.orderId && o.customerId == r.customerId)
        .firstOrNull;
    if (order == null || r.amount <= 0 || r.amount > order.total)
      throw StateError('طلب الاسترداد غير صالح');
    final reserved = (await fetchRefundRequests()).where((x) => x.orderId == r.orderId && x.status != RefundStatus.rejected).fold<int>(0, (sum, x) => sum + x.amount);
    if (reserved + r.amount > order.total) throw StateError('مجموع الاستردادات يتجاوز قيمة الطلب');
    return saveAdminRecord('local_refunds', r.id.isEmpty ? null : r.id, {
      'orderId': r.orderId,
      'customerId': r.customerId,
      'amount': r.amount,
      'reason': r.reason,
      'liability': r.liability.name,
      'status': RefundStatus.requested.name,
      'createdAt': DateTime.now().toIso8601String()
    });
  }

  @override
  Future<void> updateRefundStatus(
      String id, RefundStatus status, String? note) async {
    requireLocalAdmin();
    await db.transaction((txn) async {
      final rows = await txn.query('local_records', where: 'id = ? AND scope = ?', whereArgs: [id, 'local_refunds']);
      if (rows.isEmpty) throw StateError('طلب الاسترداد غير موجود');
      final data = Map<String, Object?>.from(jsonDecode(rows.single['payload'] as String) as Map);
      if (data['status'] == 'completed') {
        if (status == RefundStatus.completed) return;
        throw StateError('لا يمكن تغيير استرداد مكتمل');
      }
      if (status == RefundStatus.completed) {
        if (data['status'] != 'approved') throw StateError('اعتمد طلب الاسترداد أولًا');
        final account = await RewardAccount.read(txn, data['customerId'] as String);
        account.credit(data['amount'] as int, 'استرداد محلي للطلب ${data['orderId']}', signedInUser!.id);
        await account.write(txn, data['customerId'] as String);
      }
      await txn.update('local_records', {'payload': jsonEncode({...data, 'status': status.name, 'note': note,
        if (status == RefundStatus.completed) 'completedAt': DateTime.now().toIso8601String()}), 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    });
    await localAudit('refund.status', id, {'status': status.name});
  }
}
