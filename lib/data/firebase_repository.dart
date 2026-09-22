import 'firebase/firestore_schema.dart';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/models.dart';
import 'app_repository.dart';

class FirebaseRepository implements AppRepository {
  FirebaseRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth,
        _firestore = firestore;

  String? _pendingCheckoutKey;
  String? _pendingCheckoutId;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  @override
  bool get isDemo => false;

  @override
  Future<void> signOut() async {
    await auth.signOut();
    _pendingCheckoutId = null;
    _pendingCheckoutKey = null;
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
  }

  @override
  Future<void> requestAccountDeletion() async {
    try {
      await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('requestAccountDeletion')
          .call<void>();
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'failed-precondition') {
        throw StateError('لديك رصيد في المحفظة. تواصل مع الدعم لتسويته قبل حذف الحساب');
      }
      if (error.code == 'unauthenticated') {
        throw StateError(
            'سجّل الخروج ثم ادخل برمز هاتف جديد لتأكيد هويتك قبل الحذف');
      }
      throw StateError('تعذر إرسال طلب الحذف. تحقق من الاتصال وحاول مجددًا');
    }
  }

  @override
  Future<AuthChallenge> requestOtp(String phone) {
    final completer = Completer<AuthChallenge>();
    auth.verifyPhoneNumber(
      phoneNumber: _normalizeIraqiPhone(phone),
      verificationCompleted: (credential) async {
        await auth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete(const AuthChallenge('auto-verified'));
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            AuthChallenge(verificationId, resendToken: resendToken),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(AuthChallenge(verificationId));
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 60));
  }

  @override
  Future<AppUser> verifyOtp({
    required AuthChallenge challenge,
    required String code,
    required String phone,
    required UserRole role,
  }) async {
    User? firebaseUser = auth.currentUser;
    if (challenge.verificationId != 'auto-verified') {
      final credential = PhoneAuthProvider.credential(
        verificationId: challenge.verificationId,
        smsCode: code,
      );
      firebaseUser = (await auth.signInWithCredential(credential)).user;
    }
    if (firebaseUser == null) throw StateError('تعذر تسجيل الدخول');

    final ref =
        firestore.collection(FirestoreCollections.users).doc(firebaseUser.uid);
    final snapshot = await ref.get();
    final data = snapshot.data();
    final savedRole = _roleFromValue(data?['role'] as String?);
    if (snapshot.exists && savedRole == null) {
      await auth.signOut();
      throw StateError('نوع الحساب غير معروف. تواصل مع الإدارة');
    }
    if (savedRole == UserRole.courier || role == UserRole.courier) {
      await auth.signOut();
      throw StateError('يرجى استخدام تطبيق المندوب لهذا الحساب');
    }
    final token = await firebaseUser.getIdTokenResult(true);
    if (savedRole == UserRole.superAdmin &&
        (!['admin', 'superAdmin'].contains(token.claims?['role']) ||
            (token.claims?['firebase'] as Map?)?['sign_in_second_factor'] ==
                null)) {
      await auth.signOut();
      throw StateError('لم تُمنح صلاحيات الإدارة من خادم Firebase');
    }
    if (data?['active'] == false) {
      await auth.signOut();
      throw StateError('هذا الحساب موقوف. تواصل مع الدعم');
    }
    if (role == UserRole.superAdmin && savedRole != UserRole.superAdmin) {
      await auth.signOut();
      throw StateError('هذا الحساب غير مخول للدخول إلى لوحة الإدارة');
    }
    final effectiveRole =
        savedRole ?? (role == UserRole.superAdmin ? UserRole.customer : role);
    final user = AppUser(
      id: firebaseUser.uid,
      name: (data?['name'] as String?) ??
          (role == UserRole.customer
              ? 'عميل أزهارنا'
              : role == UserRole.superAdmin
                  ? 'سوبر أدمن أزهارنا'
                  : 'متجر أزهارنا'),
      phone: firebaseUser.phoneNumber ?? phone,
      role: effectiveRole,
      storeId: data?['storeId'] as String?,
    );
    await ref.set({
      'name': user.name,
      'phone': user.phone,
      if (!snapshot.exists) 'role': user.role.name,
      'active': data?['active'] as bool? ?? true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _configureMessaging(user.role, ref);
    return user;
  }

  @override
  Future<List<Store>> fetchStores(String city) async {
    final snapshot = await firestore
        .collection(FirestoreCollections.stores)
        .where('active', isEqualTo: true)
        .where('city', isEqualTo: city)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Store(
        id: doc.id,
        name: data['name'] as String? ?? '',
        city: data['city'] as String? ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        emoji: data['emoji'] as String? ?? '🌷',
        minOrder: (data['minOrder'] as num?)?.toInt() ?? 0,
        deliveryMinutes: (data['deliveryMinutes'] as num?)?.toInt() ?? 60,
      );
    }).toList();
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final snapshot = await firestore
        .collection(FirestoreCollections.products)
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product(
        id: doc.id,
        storeId: data['storeId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? '',
        price: (data['price'] as num?)?.toInt() ?? 0,
        emoji: data['emoji'] as String? ?? '💐',
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        description: data['description'] as String? ?? '',
        imageUrl: data['imageUrl'] as String?,
        imageUrls: (data['imageUrls'] as List?)?.whereType<String>().toList() ??
            const [],
      );
    }).toList();
  }

  @override
  Future<String?> fetchStoreProfilePhoto(String storeId) async {
    final doc = await firestore
        .collection(FirestoreCollections.stores)
        .doc(storeId)
        .get();
    return doc.data()?['photoUrl'] as String?;
  }

  @override
  Future<String> saveStoreProfilePhoto(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    if (storeId.isEmpty || bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
      throw StateError('اختر صورة أصغر من 5 ميغابايت لمتجرك');
    }
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('سجل الدخول إلى حساب المتجر أولاً');
    final user =
        await firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (user.data()?['role'] != 'store' ||
        user.data()?['active'] != true ||
        user.data()?['storeId'] != storeId) {
      throw StateError('لا يمكنك تعديل صورة هذا المتجر');
    }
    final url = await saveProductImage(
        storeId: storeId, bytes: bytes, fileName: fileName);
    await firestore
        .collection(FirestoreCollections.stores)
        .doc(storeId)
        .update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  @override
  Future<Product> saveProduct(Product product) async {
    final ref = product.id.isEmpty
        ? firestore.collection(FirestoreCollections.products).doc()
        : firestore.collection(FirestoreCollections.products).doc(product.id);
    final stockMatch =
        RegExp(r'المخزون:\s*(\d+)').firstMatch(product.description);
    await ref.set({
      'storeId': product.storeId,
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'emoji': product.emoji,
      'rating': product.rating,
      'description': product.description,
      'imageUrl': product.imageUrl,
      'imageUrls': product.photos,
      'stock': int.tryParse(stockMatch?.group(1) ?? '') ?? 0,
      'approvalStatus': ProductApprovalStatus.pending.name,
      'active': false,
      'updatedAt': FieldValue.serverTimestamp()
    }, SetOptions(merge: true));
    return Product(
        id: ref.id,
        storeId: product.storeId,
        name: product.name,
        category: product.category,
        price: product.price,
        emoji: product.emoji,
        rating: product.rating,
        description: product.description,
        imageUrl: product.imageUrl,
        imageUrls: product.photos);
  }

  @override
  Future<String> submitStoreApplication(Map<String, Object?> data) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('يجب تسجيل الدخول قبل إرسال طلب المتجر');
    }
    final ref = firestore
        .collection(FirestoreCollections.adminData)
        .doc('store_applications')
        .collection(FirestoreCollections.records)
        .doc(uid);
    await ref.set({
      ...data,
      'ownerId': uid,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<List<AdminRecord>> fetchApprovedStoreApplications() async {
    final snapshot = await firestore
        .collection(FirestoreCollections.adminData)
        .doc('store_applications')
        .collection(FirestoreCollections.records)
        .where('status', isEqualTo: 'approved')
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => AdminRecord(
              id: doc.id,
              scope: 'store_applications',
              data: Map<String, Object?>.from(doc.data()),
            ))
        .toList();
  }

  @override
  Future<String> saveProductImage(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    final extension = fileName.toLowerCase().split('.').last;
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final safeName = '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final ref = FirebaseStorage.instance.ref('products/$storeId/$safeName');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  @override
  Future<String> createOrder(AppOrder order) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('يجب تسجيل الدخول قبل إنشاء الطلب');
    if (order.paymentMethod != PaymentMethod.cash) {
      throw StateError('الدفع الإلكتروني غير متاح حتى اكتمال ربط مزوّد الدفع');
    }
    final checkoutKey = jsonEncode([
      uid,
      order.address,
      order.total,
      order.walletUsed,
      order.couponId,
      order.items.map((item) => [item.product.id, item.qty]).toList()
    ]);
    if (_pendingCheckoutKey != checkoutKey) {
      _pendingCheckoutKey = checkoutKey;
      _pendingCheckoutId =
          firestore.collection(FirestoreCollections.orders).doc().id;
    }
    final result = await FirebaseFunctions.instanceFor(region: 'me-central1')
        .httpsCallable('createCashOrder')
        .call(<String, dynamic>{
      'requestId': _pendingCheckoutId,
      'expectedTotal': order.total,
      'walletAmount': order.walletUsed,
      'couponId': order.couponId,
      'address': order.address,
      'items': order.items
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.qty,
              })
          .toList(),
    });
    _pendingCheckoutKey = null;
    _pendingCheckoutId = null;
    return (result.data as Map)['orderId'] as String;
  }

  @override
  Future<List<AppOrder>> fetchOrders(
      {String? customerId, String? storeId}) async {
    Query<Map<String, dynamic>> query =
        firestore.collection(FirestoreCollections.orders);
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    } else if (storeId != null) {
      query = query.where('storeIds', arrayContains: storeId);
    } else {
      return const [];
    }
    final snapshot = await query.limit(200).get();
    final result = snapshot.docs.map((doc) {
      final data = doc.data();
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      final items = rawItems.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return OrderItem(
          Product(
            id: item['productId'] as String? ?? '',
            storeId: item['storeId'] as String? ?? '',
            name: item['name'] as String? ?? '',
            category: item['category'] as String? ?? '',
            price: (item['unitPrice'] as num?)?.toInt() ?? 0,
            emoji: item['emoji'] as String? ?? '💐',
            rating: 0,
            description: '',
            imageUrl: item['imageUrl'] as String?,
          ),
          (item['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();
      return AppOrder(
        id: doc.id,
        couponId: data['couponId'] as String?,
        discount: (data['discount'] as num?)?.toInt() ?? 0,
        walletUsed: (data['walletUsed'] as num?)?.toInt() ?? 0,
        items: items,
        deliveryFee: (data['deliveryFee'] as num?)?.toInt() ?? 0,
        address: data['address'] as String? ?? '',
        status: _orderStatus(data['status'] as String?),
        paymentMethod: _paymentMethod(data['paymentMethod'] as String?),
        paymentStatus: _paymentStatus(data['paymentStatus'] as String?),
      );
    }).toList();
    result.sort((a, b) => b.id.compareTo(a.id));
    return result;
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) {
    return firestore
        .collection(FirestoreCollections.orders)
        .doc(orderId)
        .update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<AdminStoreRecord>> fetchAdminStores() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.stores)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminStoreRecord(
        id: doc.id,
        name: data['name'] as String? ?? '',
        city: data['city'] as String? ?? '',
        ownerName: data['ownerName'] as String? ?? '',
        ownerPhone: data['ownerPhone'] as String? ?? '',
        status: _storeStatus(data['approvalStatus'] as String?),
        documentsComplete: data['documentsComplete'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<AdminUserRecord>> fetchAdminUsers() async {
    _requireAdmin();
    final snapshot =
        await firestore.collection(FirestoreCollections.users).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminUserRecord(
        id: doc.id,
        name: data['name'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        role: _roleFromValue(data['role'] as String?) ??
            (throw StateError('نوع حساب غير معروف: ${doc.id}')),
        active: data['active'] as bool? ?? true,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<AdminProductRecord>> fetchAdminProducts() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.products)
        .limit(500)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminProductRecord(
        id: doc.id,
        storeId: data['storeId'] as String? ?? '',
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? '',
        price: (data['price'] as num?)?.toInt() ?? 0,
        stock: (data['stock'] as num?)?.toInt() ?? 0,
        imageUrl: data['imageUrl'] as String?,
        active: data['active'] as bool? ?? false,
        status: _productStatus(data['approvalStatus'] as String?),
        rejectionReason: data['rejectionReason'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
  }

  @override
  Future<List<AdminOrderRecord>> fetchAdminOrders() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.orders)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>? ?? const [];
      return AdminOrderRecord(
        id: doc.id,
        customerId: data['customerId'] as String? ?? '',
        storeIds: (data['storeIds'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(),
        itemCount: items.fold<int>(0, (totalItems, item) {
          if (item is! Map) return totalItems;
          return totalItems + ((item['quantity'] as num?)?.toInt() ?? 0);
        }),
        total: (data['total'] as num?)?.toInt() ?? 0,
        address: data['address'] as String? ?? '',
        status: _orderStatus(data['status'] as String?),
        paymentMethod: _paymentMethod(data['paymentMethod'] as String?),
        paymentStatus: _paymentStatus(data['paymentStatus'] as String?),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<AdminAuditRecord>> fetchAdminAuditLogs() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.auditLogs)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminAuditRecord(
        id: doc.id,
        actorId: data['actorId'] as String? ?? '',
        action: data['action'] as String? ?? '',
        targetId: data['targetId'] as String? ?? '',
        details: Map<String, Object?>.from(
            data['details'] as Map? ?? const <String, Object?>{}),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<StoreSettlement>> fetchStoreSettlements() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.settlements)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return StoreSettlement(
        id: doc.id,
        storeId: data['storeId'] as String? ?? '',
        periodStart:
            (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
        periodEnd:
            (data['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
        grossSales: (data['grossSales'] as num?)?.toInt() ?? 0,
        commission: (data['commission'] as num?)?.toInt() ?? 0,
        refunds: (data['refunds'] as num?)?.toInt() ?? 0,
        adjustments: (data['adjustments'] as num?)?.toInt() ?? 0,
        netAmount: (data['netAmount'] as num?)?.toInt() ?? 0,
        status: _settlementStatus(data['status'] as String?),
        transferReference: data['transferReference'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<PaymentTransaction>> fetchPaymentTransactions() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.paymentTransactions)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return PaymentTransaction(
        id: doc.id,
        orderId: data['orderId'] as String? ?? '',
        customerId: data['customerId'] as String? ?? '',
        amount: (data['amount'] as num?)?.toInt() ?? 0,
        method: _paymentMethod(data['method'] as String?),
        status: _paymentStatus(data['status'] as String?),
        provider: data['provider'] as String? ?? '',
        providerPaymentId: data['providerPaymentId'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<List<RefundRequest>> fetchRefundRequests() async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.refundRequests)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return RefundRequest(
        id: doc.id,
        orderId: data['orderId'] as String? ?? '',
        customerId: data['customerId'] as String? ?? '',
        amount: (data['amount'] as num?)?.toInt() ?? 0,
        reason: data['reason'] as String? ?? '',
        liability: _refundLiability(data['liability'] as String?),
        status: _refundStatus(data['status'] as String?),
        note: data['note'] as String?,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  @override
  Future<String> createRefundRequest(RefundRequest refund) async {
    final uid = _requireAdmin();
    final ref = firestore.collection(FirestoreCollections.refundRequests).doc();
    final batch = firestore.batch();
    batch.set(ref, {
      'orderId': refund.orderId,
      'customerId': refund.customerId,
      'amount': refund.amount,
      'reason': refund.reason,
      'liability': refund.liability.name,
      'status': RefundStatus.requested.name,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAudit(batch, uid, 'refund.create', ref.id,
        {'orderId': refund.orderId, 'amount': refund.amount});
    await batch.commit();
    return ref.id;
  }

  @override
  Future<void> updateRefundStatus(
      String refundId, RefundStatus status, String? note) async {
    final uid = _requireAdmin();
    final batch = firestore.batch();
    batch.update(
        firestore.collection(FirestoreCollections.refundRequests).doc(refundId),
        {
          'status': status.name,
          'note': note,
          'reviewedBy': uid,
          if (status == RefundStatus.completed)
            'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    _addAudit(batch, uid, 'refund.status', refundId, {'status': status.name});
    await batch.commit();
  }

  @override
  Future<String> saveStoreSettlement(StoreSettlement settlement) async {
    final uid = _requireAdmin();
    final ref = settlement.id.isEmpty
        ? firestore.collection(FirestoreCollections.settlements).doc()
        : firestore
            .collection(FirestoreCollections.settlements)
            .doc(settlement.id);
    final batch = firestore.batch();
    batch.set(
        ref,
        {
          'storeId': settlement.storeId,
          'periodStart': Timestamp.fromDate(settlement.periodStart),
          'periodEnd': Timestamp.fromDate(settlement.periodEnd),
          'grossSales': settlement.grossSales,
          'commission': settlement.commission,
          'refunds': settlement.refunds,
          'adjustments': settlement.adjustments,
          'netAmount': settlement.netAmount,
          'status': settlement.status.name,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    _addAudit(batch, uid, 'settlement.create', ref.id, {
      'storeId': settlement.storeId,
      'netAmount': settlement.netAmount,
    });
    await batch.commit();
    return ref.id;
  }

  @override
  Future<void> updateSettlementStatus(String settlementId,
      SettlementStatus status, String? transferReference) async {
    final uid = _requireAdmin();
    final batch = firestore.batch();
    final ref = firestore
        .collection(FirestoreCollections.settlements)
        .doc(settlementId);
    batch.update(ref, {
      'status': status.name,
      'transferReference': transferReference,
      'approvedBy': uid,
      if (status == SettlementStatus.approved)
        'approvedAt': FieldValue.serverTimestamp(),
      if (status == SettlementStatus.paid)
        'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAudit(batch, uid, 'settlement.status', settlementId, {
      'status': status.name,
      if (transferReference != null) 'transferReference': transferReference,
    });
    await batch.commit();
  }

  @override
  Future<void> updateStoreApproval(
      String storeId, StoreApprovalStatus status, String? reason) async {
    final uid = _requireAdmin();
    final batch = firestore.batch();
    final storeRef =
        firestore.collection(FirestoreCollections.stores).doc(storeId);
    batch.update(storeRef, {
      'approvalStatus': status.name,
      'active': status == StoreApprovalStatus.approved,
      'rejectionReason': reason,
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAudit(batch, uid, 'store.approval', storeId, {
      'status': status.name,
      if (reason != null) 'reason': reason,
    });
    await batch.commit();
  }

  @override
  Future<void> updateAdminUser(
      String userId, UserRole role, bool active) async {
    final uid = _requireAdmin();
    if (userId == uid && (!active || role != UserRole.superAdmin)) {
      throw StateError('لا يمكنك إيقاف حسابك أو إزالة صلاحيتك بنفسك');
    }
    final existing = await firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();
    final currentRole = _roleFromValue(existing.data()?['role'] as String?);
    if ((role == UserRole.courier || currentRole == UserRole.courier) &&
        role != currentRole) {
      throw StateError('تغيير دور المندوب يتطلب تحديث صلاحياته من الخادم');
    }
    final batch = firestore.batch();
    batch.update(firestore.collection(FirestoreCollections.users).doc(userId), {
      'role': role.name,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
    _addAudit(batch, uid, 'user.update', userId, {
      'role': role.name,
      'active': active,
    });
    await batch.commit();
  }

  @override
  Future<void> reviewAdminProduct(
      String productId, ProductApprovalStatus status, String? reason) async {
    final uid = _requireAdmin();
    final batch = firestore.batch();
    final productRef =
        firestore.collection(FirestoreCollections.products).doc(productId);
    batch.update(productRef, {
      'approvalStatus': status.name,
      'active': status == ProductApprovalStatus.approved,
      'rejectionReason': reason,
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAudit(batch, uid, 'product.review', productId, {
      'status': status.name,
      if (reason != null) 'reason': reason,
    });
    await batch.commit();
  }

  @override
  Future<List<AdminRecord>> fetchAdminRecords(String scope) async {
    _requireAdmin();
    final snapshot = await firestore
        .collection(FirestoreCollections.adminData)
        .doc(scope)
        .collection(FirestoreCollections.records)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => AdminRecord(
              id: doc.id,
              scope: scope,
              data: Map<String, Object?>.from(doc.data()),
            ))
        .toList();
  }

  @override
  Future<String> saveAdminRecord(
      String scope, String? recordId, Map<String, Object?> data) async {
    final uid = _requireAdmin();
    final collection = firestore
        .collection(FirestoreCollections.adminData)
        .doc(scope)
        .collection(FirestoreCollections.records);
    final ref = recordId == null ? collection.doc() : collection.doc(recordId);
    final batch = firestore.batch();
    batch.set(
        ref,
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
          if (recordId == null) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    _addAudit(batch, uid, 'admin.$scope.save', ref.id, data);
    await batch.commit();
    return ref.id;
  }

  @override
  Future<Map<String, num>> fetchAdminMetrics() async {
    _requireAdmin();
    final results = await Future.wait([
      firestore.collection(FirestoreCollections.users).count().get(),
      firestore.collection(FirestoreCollections.stores).count().get(),
      firestore.collection(FirestoreCollections.orders).limit(1000).get(),
    ]);
    final users = (results[0] as AggregateQuerySnapshot).count ?? 0;
    final stores = (results[1] as AggregateQuerySnapshot).count ?? 0;
    final orders = results[2] as QuerySnapshot<Map<String, dynamic>>;
    var gross = 0;
    var cancelled = 0;
    for (final doc in orders.docs) {
      final data = doc.data();
      gross += (data['total'] as num?)?.toInt() ?? 0;
      if (data['status'] == 'cancelled') cancelled++;
    }
    final count = orders.docs.length;
    return {
      'users': users,
      'stores': stores,
      'orders': count,
      'grossSales': gross,
      'averageOrder': count == 0 ? 0 : gross / count,
      'cancellationRate': count == 0 ? 0 : cancelled * 100 / count,
    };
  }

  String _requireAdmin() {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('يجب تسجيل الدخول');
    return uid;
  }

  void _addAudit(WriteBatch batch, String uid, String action, String targetId,
      Map<String, Object?> details) {
    final ref = firestore.collection(FirestoreCollections.auditLogs).doc();
    batch.set(ref, {
      'actorId': uid,
      'action': action,
      'targetId': targetId,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  StoreApprovalStatus _storeStatus(String? value) {
    for (final status in StoreApprovalStatus.values) {
      if (status.name == value) return status;
    }
    return StoreApprovalStatus.pending;
  }

  ProductApprovalStatus _productStatus(String? value) {
    for (final status in ProductApprovalStatus.values) {
      if (status.name == value) return status;
    }
    return ProductApprovalStatus.approved;
  }

  OrderStatus _orderStatus(String? value) {
    for (final status in OrderStatus.values) {
      if (status.name == value) return status;
    }
    return OrderStatus.newOrder;
  }

  SettlementStatus _settlementStatus(String? value) {
    for (final status in SettlementStatus.values) {
      if (status.name == value) return status;
    }
    return SettlementStatus.draft;
  }

  PaymentMethod _paymentMethod(String? value) =>
      PaymentMethod.values.where((item) => item.name == value).firstOrNull ??
      PaymentMethod.cash;

  PaymentStatus _paymentStatus(String? value) =>
      PaymentStatus.values.where((item) => item.name == value).firstOrNull ??
      PaymentStatus.pending;

  RefundStatus _refundStatus(String? value) =>
      RefundStatus.values.where((item) => item.name == value).firstOrNull ??
      RefundStatus.requested;

  RefundLiability _refundLiability(String? value) =>
      RefundLiability.values.where((item) => item.name == value).firstOrNull ??
      RefundLiability.platform;

  String _normalizeIraqiPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('964')) return '+$digits';
    if (digits.startsWith('0')) return '+964${digits.substring(1)}';
    return '+964$digits';
  }

  UserRole? _roleFromValue(String? value) => parseUserRole(value);

  Future<void> _configureMessaging(
      UserRole role, DocumentReference<Map<String, dynamic>> userRef) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.subscribeToTopic('all');
      if (role == UserRole.customer) {
        await messaging.subscribeToTopic('customers');
      } else if (role == UserRole.store) {
        await messaging.subscribeToTopic('stores');
      }
      final token = await messaging.getToken();
      if (token != null) {
        await userRef.set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastActiveAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Notification permission or token failures must not block sign-in.
    }
  }
}
