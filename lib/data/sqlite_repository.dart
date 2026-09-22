import '../domain/accounts/reward_account.dart';
import '../domain/accounts/account_identity.dart';
import 'local/database_schema.dart';
import 'local/local_admin_repository.dart';
import '../domain/orders/order_transitions.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../services/local_product_images.dart';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'demo_repository.dart';
import 'mock_data.dart' as seed;

/// قاعدة البيانات المحلية للتطبيق. تورّث عمليات لوحة الإدارة التجريبية، بينما
/// تحفظ بيانات تجربة العميل الأساسية في SQLite على الهاتف.
class SqliteRepository extends DemoRepository with LocalAdminRepository {
  Database? _database;
  AppUser? _signedInUser;
  @override
  AppUser? get signedInUser => _signedInUser;

  Future<void> changeLocalPhone(String phone, String code) async {
    final actor = _signedInUser;
    if (actor == null || code != '123456')
      throw StateError('رمز الفحص غير صحيح');
    final normalized = accountPhone(phone);
    if (!RegExp(r'^\+9647[0-9]{9}$').hasMatch(normalized))
      throw StateError('رقم غير صالح');
    final users = await db.query('users');
    if (users.any((u) =>
        u['id'] != actor.id &&
        accountPhone(u['phone'] as String) == normalized))
      throw StateError('الرقم مستخدم');
    await db.update('users', {'phone': normalized},
        where: 'id = ?', whereArgs: [actor.id]);
    _signedInUser = AppUser(
        id: actor.id,
        name: actor.name,
        phone: normalized,
        role: actor.role,
        storeId: actor.storeId);
  }

