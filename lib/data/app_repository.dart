import 'dart:typed_data';

import '../models/models.dart';

class AuthChallenge {
  final String verificationId;
  final int? resendToken;

  const AuthChallenge(this.verificationId, {this.resendToken});
}

abstract class AppRepository {
  bool get isDemo;
  Future<void> initialize();
  Future<void> signOut();
  Future<void> requestAccountDeletion() async {
    throw StateError('حذف الحساب متاح في النسخة المتصلة بالخدمة فقط');
  }

  Future<AuthChallenge> requestOtp(String phone);
  Future<AppUser> verifyOtp({
    required AuthChallenge challenge,
    required String code,
    required String phone,
    required UserRole role,
  });
  Future<List<Store>> fetchStores(String city);
  Future<List<Product>> fetchProducts();
  Future<Product> saveProduct(Product product);
  Future<String?> fetchStoreProfilePhoto(String storeId);
  Future<String> saveStoreProfilePhoto(
      {required String storeId,
      required Uint8List bytes,
      required String fileName});
  Future<String> submitStoreApplication(Map<String, Object?> data);
  Future<List<AdminRecord>> fetchApprovedStoreApplications();
  Future<String> saveProductImage({
    required String storeId,
    required Uint8List bytes,
    required String fileName,
  });
  Future<String> createOrder(AppOrder order);
  Future<List<AppOrder>> fetchOrders({String? customerId, String? storeId});
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<List<AdminStoreRecord>> fetchAdminStores();
  Future<List<AdminUserRecord>> fetchAdminUsers();
  Future<List<AdminProductRecord>> fetchAdminProducts();
  Future<List<AdminOrderRecord>> fetchAdminOrders();
  Future<List<AdminAuditRecord>> fetchAdminAuditLogs();
  Future<List<StoreSettlement>> fetchStoreSettlements();
  Future<List<PaymentTransaction>> fetchPaymentTransactions();
  Future<List<RefundRequest>> fetchRefundRequests();
  Future<String> createRefundRequest(RefundRequest refund);
  Future<void> updateRefundStatus(
      String refundId, RefundStatus status, String? note);
  Future<String> saveStoreSettlement(StoreSettlement settlement);
  Future<void> updateSettlementStatus(
      String settlementId, SettlementStatus status, String? transferReference);
  Future<void> updateStoreApproval(
      String storeId, StoreApprovalStatus status, String? reason);
  Future<void> updateAdminUser(String userId, UserRole role, bool active);
  Future<void> reviewAdminProduct(
      String productId, ProductApprovalStatus status, String? reason);
  Future<List<AdminRecord>> fetchAdminRecords(String scope);
  Future<String> saveAdminRecord(
    String scope,
    String? recordId,
    Map<String, Object?> data,
  );
  Future<Map<String, num>> fetchAdminMetrics();
}
