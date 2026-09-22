import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/app_repository.dart';
import '../data/firebase_repository.dart';
import '../data/sqlite_repository.dart';
import '../domain/accounts/reward_account.dart';
import '../models/models.dart';
import 'customer_account_service.dart';

class RewardsService {
  final AppRepository repository;
  final AppUser user;
  RewardsService(this.repository, this.user);
  String id() =>
      'AZ${DateTime.now().microsecondsSinceEpoch}${Random.secure().nextInt(999999)}';
  Future<Map<String, Object?>> read() =>
      CustomerAccountService(repository, user).read('benefits');

  Future<void> syncDelivered() async {
    final repo = repository;
    if (repo is SqliteRepository) {
      await repo.db.transaction((txn) async {
        final orders = await txn.query('orders', where: 'user_id = ? AND status = ? AND rewards_granted = 0', whereArgs: [user.id, 'delivered']);
        if (orders.isEmpty) return;
        final account = await RewardAccount.read(txn, user.id);
        for (final order in orders) {
          final sums = await txn.rawQuery('SELECT SUM(quantity * unit_price) AS subtotal FROM order_items WHERE order_id = ?', [order['id']]);
          account.earn(((sums.single['subtotal'] as num?)?.toInt() ?? 0) - ((order['discount'] as num?)?.toInt() ?? 0), order['id'] as String);
          await txn.update('orders', {'rewards_granted': 1}, where:'id = ?',whereArgs:[order['id']]);
        }
        await account.write(txn,user.id);
      });
    } else if (repo is FirebaseRepository) {
      String? cursor;
      do {
        final result = await FirebaseFunctions.instanceFor(region:'me-central1').httpsCallable('syncRewardPoints').call({'cursor':cursor});
        cursor = (result.data as Map)['cursor'] as String?;
      } while (cursor != null);
    }
  }

  Future<void> redeem(String requestId) async {
    final repo = repository;
    if (repo is FirebaseRepository) {
      await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('redeemRewardPoints')
          .call({'requestId': requestId});
    } else if (repo is SqliteRepository) {
      await repo.db.transaction((txn) async {
        final marker = 'redemption_${user.id}_$requestId';
        if ((await txn
                .query('local_records', where: 'id = ?', whereArgs: [marker]))
            .isNotEmpty) {
          return;
        }
        final account = await RewardAccount.read(txn, user.id);
        account.redeem(requestId);
        await account.write(txn, user.id);
        final now = DateTime.now().toIso8601String();
        await txn.insert('local_records', {
          'id': marker,
          'scope': 'reward_redemptions',
          'payload': '{}',
          'created_at': now,
          'updated_at': now
        });
      });
    } else {
      throw StateError('استخدم قاعدة البيانات المحلية أو النسخة المتصلة');
    }
  }

  Future<void> credit(
      String customerId, int amount, String reason, String requestId) async {
    if (user.role != UserRole.superAdmin) {
      throw StateError('هذه العملية للإدارة فقط');
    }
    final repo = repository;
    if (repo is FirebaseRepository) {
      await FirebaseFunctions.instanceFor(region: 'me-central1')
          .httpsCallable('creditCustomerWallet')
          .call({
        'customerId': customerId,
        'amount': amount,
        'reason': reason,
        'requestId': requestId
      });
    } else if (repo is SqliteRepository) {
      await repo.db.transaction((txn) async {
        final actor = await txn.query('users',
            where: 'id = ? AND role = ? AND active = 1',
            whereArgs: [user.id, 'superAdmin']);
        final customer = await txn.query('users',
            where: 'id = ? AND role = ? AND active = 1',
            whereArgs: [customerId, 'customer']);
        if (actor.isEmpty || customer.isEmpty) {
          throw StateError('الحساب غير متاح أو الصلاحية غير كافية');
        }
        final marker = 'wallet_credit_${user.id}_$requestId';
        if ((await txn
                .query('local_records', where: 'id = ?', whereArgs: [marker]))
            .isNotEmpty) {
          return;
        }
        final account = await RewardAccount.read(txn, customerId);
        account.credit(amount, reason, user.id);
        await account.write(txn, customerId);
        final now = DateTime.now().toIso8601String();
        await txn.insert('local_records', {
          'id': marker,
          'scope': 'wallet_credits',
          'payload': '{}',
          'created_at': now,
          'updated_at': now
        });
      });
    } else {
      throw StateError('استخدم النسخة المحلية أو المتصلة');
    }
  }
}
