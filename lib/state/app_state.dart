import 'dart:async';
import 'operation_runner.dart';
import 'modules/session_state.dart';
import 'modules/order_state.dart';
import 'modules/catalog_state.dart';
import 'modules/admin_state.dart';
import '../domain/cart/shopping_cart.dart';
import 'package:flutter/foundation.dart';
import '../data/app_repository.dart';
import '../data/sqlite_repository.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  final AppRepository repository;

  late final CatalogState catalog;
  late final AdminState admin;
  late final SessionState session;
  late final OrderState orderState;
  AppState({required this.repository}) {
    catalog = CatalogState(
        repository: repository, run: _run, onChanged: notifyListeners);
    admin = AdminState(repository: repository, run: _run, catalog: catalog);
    orderState = OrderState(
        repository: repository,
        run: _run,
        cart: _shoppingCart,
        getUser: () => session.user,
        onChanged: notifyListeners);
    session = SessionState(
        repository: repository,
        run: _run,
        orders: orderState.orders,
        loadCatalog: catalog.loadForSession);
  }

  AppUser? get user => session.user;
  set user(AppUser? value) => session.user = value;
  AuthChallenge? get authChallenge => session.authChallenge;
  set authChallenge(AuthChallenge? value) => session.authChallenge = value;
  int _epoch = 0;
  int _activeOperations = 0;
  bool _signingOut = false;
  bool _disposed = false;
  final Set<Future<void>> _inFlight = {};
  bool get busy => _activeOperations > 0 || _signingOut;
  String? errorMessage;
  List<Store> get stores => catalog.stores;
  set stores(List<Store> value) => catalog.stores = value;
  List<Product> get products => catalog.products;
  set products(List<Product> value) => catalog.products = value;
  List<AdminStoreRecord> get adminStores => admin.adminStores;
  set adminStores(List<AdminStoreRecord> value) => admin.adminStores = value;
  List<AdminUserRecord> get adminUsers => admin.adminUsers;
  set adminUsers(List<AdminUserRecord> value) => admin.adminUsers = value;
  List<AdminProductRecord> get adminProducts => admin.adminProducts;
  set adminProducts(List<AdminProductRecord> value) =>
      admin.adminProducts = value;
  List<AdminOrderRecord> get adminOrders => admin.adminOrders;
  set adminOrders(List<AdminOrderRecord> value) => admin.adminOrders = value;
  List<AdminAuditRecord> get adminAuditLogs => admin.adminAuditLogs;
  set adminAuditLogs(List<AdminAuditRecord> value) =>
      admin.adminAuditLogs = value;
  List<StoreSettlement> get storeSettlements => admin.storeSettlements;
  set storeSettlements(List<StoreSettlement> value) =>
      admin.storeSettlements = value;
  List<PaymentTransaction> get paymentTransactions => admin.paymentTransactions;
  set paymentTransactions(List<PaymentTransaction> value) =>
      admin.paymentTransactions = value;
  List<RefundRequest> get refundRequests => admin.refundRequests;
  set refundRequests(List<RefundRequest> value) => admin.refundRequests = value;
  Map<String, num> get adminMetrics => admin.adminMetrics;
  set adminMetrics(Map<String, num> value) => admin.adminMetrics = value;
  Map<String, List<AdminRecord>> get adminRecords => admin.adminRecords;
  final ShoppingCart _shoppingCart = ShoppingCart();
  // Compatibility for existing screens; mutations should use the methods below.
  Map<Product, int> get cart => _shoppingCart.items;
  final Set<String> favorites = {};
  List<AppOrder> get orders => orderState.orders;
  String get selectedCity => catalog.selectedCity;
  set selectedCity(String value) => catalog.selectedCity = value;
  final List<Address> addresses = [
    const Address(
        id: 'a1',
        title: 'المنزل',
        city: 'بغداد',
        details: 'الكرادة - شارع الصناعة'),
  ];
  final List<ChatMessage> messages = [
    ChatMessage(
        id: 'm1',
        sender: 'ورود الجوري',
        text: 'أهلًا بك، كيف يمكننا مساعدتك؟',
        createdAt: DateTime.now(),
        fromMe: false),
  ];
  final List<AppNotification> notifications = [
    AppNotification(
        id: 'n1',
        title: 'مرحبًا بك في أزهارنا',
        body: 'اكتشف المتاجر والزهور والهدايا القريبة منك.',
        createdAt: DateTime.now()),
  ];

  bool get isLoggedIn => user != null;
  bool get isDemo => repository.isDemo;
  int get cartCount => _shoppingCart.count;
  int get cartSubtotal => _shoppingCart.subtotal;
  int get deliveryFee => _shoppingCart.deliveryFee;
  int get cartTotal => _shoppingCart.total;

  void updateCustomerName(String name) {
    final current = user;
    if (current == null) return;
    user = AppUser(
        id: current.id,
        name: name,
        phone: current.phone,
        role: current.role,
        storeId: current.storeId);
    notifyListeners();
  }

  void updateCustomerPhone(String phone) {
    final current = user;
    if (current == null) return;
    user = AppUser(
        id: current.id,
        name: current.name,
        phone: phone,
        role: current.role,
        storeId: current.storeId);
    notifyListeners();
  }

  Future<void> loadCatalog() => catalog.loadCatalog();
  Future<void> selectCity(String city) => catalog.selectCity(city);
  Future<void> saveStoreProduct(Product product) =>
      catalog.saveStoreProduct(product);
  Future<void> loadAdminData() => admin.loadAdminData();
  Future<void> reviewStore(AdminStoreRecord store, StoreApprovalStatus status,
          {String? reason}) =>
      admin.reviewStore(store, status, reason: reason);
  Future<void> updateManagedUser(
          AdminUserRecord user, UserRole role, bool active) =>
      admin.updateManagedUser(user, role, active);
  Future<void> reviewProduct(
          AdminProductRecord product, ProductApprovalStatus status,
          {String? reason}) =>
      admin.reviewProduct(product, status, reason: reason);
  Future<void> loadAdminScope(String scope) => admin.loadAdminScope(scope);
  Future<String> saveAdminRecord(
          String scope, String? recordId, Map<String, Object?> data) =>
      admin.saveAdminRecord(scope, recordId, data);

  Future<void> runAuthentication(
          Future<void> Function(OperationToken) operation) =>
      _run(operation);

  Future<void> requestOtp(String phone) => session.requestOtp(phone);
  Future<void> verifyOtp(String phone, String code, UserRole role) async {
    await session.verifyOtp(phone, code, role);
    if (repository is SqliteRepository && user != null) {
      final rows = await (repository as SqliteRepository)
          .db
          .query('favorites', where: 'user_id = ?', whereArgs: [user!.id]);
      favorites
        ..clear()
        ..addAll(rows.map((r) => r['product_id'] as String));
      notifyListeners();
    }
  }

  Future<void> refreshOrders() => orderState.refreshOrders();

  Future<void> logout() async {
    if (_signingOut) return;
    _signingOut = true;
    _epoch++;
    _activeOperations = 0;
    authChallenge = null;
    errorMessage = null;
    favorites.clear();
    addresses.clear();
    _shoppingCart.clear();
    orders.clear();
    messages.clear();
    notifications.clear();
    admin.clear();
    user = null;

    catalog.products = [];
    catalog.stores = [];
    notifyListeners();
    try {
      // Drain authentication work first, so late sign-in cannot restore Auth.
      await Future.wait(_inFlight.toList());
      await session.signOut();
    } finally {
      _signingOut = false;
      if (!_disposed) notifyListeners();
    }
  }

  void addToCart(Product product) {
    _shoppingCart.add(product);
    notifyListeners();
  }

  void decrement(Product product) {
    _shoppingCart.decrement(product);
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _shoppingCart.remove(product);
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    final selected = favorites.contains(product.id);
    final repo = repository;
    if (repo is SqliteRepository && user != null) {
      try {
        if (selected) {
          await repo.db.delete('favorites',
              where: 'user_id = ? AND product_id = ?',
              whereArgs: [user!.id, product.id]);
        } else {
          await repo.db.rawInsert(
              'INSERT OR IGNORE INTO favorites(user_id, product_id) VALUES (?, ?)',
              [user!.id, product.id]);
        }
      } catch (_) {
        errorMessage = 'تعذر حفظ المفضلة';
        notifyListeners();
        return;
      }
    }
    if (favorites.contains(product.id)) {
      favorites.remove(product.id);
    } else {
      favorites.add(product.id);
    }
    notifyListeners();
  }

  Future<AppOrder> checkout(String address,
          {PaymentMethod paymentMethod = PaymentMethod.cash,
          String? couponId,
          int discount = 0,
          int walletUsed = 0}) =>
      orderState.checkout(address,
          paymentMethod: paymentMethod,
          couponId: couponId,
          discount: discount,
          walletUsed: walletUsed);

  void addAddress(String title, String city, String details) {
    addresses.add(Address(
      id: 'a${addresses.length + 1}',
      title: title,
      city: city,
      details: details,
    ));
    notifyListeners();
  }

  void sendMessage(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    messages.add(ChatMessage(
      id: 'm${messages.length + 1}',
      sender: user?.name ?? 'أنا',
      text: value,
      createdAt: DateTime.now(),
      fromMe: true,
    ));
    notifyListeners();
  }

  void markNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  Future<void> updateOrderStatus(AppOrder order, OrderStatus status) =>
      orderState.updateOrderStatus(order, status);

  Future<void> updateAdminOrderStatus(
          AdminOrderRecord order, OrderStatus status) =>
      admin.updateAdminOrderStatus(order, status);
  Future<void> createSettlement(StoreSettlement settlement) =>
      admin.createSettlement(settlement);
  Future<void> updateSettlement(
          StoreSettlement settlement, SettlementStatus status,
          {String? transferReference}) =>
      admin.updateSettlement(settlement, status,
          transferReference: transferReference);
  Future<void> createRefund(RefundRequest refund) => admin.createRefund(refund);
  Future<void> updateRefund(RefundRequest refund, RefundStatus status,
          {String? note}) =>
      admin.updateRefund(refund, status, note: note);

  Future<void> _run(Future<void> Function(OperationToken) operation) async {
    if (_signingOut || _disposed) throw const StaleOperation();
    final epoch = _epoch;
    final token = OperationToken(() => !_disposed && epoch == _epoch);
    final finished = Completer<void>();
    _inFlight.add(finished.future);
    _activeOperations++;
    errorMessage = null;
    notifyListeners();
    try {
      token.check();
      await operation(token);
      token.check();
    } catch (error) {
      if (token.isCurrent) errorMessage = _friendlyError(error);
      rethrow;
    } finally {
      _inFlight.remove(finished.future);
      finished.complete();
      if (token.isCurrent) {
        _activeOperations--;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('BILLING_NOT_ENABLED')) {
      return 'هذا الرقم غير مضاف إلى أرقام الاختبار في Firebase. أضفه أولًا أو فعّل الفوترة لإرسال رسالة حقيقية.';
    }
    if (message.contains('invalid-verification-code')) {
      return 'رمز التحقق غير صحيح. تأكد من الأرقام وحاول مجددًا.';
    }
    if (message.contains('too-many-requests')) {
      return 'تم إجراء محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.';
    }
    if (message.contains('network-request-failed')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من الشبكة وحاول مجددًا.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
