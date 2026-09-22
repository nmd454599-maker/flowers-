import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../data/app_repository.dart';
import '../data/firebase_repository.dart';
import '../data/sqlite_repository.dart';
import '../models/models.dart';

/// Private account data. Financial balances are deliberately not client writable.
class CustomerAccountService {
  final AppRepository repository;
  final AppUser user;
  CustomerAccountService(this.repository, this.user);
  static const editable = {
    'profile',
    'recipients',
    'occasions',
    'addresses',
    'preferences'
  };

  Future<Map<String, Object?>> read(String section) async {
    final repo = repository;
    if (repo is FirebaseRepository) {
      if (repo.auth.currentUser?.uid != user.id) {
        throw StateError('سجّل الدخول مجددًا');
      }
      return (await repo.firestore
                  .collection('users')
                  .doc(user.id)
                  .collection('account')
                  .doc(section)
                  .get())
              .data() ??
          {};
    }
    if (repo is SqliteRepository) {
      final rows = await repo.db.query('local_records',
          columns: ['payload'],
          where: 'id = ? AND scope = ?',
          whereArgs: [
            'account_${section}_${user.id}',
            'customer_account_$section'
          ],
          limit: 1);
      if (rows.isNotEmpty) {
        final value = Map<String, Object?>.from(
            jsonDecode(rows.first['payload'] as String) as Map);
        if (value['ownerId'] == user.id) return value;
        return {};
      }
    }
    final records = await repo.fetchAdminRecords('customer_account_$section');
    return records
            .where((r) => r.data['ownerId'] == user.id)
            .firstOrNull
            ?.data ??
        {};
  }

  Future<void> save(String section, Map<String, Object?> data) async {
    if (!editable.contains(section)) {
      throw StateError('لا يمكن تعديل هذا السجل');
    }
    if (section == 'profile' &&
        (data['name'] is! String || (data['name'] as String).trim().isEmpty)) {
      throw StateError('الاسم مطلوب');
    }
    final value = {...data, 'ownerId': user.id};
    if (utf8.encode(jsonEncode(value)).length > 700000) {
      throw StateError('حجم البيانات كبير');
    }
    final repo = repository;
    if (repo is FirebaseRepository) {
      if (repo.auth.currentUser?.uid != user.id) {
        throw StateError('سجّل الدخول مجددًا');
      }
      final batch = repo.firestore.batch();
      batch.set(
          repo.firestore
              .collection('users')
              .doc(user.id)
              .collection('account')
              .doc(section),
          value);
      if (section == 'profile') {
        batch.update(repo.firestore.collection('users').doc(user.id),
            {'name': data['name']});
      }
      await batch.commit();
    } else if (repo is SqliteRepository) {
      await repo.db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        await txn.insert(
            'local_records',
            {
              'id': 'account_${section}_${user.id}',
              'scope': 'customer_account_$section',
              'payload': jsonEncode(value),
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
        if (section == 'profile') {
          await txn.update('users', {'name': data['name']},
              where: 'id = ?', whereArgs: [user.id]);
        }
      });
    } else {
      await repo.saveAdminRecord(
          'customer_account_$section', 'account_${section}_${user.id}', value);
    }
  }

  Future<List<Map<String, Object?>>> requests(String kind) async {
    final repo = repository;
    if (repo is FirebaseRepository) {
      final docs = await repo.firestore
          .collection('customerRequests')
          .where('ownerId', isEqualTo: user.id)
          .get();
      return docs.docs
          .where((d) => d.data()['kind'] == kind)
          .map((d) => <String, Object?>{...d.data(), 'id': d.id})
          .toList();
    }
    return (await repo.fetchAdminRecords('customer_requests'))
        .where((r) => r.data['ownerId'] == user.id && r.data['kind'] == kind)
        .map((r) => <String, Object?>{...r.data, 'id': r.id})
        .toList();
  }

  Future<void> submit(String kind, Map<String, Object?> fields) async {
    if (!{'support', 'store', 'courier'}.contains(kind)) {
      throw StateError('طلب غير صالح');
    }
    final data = <String, Object?>{
      'ownerId': user.id,
      'name': user.name,
      'phone': user.phone,
      'kind': kind,
      'fields': fields,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String()
    };
    final repo = repository;
    if (repo is FirebaseRepository) {
      if (repo.auth.currentUser?.uid != user.id) {
        throw StateError('سجّل الدخول مجددًا');
      }
      await repo.firestore.collection('customerRequests').add(data);
    } else {
      await repo.saveAdminRecord('customer_requests', null, data);
    }
  }

  static List<Map<String, Object?>> rows(Map<String, Object?> data) =>
      (data['items'] as List? ?? [])
          .map((e) => Map<String, Object?>.from(e as Map))
          .toList();
}
