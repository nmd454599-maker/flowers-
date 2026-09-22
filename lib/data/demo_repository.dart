import 'dart:convert';
import 'dart:typed_data';

import 'app_repository.dart';
import 'mock_data.dart' as mock;
import '../models/models.dart';

class DemoRepository implements AppRepository {
  @override
  Future<void> requestAccountDeletion() async {
    throw StateError('حذف الحساب متاح في النسخة المتصلة بالخدمة فقط');
  }

  final List<Product> _merchantProducts = [];
  final List<AdminOrderRecord> _adminOrders = [];
  final List<AppOrder> _orders = [];
  final Map<String, ProductApprovalStatus> _productStatuses = {};
  final Map<String, String?> _productRejectionReasons = {};
  final List<AdminAuditRecord> _auditLogs = [];
  final List<StoreSettlement> _settlements = [];
  final List<PaymentTransaction> _payments = [];
  final List<RefundRequest> _refunds = [];
  final Map<String, List<AdminRecord>> _adminRecords = {};
  final List<AdminStoreRecord> _adminStores = [
    const AdminStoreRecord(
      id: 's1',
      name: 'ورود الجوري',
      city: 'بغداد',
      ownerName: 'علي حسن',
      ownerPhone: '07701234567',
      status: StoreApprovalStatus.approved,
      documentsComplete: true,
    ),
    const AdminStoreRecord(
      id: 'pending-1',
      name: 'زهور المنصور',
      city: 'بغداد',
      ownerName: 'مريم سعد',
      ownerPhone: '07811234567',
      status: StoreApprovalStatus.pending,
      documentsComplete: true,
    ),
  ];

  final List<AdminUserRecord> _adminUsers = [
    const AdminUserRecord(
        id: 'customer-1',
        name: 'عميل أزهارنا',
        phone: '07701234567',
        role: UserRole.customer,
        active: true),
    const AdminUserRecord(
        id: 'store-1',
        name: 'متجر أزهارنا',
        phone: '07811234567',
        role: UserRole.store,
        active: true),
    const AdminUserRecord(
        id: 'admin-1',
        name: 'سوبر أدمن أزهارنا',
        phone: '07501234567',
        role: UserRole.superAdmin,
        active: true),
  ];
  @override
  bool get isDemo => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> fetchStoreProfilePhoto(String storeId) async {
    final records = await fetchAdminRecords('store_profile_photos');
    for (final record in records) {
      if (record.id == storeId) return record.data['photoUrl'] as String?;
    }
    return null;
  }

