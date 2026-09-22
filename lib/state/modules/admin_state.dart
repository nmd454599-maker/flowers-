import '../../domain/orders/order_transitions.dart';
import '../../data/app_repository.dart';
import '../../models/models.dart';
import '../operation_runner.dart';
import 'catalog_state.dart';

/// Administrative records and workflows, sharing the injected repository.
class AdminState {
  final AppRepository repository;
  final OperationRunner _run;
  final CatalogState catalog;
  AdminState(
      {required this.repository,
      required OperationRunner run,
      required this.catalog})
      : _run = run;
  List<AdminStoreRecord> adminStores = [];
  List<AdminUserRecord> adminUsers = [];
  List<AdminProductRecord> adminProducts = [];
  List<AdminOrderRecord> adminOrders = [];
  List<AdminAuditRecord> adminAuditLogs = [];
  List<StoreSettlement> storeSettlements = [];
  List<PaymentTransaction> paymentTransactions = [];
  List<RefundRequest> refundRequests = [];
  final Map<String, List<AdminRecord>> adminRecords = {};
  Map<String, num> adminMetrics = const {};

  Future<void> loadAdminData() async {
    await _run((token) async {
      final results = await token.wait(Future.wait([
        repository.fetchAdminStores(),
        repository.fetchAdminUsers(),
        repository.fetchAdminProducts(),
        repository.fetchAdminOrders(),
        repository.fetchAdminAuditLogs(),
        repository.fetchStoreSettlements(),
        repository.fetchPaymentTransactions(),
        repository.fetchRefundRequests(),
        repository.fetchAdminMetrics(),
      ]));
      adminStores = results[0] as List<AdminStoreRecord>;
      adminUsers = results[1] as List<AdminUserRecord>;
      adminProducts = results[2] as List<AdminProductRecord>;
      adminOrders = results[3] as List<AdminOrderRecord>;
      adminAuditLogs = results[4] as List<AdminAuditRecord>;
      storeSettlements = results[5] as List<StoreSettlement>;
      paymentTransactions = results[6] as List<PaymentTransaction>;
      refundRequests = results[7] as List<RefundRequest>;
      adminMetrics = results[8] as Map<String, num>;
    });
  }

  Future<void> reviewStore(AdminStoreRecord store, StoreApprovalStatus status,
      {String? reason}) async {
    await _run((token) async {
      await token
          .wait(repository.updateStoreApproval(store.id, status, reason));
      adminStores = await token.wait(repository.fetchAdminStores());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  Future<void> updateManagedUser(
      AdminUserRecord managedUser, UserRole role, bool active) async {
    await _run((token) async {
      await token
          .wait(repository.updateAdminUser(managedUser.id, role, active));
      adminUsers = await token.wait(repository.fetchAdminUsers());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  Future<void> reviewProduct(
      AdminProductRecord product, ProductApprovalStatus status,
      {String? reason}) async {
    await _run((token) async {
      await token
          .wait(repository.reviewAdminProduct(product.id, status, reason));
      adminProducts = await token.wait(repository.fetchAdminProducts());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
      catalog.products = await token.wait(repository.fetchProducts());
    });
  }

  Future<void> loadAdminScope(String scope) async {
    await _run((token) async {
      adminRecords[scope] =
          await token.wait(repository.fetchAdminRecords(scope));
    });
  }

  Future<String> saveAdminRecord(
      String scope, String? recordId, Map<String, Object?> data) async {
    var id = recordId ?? '';
    await _run((token) async {
      id = await token.wait(repository.saveAdminRecord(scope, recordId, data));
      adminRecords[scope] =
          await token.wait(repository.fetchAdminRecords(scope));
    });
    return id;
  }

  Future<void> updateAdminOrderStatus(
      AdminOrderRecord order, OrderStatus status) async {
    await _run((token) async {
      if (!canAdvanceOrder(order.status, status)) {
        throw StateError('انتقال حالة الطلب غير مسموح');
      }
      await token.wait(repository.updateOrderStatus(order.id, status));
      adminOrders = await token.wait(repository.fetchAdminOrders());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  Future<void> createSettlement(StoreSettlement settlement) async {
    await _run((token) async {
      await token.wait(repository.saveStoreSettlement(settlement));
      storeSettlements = await token.wait(repository.fetchStoreSettlements());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  Future<void> updateSettlement(
      StoreSettlement settlement, SettlementStatus status,
      {String? transferReference}) async {
    await _run((token) async {
      await token.wait(repository.updateSettlementStatus(
          settlement.id, status, transferReference));
      storeSettlements = await token.wait(repository.fetchStoreSettlements());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  Future<void> createRefund(RefundRequest refund) async {
    await _run((token) async {
      await token.wait(repository.createRefundRequest(refund));
      refundRequests = await token.wait(repository.fetchRefundRequests());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  Future<void> updateRefund(RefundRequest refund, RefundStatus status,
      {String? note}) async {
    await _run((token) async {
      await token.wait(repository.updateRefundStatus(refund.id, status, note));
      refundRequests = await token.wait(repository.fetchRefundRequests());
      adminAuditLogs = await token.wait(repository.fetchAdminAuditLogs());
    });
  }

  void clear() {
    adminStores = [];
    adminUsers = [];
    adminProducts = [];
    adminOrders = [];
    adminAuditLogs = [];
    adminRecords.clear();
    adminMetrics = const {};
    storeSettlements = [];
    paymentTransactions = [];
    refundRequests = [];
  }
}