  Future<void> reviewJoinRequest(String id, bool approve) async {
    requireLocalAdmin();
    final data = await recordData('customer_requests', id);
    if (data.isEmpty || !['store', 'courier'].contains(data['kind']))
      throw StateError('طلب انضمام غير موجود');
    if (data['status'] == 'approved' || data['status'] == 'rejected')
      throw StateError('تمت مراجعة الطلب مسبقًا');
    final ownerId = data['ownerId'] as String;
    final fields = Map<String, Object?>.from(data['fields'] as Map);
    await db.transaction((txn) async {
      if (approve) {
        final storeId = 'store_$ownerId';
        if (data['kind'] == 'store') {
          await txn.insert(
              'stores',
              {
                'id': storeId,
                'name': fields['storeName'] ?? data['name'],
                'city': fields['city'] ?? 'بغداد',
                'rating': 0,
                'emoji': '🌷',
                'min_order': 0,
                'delivery_minutes': 60
              },
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await txn.update(
            'users',
            {
              'role': data['kind'],
              'account_type': data['kind'],
              if (data['kind'] == 'store') 'store_id': storeId
            },
            where: 'id = ?',
            whereArgs: [ownerId]);
      }
      final updated = {
        ...data,
        'status': approve ? 'approved' : 'rejected',
        'reply': approve
            ? 'تم قبول طلب الانضمام. سجّل الدخول مجددًا لتحديث الصلاحيات.'
            : 'لم تتم الموافقة على طلب الانضمام.'
      };
      await txn.update(
          'local_records',
          {
            'payload': jsonEncode(updated),
            'updated_at': DateTime.now().toIso8601String()
          },
          where: 'id = ? AND scope = ?',
          whereArgs: [id, 'customer_requests']);
    });
    await localAudit(
        'join.review', ownerId, {'approved': approve, 'requestId': id});
  }

  @override
  Future<void> requestAccountDeletion() async {
    final actor = _signedInUser;
    if (actor == null) throw StateError('سجّل الدخول أولًا');
    await saveAdminRecord('customer_requests', 'delete_${actor.id}', {
      'ownerId': actor.id,
      'name': actor.name,
      'phone': actor.phone,
      'kind': 'support',
      'fields': {
        'subject': 'طلب حذف الحساب',
        'details': 'مراجعة الطلبات المفتوحة قبل تنفيذ الحذف'
      },
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Database get db {
    final value = _database;
    if (value == null) throw StateError('قاعدة البيانات غير مهيأة');
    return value;
  }

  @override
  bool get isDemo => true;

  @override
  Future<void> signOut() async {
    await super.signOut();
    _signedInUser = null;
  }

  @override
  Future<List<AdminUserRecord>> fetchAdminUsers() async {
    final rows = await db.query('users', orderBy: 'created_at DESC');
    return rows
        .map((row) => AdminUserRecord(
              id: row['id'] as String,
              name: row['name'] as String,
              phone: row['phone'] as String,
              role: parseUserRole(row['role'] as String?) ??
                  (throw StateError('نوع حساب غير معروف')),
              active: row['active'] == 1,
              createdAt: DateTime.tryParse(row['created_at'] as String),
            ))
        .toList();
  }

  @override
  Future<void> updateAdminUser(
      String userId, UserRole role, bool active) async {
    final actor = _signedInUser;
    if (actor?.role != UserRole.superAdmin) {
      throw StateError('صلاحية الإدارة مطلوبة');
    }
    if (userId == actor!.id && (!active || role != UserRole.superAdmin)) {
      throw StateError('لا يمكنك إيقاف حسابك أو إزالة صلاحيتك بنفسك');
    }
    await db.transaction((txn) async {
      final rows =
          await txn.query('users', where: 'id = ?', whereArgs: [userId]);
      if (rows.isEmpty) throw StateError('المستخدم غير موجود');
      String? storeId = rows.single['store_id'] as String?;
      if (role == UserRole.store && storeId == null) {
        storeId = 'store_$userId';
        await txn.insert(
            'stores',
            {
              'id': storeId,
              'name': 'متجر ${rows.single['name']}',
              'city': 'بغداد',
              'rating': 0,
              'emoji': '🌷',
              'min_order': 0,
              'delivery_minutes': 60
            },
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await txn.update(
          'users',
          {
            'role': role.name,
            'account_type': role.name,
            'store_id': storeId,
            'active': active ? 1 : 0
          },
          where: 'id = ?',
          whereArgs: [userId]);
      final now = DateTime.now();
      await txn.insert('local_records', {
        'id': 'account_audit_${now.microsecondsSinceEpoch}',
        'scope': 'account_audit',
        'payload': jsonEncode({
          'actorId': actor.id,
          'targetId': userId,
          'action': 'user.update',
          'role': role.name,
          'active': active
        }),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    });
  }

  @override
  Future<List<AdminAuditRecord>> fetchAdminAuditLogs() async {
    final rows = await db.query('local_records',
        where: 'scope = ?',
        whereArgs: ['account_audit'],
        orderBy: 'created_at DESC');
    return [
      ...rows.map((row) {
        final data = Map<String, Object?>.from(
            jsonDecode(row['payload'] as String) as Map);
        return AdminAuditRecord(
            id: row['id'] as String,
            actorId: data['actorId'] as String,
            action: data['action'] as String,
            targetId: data['targetId'] as String,
            details: data,
            createdAt: DateTime.tryParse(row['created_at'] as String));
      }),
      ...await super.fetchAdminAuditLogs(),
    ];
  }

  @override
  Future<void> initialize() async {
    final root = await getDatabasesPath();
    _database = await openDatabase(
      p.join(root, 'azharna.db'),
      version: DatabaseSchema.version,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await DatabaseSchema.create(database);
        await _seed(database);
      },
      onUpgrade: DatabaseSchema.upgrade,
    );
  }

  @override
  Future<List<AdminRecord>> fetchAdminRecords(String scope) async {
    final rows = await db.query('local_records',
        where: 'scope = ?', whereArgs: [scope], orderBy: 'updated_at DESC');
    return rows
        .map((row) => AdminRecord(
              id: row['id'] as String,
              scope: scope,
              data: Map<String, Object?>.from(
                  jsonDecode(row['payload'] as String) as Map),
            ))
        .toList();
  }

  @override
  Future<String> saveAdminRecord(
      String scope, String? recordId, Map<String, Object?> data) async {
    if (scope == 'store_applications' &&
        ['approved', 'rejected'].contains(data['status'])) {
      requireLocalAdmin();
      if (data['status'] == 'approved') {
        final ownerId = data['ownerId'] as String;
        await db.transaction((txn) async {
          final owners =
              await txn.query('users', where: 'id = ?', whereArgs: [ownerId]);
          if (owners.isEmpty) throw StateError('حساب المتجر غير موجود');
          final storeId =
              owners.single['store_id'] as String? ?? 'store_$ownerId';
          final stores =
              await txn.query('stores', where: 'id = ?', whereArgs: [storeId]);
          final values = <String, Object?>{
            'name': data['name'],
            'city': data['city'] ?? 'بغداد',
            'latitude': data['latitude'],
            'longitude': data['longitude']
          };
          if (stores.isEmpty) {
            await txn.insert('stores', {
              ...values,
              'id': storeId,
              'rating': 0,
              'emoji': '🌷',
              'min_order': 0,
              'delivery_minutes': 60
            });
          } else {
            await txn.update('stores', values,
                where: 'id = ?', whereArgs: [storeId]);
          }
          await txn.update('users',
              {'store_id': storeId, 'role': 'store', 'account_type': 'store'},
              where: 'id = ?', whereArgs: [ownerId]);
          // Publishing an application must also approve the linked store;
          // catalog and map visibility read this separate moderation record.
          final approvals = await txn.query('local_records',
              where: 'id = ? AND scope = ?',
              whereArgs: [storeId, 'store_approvals']);
          final previous = approvals.isEmpty
              ? <String, Object?>{}
              : Map<String, Object?>.from(
                  jsonDecode(approvals.single['payload'] as String) as Map);
          final timestamp = DateTime.now().toIso8601String();
          await txn.insert(
              'local_records',
              {
                'id': storeId,
                'scope': 'store_approvals',
                'payload': jsonEncode(
                    {...previous, 'status': 'approved', 'reason': null}),
                'created_at': approvals.isEmpty
                    ? timestamp
                    : approvals.single['created_at'],
                'updated_at': timestamp,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        });
      }
    }
    final id = recordId ?? '${scope}_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    await db.insert(
        'local_records',
        {
          'id': id,
          'scope': scope,
          'payload': jsonEncode(data,
              toEncodable: (value) => value is DateTime
                  ? value.toIso8601String()
                  : throw StateError('قيمة غير قابلة للحفظ')),
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> _seed(Database database) async {
    final batch = database.batch();
    for (final store in seed.stores) {
      batch.insert('stores', _storeMap(store));
    }
    for (final product in seed.products) {
      batch.insert('products', _productMap(product));
    }
    batch.insert('coupons',
        {'id': 'welcome', 'code': 'AZHARNA10', 'discount': 10, 'active': 1});
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Store>> fetchStores(String city) async {
    final rows = await db.query('stores', where: 'city = ?', whereArgs: [city]);
    final approved = (await fetchAdminStores())
        .where((s) => s.status == StoreApprovalStatus.approved)
        .map((s) => s.id)
        .toSet();
    return rows
        .where((s) =>
            approved.contains(s['id']) ||
            _signedInUser?.storeId == s['id'] ||
            _signedInUser?.role == UserRole.superAdmin)
        .map(_storeFromMap)
        .toList();
  }

  @override
  Future<List<AdminRecord>> fetchApprovedStoreApplications() async {
    final applications = await super.fetchApprovedStoreApplications();
    final locations = await fetchAdminRecords('store_locations');
    final users = await db.query('users');
    final result = <AdminRecord>[];
    for (final store in await fetchAdminStores()) {
      if (store.status != StoreApprovalStatus.approved) continue;
      final owner = users.where((u) => u['store_id'] == store.id).firstOrNull;
      final application = applications
          .where((r) => owner != null && r.data['ownerId'] == owner['id'])
          .firstOrNull;
      final location =
          locations.where((r) => r.data['storeId'] == store.id).firstOrNull;
      final data = <String, Object?>{
        ...?application?.data,
        ...?location?.data,
        'name': store.name,
        'city': store.city,
        'ownerId': owner?['id'],
        'phone': owner?['phone'],
        'status': 'approved'
      };
      if (data['latitude'] is num && data['longitude'] is num)
        result.add(
            AdminRecord(id: store.id, scope: 'store_applications', data: data));
    }
    return result;
  }

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await db.query('products', orderBy: 'rating DESC');
    final approvals = {for (final p in await fetchAdminProducts()) p.id: p};
    final stores = (await fetchAdminStores())
        .where((s) => s.status == StoreApprovalStatus.approved)
        .map((s) => s.id)
        .toSet();
    return rows
        .where((p) =>
            _signedInUser?.role == UserRole.superAdmin ||
            _signedInUser?.storeId == p['store_id'] ||
            (approvals[p['id']]?.active == true &&
                stores.contains(p['store_id'])))
        .map(_productFromMap)
        .toList();
  }

  @override
  Future<Product> saveProduct(Product product) async {
    final actor = _signedInUser;
    if (actor == null ||
        (actor.role != UserRole.superAdmin &&
            (actor.role != UserRole.store || actor.storeId != product.storeId)))
      throw StateError('صلاحية المتجر مطلوبة');
    final existing =
        await db.query('products', where: 'id = ?', whereArgs: [product.id]);
    if (existing.isNotEmpty && existing.single['store_id'] != product.storeId)
      throw StateError('لا يمكنك تعديل منتج متجر آخر');
    if (existing.isEmpty) {
      await db.insert('products', _productMap(product));
    } else {
      await db.update('products', _productMap(product),
          where: 'id = ?', whereArgs: [product.id]);
    }
    await saveAdminRecord('product_approvals', product.id,
        {'status': actor.role == UserRole.superAdmin ? 'approved' : 'pending'});
    return product;
  }

  @override
  Future<String> saveProductImage(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    if (storeId.isEmpty || bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
      throw StateError('اختر صورة أصغر من 5 ميغابايت');
    }
    return saveLocalProductImage(bytes, fileName);
  }

  @override
  Future<String> saveStoreProfilePhoto(
      {required String storeId,
      required Uint8List bytes,
      required String fileName}) async {
    if (storeId.isEmpty || bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
      throw StateError('اختر صورة أصغر من 5 ميغابايت لمتجرك');
    }
    final mime =
        fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final url = 'data:$mime;base64,${base64Encode(bytes)}';
    await saveAdminRecord('store_profile_photos', storeId, {'photoUrl': url});
    return url;
  }

  @override
  Future<AppUser> verifyOtp(
      {required challenge,
      required String code,
      required String phone,
      required UserRole role}) async {
    final verified = await super
        .verifyOtp(challenge: challenge, code: code, phone: phone, role: role);
    final user = await db.transaction((txn) async {
      final rows = await txn.query('users');
      final matches = rows
          .where((row) =>
              accountPhone(row['phone'] as String) == accountPhone(phone))
          .toList();
      if (matches.length > 1) {
        throw StateError('يوجد أكثر من حساب لهذا الرقم. راجع الإدارة');
      }
      final existing = matches.isEmpty ? null : matches.single;
      final account = localAccount(verified, existing);
      if (existing == null) {
        await txn.insert('users', {
          'id': account.id,
          'name': account.name,
          'phone': account.phone,
          'role': account.role.name,
          'account_type': account.role.name,
          'store_id': account.storeId,
          'active': 1,
          'points': 78,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else if (existing['store_id'] == null && account.storeId != null) {
        await txn.update('users', {'store_id': account.storeId},
            where: 'id = ?', whereArgs: [account.id]);
      }
      return account;
    });
    _signedInUser = user;
    return user;
  }

  @override
  Future<String> createOrder(AppOrder order) async {
    final customer = _signedInUser;
    if (customer == null || customer.role != UserRole.customer)
      throw StateError('سجّل الدخول كعميل قبل إنشاء الطلب');
    final available = {for (final p in await fetchProducts()) p.id: p};
    final settings = await recordData('platform', 'settings');
    if (settings['maintenanceMode'] == true)
      throw StateError('استقبال الطلبات متوقف للصيانة');
    if (order.subtotal < ((settings['minimumOrder'] as num?)?.toInt() ?? 0))
      throw StateError('قيمة السلة أقل من الحد الأدنى للطلب');
    if (order.items.isEmpty ||
        order.items.any((i) =>
            i.qty <= 0 || available[i.product.id]?.price != i.product.price))
      throw StateError('تغيرت المنتجات أو الأسعار؛ حدّث السلة');
    for (final storeId in order.items.map((i) => i.product.storeId).toSet()) {
      if ((await recordData('store_settings', storeId))['acceptingOrders'] ==
          false) throw StateError('المتجر متوقف عن استقبال الطلبات مؤقتًا');
    }
    final id = 'AZ-${DateTime.now().millisecondsSinceEpoch}';
    await db.transaction((txn) async {
      final benefits = await RewardAccount.read(txn, customer.id);
      benefits.spend(
          orderId: id,
          subtotal: order.subtotal,
          deliveryFee: order.deliveryFee,
          expectedDiscount: order.discount,
          walletAmount: order.walletUsed,
          couponId: order.couponId);
      await benefits.write(txn, customer.id);
      await txn.insert('orders', {
        'coupon_id': order.couponId,
        'discount': order.discount,
        'wallet_used': order.walletUsed,
        'id': id,
        'user_id': customer.id,
        'address': order.address,
        'delivery_fee': order.deliveryFee,
        'status': order.status.name,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final item in order.items) {
        await txn.insert('order_items', {
          'order_id': id,
          'product_id': item.product.id,
          'quantity': item.qty,
          'unit_price': item.product.price,
        });
      }
    });
    return id;
  }

  @override
  Future<List<AppOrder>> fetchOrders(
      {String? customerId, String? storeId}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (customerId != null) {
      where.add('o.user_id = ?');
      args.add(customerId);
    }
    if (storeId != null) {
      where.add('p.store_id = ?');
      args.add(storeId);
    }
    final rows = await db.rawQuery('''
      SELECT DISTINCT o.id, o.address, o.delivery_fee, o.status, o.created_at, o.coupon_id, o.discount, o.wallet_used
      FROM orders o
      JOIN order_items oi ON oi.order_id = o.id
      JOIN products p ON p.id = oi.product_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY o.created_at DESC
    ''', args);
    final result = <AppOrder>[];
    for (final row in rows) {
      final itemRows = await db.rawQuery('''
        SELECT oi.quantity, oi.unit_price, p.id, p.store_id, p.name,
               p.category, p.emoji, p.rating, p.description, p.image_url, p.image_urls
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        WHERE oi.order_id = ?
        ${storeId == null ? '' : 'AND p.store_id = ?'}
      ''', [row['id'], if (storeId != null) storeId]);
      final items = itemRows
          .map((item) => OrderItem(
                Product(
                  id: item['id'] as String,
                  storeId: item['store_id'] as String,
                  name: item['name'] as String,
                  category: item['category'] as String,
                  price: item['unit_price'] as int,
                  emoji: item['emoji'] as String,
                  rating: (item['rating'] as num).toDouble(),
                  description: item['description'] as String,
                  imageUrl: item['image_url'] as String?,
                  imageUrls: _photoUrls(item['image_urls']),
                ),
                item['quantity'] as int,
              ))
          .toList();
      final fulfilment = storeId == null
          ? <String, Object?>{}
          : await recordData('order_fulfilment', 'fulfilment_${row['id']}');
      result.add(AppOrder(
        id: row['id'] as String,
        couponId: row['coupon_id'] as String?,
        discount: (row['discount'] as num?)?.toInt() ?? 0,
        walletUsed: (row['wallet_used'] as num?)?.toInt() ?? 0,
        items: items,
        deliveryFee: row['delivery_fee'] as int,
        address: row['address'] as String,
        status: _orderStatusFromName(
            (fulfilment[storeId] ?? row['status']) as String?),
      ));
    }
    return result;
  }

  @override
  Future<List<AdminOrderRecord>> fetchAdminOrders() async {
    final rows = await db.rawQuery('''
      SELECT o.id, o.user_id, o.address, o.delivery_fee, o.status, o.created_at,
             COALESCE(SUM(oi.quantity), 0) AS item_count,
             COALESCE(SUM(oi.quantity * oi.unit_price), 0) + o.delivery_fee - o.discount AS total
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      GROUP BY o.id
      ORDER BY o.created_at DESC
    ''');
    final records = <AdminOrderRecord>[];
    for (final row in rows) {
      final stores = await db.rawQuery('''
        SELECT DISTINCT p.store_id FROM order_items oi
        JOIN products p ON p.id = oi.product_id WHERE oi.order_id = ?
      ''', [row['id']]);
      records.add(AdminOrderRecord(
        id: row['id'] as String,
        customerId: row['user_id'] as String? ?? 'customer-1',
        storeIds: stores.map((item) => item['store_id'] as String).toList(),
        itemCount: (row['item_count'] as num).toInt(),
        total: (row['total'] as num).toInt(),
        address: row['address'] as String,
        status: _orderStatusFromName(row['status'] as String?),
        createdAt: DateTime.tryParse(row['created_at'] as String),
      ));
    }
    return records;
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final actor = _signedInUser;
    if (actor == null ||
        ![UserRole.store, UserRole.superAdmin].contains(actor.role))
      throw StateError('صلاحية المتجر أو الإدارة مطلوبة');
    final order =
        (await fetchAdminOrders()).where((o) => o.id == orderId).firstOrNull;
    if (order == null ||
        (actor.role == UserRole.store &&
            !order.storeIds.contains(actor.storeId)))
      throw StateError('لا تملك صلاحية هذا الطلب');
    await db.transaction((txn) async {
      final rows =
          await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (rows.isEmpty) throw StateError('الطلب غير موجود');
      final row = rows.single;
      final progressRows = await txn.query('local_records',
          where: 'id = ?', whereArgs: ['fulfilment_$orderId']);
      final progress = progressRows.isEmpty
          ? <String, Object?>{}
          : Map<String, Object?>.from(
              jsonDecode(progressRows.single['payload'] as String) as Map);
      final current = actor.role == UserRole.store
          ? progress[actor.storeId] ?? row['status']
          : row['status'];
      if (!canAdvanceOrder(_orderStatusFromName(current as String?), status))
        throw StateError('انتقال حالة غير صالح');
      for (final storeId in order.storeIds) {
        progress.putIfAbsent(storeId, () => row['status']);
        if (actor.role == UserRole.store
            ? storeId == actor.storeId
            : _orderStatusFromName(progress[storeId] as String?).index <
                status.index) progress[storeId] = status.name;
      }
      final aggregate = order.storeIds
          .map((id) => _orderStatusFromName(progress[id] as String?))
          .reduce((a, b) => a.index < b.index ? a : b);
      final now = DateTime.now().toIso8601String();
      await txn.insert(
          'local_records',
          {
            'id': 'fulfilment_$orderId',
            'scope': 'order_fulfilment',
            'payload': jsonEncode(progress),
            'created_at': now,
            'updated_at': now
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (aggregate == OrderStatus.delivered && row['rewards_granted'] != 1) {
        if (row['status'] != OrderStatus.delivering.name) {
          throw StateError('انتقال حالة غير صالح');
        }
        final sums = await txn.rawQuery(
            'SELECT SUM(quantity * unit_price) AS subtotal FROM order_items WHERE order_id = ?',
            [orderId]);
        final account = await RewardAccount.read(txn, row['user_id'] as String);
        account.earn(
            ((sums.single['subtotal'] as num?)?.toInt() ?? 0) -
                ((row['discount'] as num?)?.toInt() ?? 0),
            orderId);
        await account.write(txn, row['user_id'] as String);
        await txn.update('orders', {'rewards_granted': 1},
            where: 'id = ?', whereArgs: [orderId]);
      }
      await txn.update('orders', {'status': aggregate.name},
          where: 'id = ?', whereArgs: [orderId]);
    });
  }

  OrderStatus _orderStatusFromName(String? value) =>
      OrderStatus.values.where((item) => item.name == value).firstOrNull ??
      OrderStatus.newOrder;

  Map<String, Object?> _storeMap(Store s) => {
        'id': s.id,
        'name': s.name,
        'city': s.city,
        'rating': s.rating,
        'emoji': s.emoji,
        'min_order': s.minOrder,
        'delivery_minutes': s.deliveryMinutes,
      };

  Map<String, Object?> _productMap(Product v) => {
        'id': v.id,
        'store_id': v.storeId,
        'name': v.name,
        'category': v.category,
        'price': v.price,
        'emoji': v.emoji,
        'rating': v.rating,
        'description': v.description,
        'image_url': v.imageUrl,
        'image_urls': jsonEncode(v.photos),
      };

  Store _storeFromMap(Map<String, Object?> m) => Store(
        id: m['id'] as String,
        name: m['name'] as String,
        city: m['city'] as String,
        rating: (m['rating'] as num).toDouble(),
        emoji: m['emoji'] as String,
        minOrder: m['min_order'] as int,
        deliveryMinutes: m['delivery_minutes'] as int,
      );

  Product _productFromMap(Map<String, Object?> m) => Product(
        id: m['id'] as String,
        storeId: m['store_id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        price: m['price'] as int,
        emoji: m['emoji'] as String,
        rating: (m['rating'] as num).toDouble(),
        description: m['description'] as String,
        imageUrl: m['image_url'] as String?,
        imageUrls: _photoUrls(m['image_urls']),
      );

  List<String> _photoUrls(Object? value) => value is String
      ? (jsonDecode(value) as List).whereType<String>().toList()
      : const [];

  String encodePayload(Map<String, Object?> value) => jsonEncode(value);
}
