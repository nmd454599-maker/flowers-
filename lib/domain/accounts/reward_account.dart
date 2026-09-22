import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';

/// All local balance changes run inside the order/database transaction.
class RewardAccount {
  final Map<String, Object?> data;
  RewardAccount(Map<String, Object?> value) : data = Map.from(value);
  int get points => (data['points'] as num?)?.toInt() ?? 0;
  int get lifetime => (data['lifetimePoints'] as num?)?.toInt() ?? 0;
  int get balance => (data['balance'] as num?)?.toInt() ?? 0;
  List<Map<String, Object?>> get coupons => (data['coupons'] as List? ?? [])
      .map((e) => Map<String, Object?>.from(e as Map))
      .toList();
  String get membership => lifetime >= 1500
      ? 'ذهبية'
      : lifetime >= 500
          ? 'فضية'
          : 'أساسية';
  static Future<RewardAccount> read(DatabaseExecutor db, String uid) async {
    final rows = await db.query('local_records',
        where: 'id = ?', whereArgs: ['account_benefits_$uid']);
    return RewardAccount(rows.isEmpty
        ? {}
        : Map<String, Object?>.from(
            jsonDecode(rows.single['payload'] as String) as Map));
  }

  Future<void> write(DatabaseExecutor db, String uid) async {
    data['ownerId'] = uid;
    data['membership'] = membership;
    final now = DateTime.now().toIso8601String();
    await db.insert(
        'local_records',
        {
          'id': 'account_benefits_$uid',
          'scope': 'customer_account_benefits',
          'payload': jsonEncode(data),
          'created_at': now,
          'updated_at': now
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  void log(String type, String description,
      {int amount = 0, int points = 0, String? orderId}) {
    data['transactions'] = [
      {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'type': type,
        'description': description,
        'amount': amount,
        'points': points,
        'orderId': orderId,
        'createdAt': DateTime.now().toIso8601String()
      },
      ...(data['transactions'] as List? ?? []),
    ].take(100).toList();
  }

  String redeem(String id) {
    final available = coupons;
    if (points < 100) throw StateError('تحتاج إلى 100 نقطة للاستبدال');
    if (available.length >= 50) {
      throw StateError('استخدم أحد كوبوناتك قبل استبدال المزيد');
    }
    data['points'] = points - 100;
    data['coupons'] = [
      ...available,
      {'id': id, 'code': id, 'value': 1000}
    ];
    log('redeem', 'استبدال 100 نقطة بكوبون 1,000 د.ع', points: -100);
    return id;
  }

  void credit(int amount, String reason, String actor) {
    if (amount <= 0 || amount > 100000000 || reason.trim().isEmpty) {
      throw StateError('أدخل مبلغًا موجبًا وسبب الإضافة');
    }
    if (balance + amount > 100000000) throw StateError('تجاوز حد رصيد المحفظة');
    data['balance'] = balance + amount;
    log('credit', '$reason • الإدارة: $actor', amount: amount);
  }

  int discount(String? couponId, int subtotal) {
    if (couponId == null) return 0;
    if (!coupons.any((c) => c['id'] == couponId) || subtotal < 1000) {
      throw StateError('الكوبون غير متاح أو قيمة المنتجات أقل من 1,000 د.ع');
    }
    return 1000;
  }

  void spend(
      {required String orderId,
      required int subtotal,
      required int deliveryFee,
      required int expectedDiscount,
      required int walletAmount,
      String? couponId}) {
    final actual = discount(couponId, subtotal);
    if (actual != expectedDiscount ||
        walletAmount < 0 ||
        walletAmount > min(balance, subtotal + deliveryFee - actual)) {
      throw StateError('تغيّر الرصيد أو الخصم، راجع الطلب مجددًا');
    }
    if (couponId != null) {
      data['coupons'] = coupons.where((c) => c['id'] != couponId).toList();
    }
    data['balance'] = balance - walletAmount;
    if (couponId != null) {
      log('coupon', 'استخدام كوبون خصم', amount: -actual, orderId: orderId);
    }
    if (walletAmount > 0) {
      log('debit', 'خصم من المحفظة للطلب',
          amount: -walletAmount, orderId: orderId);
    }
  }

  void earn(int productTotal, String orderId) {
    final earned = max(0, productTotal) ~/ 1000;
    data['points'] = points + earned;
    data['lifetimePoints'] = lifetime + earned;
    log('earned', 'نقاط طلب تم تسليمه', points: earned, orderId: orderId);
  }
}