  @override
  Future<String> saveStoreProfilePhoto(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    if (storeId.isEmpty || bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
      throw StateError('اختر صورة أصغر من 5 ميغابايت لمتجرك');
    }
    final url = await saveProductImage(
        storeId: storeId, bytes: bytes, fileName: fileName);
    await saveAdminRecord('store_profile_photos', storeId, {'photoUrl': url});
    return url;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<AuthChallenge> requestOtp(String phone) async {
    return const AuthChallenge('demo');
  }

  @override
  Future<AppUser> verifyOtp({
    required AuthChallenge challenge,
    required String code,
    required String phone,
    required UserRole role,
  }) async {
    if (role == UserRole.courier) {
      throw StateError('يرجى استخدام تطبيق المندوب');
    }
    if (code != '1234') throw const FormatException('رمز التحقق غير صحيح');
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final effectiveRole = digits.endsWith('7501234567')
        ? UserRole.superAdmin
        : digits.endsWith('7811234567')
            ? UserRole.store
            : role;
    final isCustomer = effectiveRole == UserRole.customer;
    final isAdmin = effectiveRole == UserRole.superAdmin;
    return AppUser(
      id: isCustomer ? 'customer-1' : (isAdmin ? 'admin-1' : 'store-1'),
      name: isCustomer
          ? 'عميل أزهارنا'
          : (isAdmin ? 'سوبر أدمن أزهارنا' : 'متجر أزهارنا'),
      phone: phone,
      role: effectiveRole,
      storeId: effectiveRole == UserRole.store ? 's1' : null,
    );
  }

  @override
  Future<List<Store>> fetchStores(String city) async {
    return mock.stores.where((store) => store.city == city).toList();
  }

  @override
  Future<List<Product>> fetchProducts() async =>
      [...mock.products, ..._merchantProducts];

  @override
  Future<Product> saveProduct(Product product) async {
    final index = _merchantProducts.indexWhere((item) => item.id == product.id);
    if (index < 0) {
      _merchantProducts.add(product);
    } else {
      _merchantProducts[index] = product;
    }
    _productStatuses.putIfAbsent(
        product.id, () => ProductApprovalStatus.pending);
    return product;
  }

  @override
  Future<String> submitStoreApplication(Map<String, Object?> data) async {
    final id = 'application_${data['ownerId'] ?? 'store-1'}';
    return saveAdminRecord('store_applications', id, {
      ...data,
      'status': 'pending',
      'submittedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<AdminRecord>> fetchApprovedStoreApplications() async =>
      List.unmodifiable(
        (await fetchAdminRecords('store_applications'))
            .where((record) => record.data['status'] == 'approved'),
      );

  @override
  Future<String> saveProductImage(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    final extension = fileName.toLowerCase().split('.').last;
    final mime = extension == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  @override
  Future<String> createOrder(AppOrder order) async {
    _adminOrders.insert(
        0,
        AdminOrderRecord(
          id: order.id,
          customerId: 'customer-1',
          storeIds:
              order.items.map((item) => item.product.storeId).toSet().toList(),
          itemCount: order.items.fold(0, (sum, item) => sum + item.qty),
          total: order.total,
          address: order.address,
          status: order.status,
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          createdAt: DateTime.now(),
        ));
    _orders.insert(0, order);
    _payments.insert(
        0,
        PaymentTransaction(
          id: 'payment_${DateTime.now().microsecondsSinceEpoch}',
          orderId: order.id,
          customerId: 'customer-1',
          amount: order.total,
          method: order.paymentMethod,
          status: order.paymentStatus,
          provider:
              order.paymentMethod == PaymentMethod.cash ? 'cash' : 'QiCard',
          createdAt: DateTime.now(),
        ));
    return order.id;
  }

  @override
  Future<List<AppOrder>> fetchOrders(
      {String? customerId, String? storeId}) async {
    if (storeId == null) return List.unmodifiable(_orders);
    return _orders
        .where((order) =>
            order.items.any((item) => item.product.storeId == storeId))
        .toList(growable: false);
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final sharedOrder =
        _orders.where((order) => order.id == orderId).firstOrNull;
    if (sharedOrder != null) sharedOrder.status = status;
    final index = _adminOrders.indexWhere((order) => order.id == orderId);
    if (index >= 0) {
      final order = _adminOrders[index];
      _adminOrders[index] = AdminOrderRecord(
        id: order.id,
        customerId: order.customerId,
        storeIds: order.storeIds,
        itemCount: order.itemCount,
        total: order.total,
        address: order.address,
        status: status,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        createdAt: order.createdAt,
      );
      _audit('order.status', orderId, {'status': status.name});
    }
  }

  @override
  Future<List<AdminStoreRecord>> fetchAdminStores() async =>
      List.unmodifiable(_adminStores);

  @override
  Future<List<AdminUserRecord>> fetchAdminUsers() async =>
      List.unmodifiable(_adminUsers);

  @override
  Future<List<AdminProductRecord>> fetchAdminProducts() async {
    final products = [...mock.products, ..._merchantProducts];
    return products.map((product) {
      final stockMatch =
          RegExp(r'المخزون:\s*(\d+)').firstMatch(product.description);
      return AdminProductRecord(
        id: product.id,
        storeId: product.storeId,
        name: product.name,
        category: product.category,
        price: product.price,
        stock: int.tryParse(stockMatch?.group(1) ?? '') ?? 0,
        imageUrl: product.imageUrl,
        active:
            (_productStatuses[product.id] ?? ProductApprovalStatus.approved) ==
                ProductApprovalStatus.approved,
        status: _productStatuses[product.id] ?? ProductApprovalStatus.approved,
        rejectionReason: _productRejectionReasons[product.id],
      );
    }).toList();
  }

  @override
  Future<List<AdminOrderRecord>> fetchAdminOrders() async =>
      List.unmodifiable(_adminOrders);

  @override
  Future<List<AdminAuditRecord>> fetchAdminAuditLogs() async =>
      List.unmodifiable(_auditLogs);

  @override
  Future<List<StoreSettlement>> fetchStoreSettlements() async =>
      List.unmodifiable(_settlements);

  @override
  Future<List<PaymentTransaction>> fetchPaymentTransactions() async =>
      List.unmodifiable(_payments);

  @override
  Future<List<RefundRequest>> fetchRefundRequests() async =>
      List.unmodifiable(_refunds);

  @override
  Future<String> createRefundRequest(RefundRequest refund) async {
    final id = refund.id.isEmpty
        ? 'refund_${DateTime.now().microsecondsSinceEpoch}'
        : refund.id;
    _refunds.insert(
        0,
        RefundRequest(
          id: id,
          orderId: refund.orderId,
          customerId: refund.customerId,
          amount: refund.amount,
          reason: refund.reason,
          liability: refund.liability,
          status: RefundStatus.requested,
          createdAt: DateTime.now(),
        ));
    _audit('refund.create', id,
        {'orderId': refund.orderId, 'amount': refund.amount});
    return id;
  }

  @override
  Future<void> updateRefundStatus(
      String refundId, RefundStatus status, String? note) async {
    final index = _refunds.indexWhere((item) => item.id == refundId);
    if (index < 0) throw StateError('طلب الاسترداد غير موجود');
    _refunds[index] = _refunds[index].copyWith(
      status: status,
      note: note,
      completedAt: status == RefundStatus.completed ? DateTime.now() : null,
    );
    _audit('refund.status', refundId, {'status': status.name});
  }

  @override
  Future<String> saveStoreSettlement(StoreSettlement settlement) async {
    final id = settlement.id.isEmpty
        ? 'settlement_${DateTime.now().microsecondsSinceEpoch}'
        : settlement.id;
    final saved = settlement.copyWith(id: id);
    final index = _settlements.indexWhere((item) => item.id == id);
    if (index < 0) {
      _settlements.insert(0, saved);
    } else {
      _settlements[index] = saved;
    }
    _audit('settlement.create', id,
        {'storeId': settlement.storeId, 'netAmount': settlement.netAmount});
    return id;
  }

  @override
  Future<void> updateSettlementStatus(String settlementId,
      SettlementStatus status, String? transferReference) async {
    final index = _settlements.indexWhere((item) => item.id == settlementId);
    if (index < 0) throw StateError('التسوية غير موجودة');
    _settlements[index] = _settlements[index].copyWith(
      status: status,
      transferReference: transferReference,
      paidAt: status == SettlementStatus.paid ? DateTime.now() : null,
    );
    _audit('settlement.status', settlementId, {
      'status': status.name,
      if (transferReference != null) 'transferReference': transferReference,
    });
  }

  @override
  Future<void> updateStoreApproval(
      String storeId, StoreApprovalStatus status, String? reason) async {
    final index = _adminStores.indexWhere((item) => item.id == storeId);
    if (index < 0) throw StateError('المتجر غير موجود');
    final item = _adminStores[index];
    _adminStores[index] = AdminStoreRecord(
      id: item.id,
      name: item.name,
      city: item.city,
      ownerName: item.ownerName,
      ownerPhone: item.ownerPhone,
      status: status,
      documentsComplete: item.documentsComplete,
      createdAt: item.createdAt,
    );
    _audit('store.approval', storeId,
        {'status': status.name, if (reason != null) 'reason': reason});
  }

  @override
  Future<void> updateAdminUser(
      String userId, UserRole role, bool active) async {
    final index = _adminUsers.indexWhere((item) => item.id == userId);
    if (index < 0) throw StateError('المستخدم غير موجود');
    final item = _adminUsers[index];
    _adminUsers[index] = AdminUserRecord(
      id: item.id,
      name: item.name,
      phone: item.phone,
      role: role,
      active: active,
      createdAt: item.createdAt,
    );
    _audit('user.update', userId, {'role': role.name, 'active': active});
  }

  @override
  Future<void> reviewAdminProduct(
      String productId, ProductApprovalStatus status, String? reason) async {
    _productStatuses[productId] = status;
    _productRejectionReasons[productId] = reason;
    _audit('product.review', productId,
        {'status': status.name, if (reason != null) 'reason': reason});
  }

  void _audit(String action, String targetId, Map<String, Object?> details) {
    _auditLogs.insert(
      0,
      AdminAuditRecord(
        id: 'audit_${DateTime.now().microsecondsSinceEpoch}',
        actorId: 'admin-1',
        action: action,
        targetId: targetId,
        details: details,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AdminRecord>> fetchAdminRecords(String scope) async =>
      List.unmodifiable(_adminRecords[scope] ?? const <AdminRecord>[]);

  @override
  Future<String> saveAdminRecord(
      String scope, String? recordId, Map<String, Object?> data) async {
    final records = _adminRecords.putIfAbsent(scope, () => []);
    final id = recordId ?? '${scope}_${DateTime.now().microsecondsSinceEpoch}';
    final index = records.indexWhere((record) => record.id == id);
    final record = AdminRecord(id: id, scope: scope, data: Map.of(data));
    if (index < 0) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    return id;
  }

  @override
  Future<Map<String, num>> fetchAdminMetrics() async => {
        'users': _adminUsers.length,
        'stores': _adminStores.length,
        'orders': 18,
        'grossSales': 8410000,
        'averageOrder': 53000,
        'cancellationRate': 3.2,
      };
}
