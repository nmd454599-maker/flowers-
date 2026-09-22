import 'package:azharna_pro/data/sqlite_repository.dart';
import 'package:azharna_pro/data/local/database_schema.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'support/test_sqlite.dart';

class LocalApplicationRepository extends SqliteRepository {
  LocalApplicationRepository(this.database);
  final Database database;
  @override
  Database get db => database;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'merchant request survives recreation; only admin approval publishes the store',
      () async {
    final directory =
        await Directory('artifacts').createTemp('store-approval-');
    final database = await TestSqlite.open('${directory.path}/test.db');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });
    await DatabaseSchema.create(database);
    await database.insert('stores', {
      'id': 's1',
      'name': 'متجر',
      'city': 'بغداد',
      'rating': 0,
      'emoji': '',
      'min_order': 0,
      'delivery_minutes': 30
    });
    Future<AppUser> login(LocalApplicationRepository repo, String phone,
            UserRole role) async =>
        repo.verifyOtp(
            challenge: await repo.requestOtp(phone),
            code: '1234',
            phone: phone,
            role: role);
    final merchant = LocalApplicationRepository(database);
    final owner = await login(merchant, '07811234567', UserRole.store);
    final admin = LocalApplicationRepository(database);
    await login(admin, '07501234567', UserRole.superAdmin);
    await admin.updateStoreApproval(
        owner.storeId!, StoreApprovalStatus.pending, null);
    final id = await merchant.submitStoreApplication({
      'ownerId': owner.id,
      'name': 'متجر الاختبار',
      'latitude': 33.3,
      'longitude': 44.4
    });
    final pending =
        (await admin.fetchAdminRecords('store_applications')).single;
    expect(pending.id, id);
    expect(pending.data['status'], 'pending');
    expect(await admin.fetchApprovedStoreApplications(), isEmpty);
    await expectLater(
        merchant.saveAdminRecord(
            'store_applications', id, {...pending.data, 'status': 'approved'}),
        throwsStateError);
    await admin.saveAdminRecord(
        'store_applications', id, {...pending.data, 'status': 'approved'});
    final customer = LocalApplicationRepository(database);
    final published = await customer.fetchApprovedStoreApplications();
    expect(published.single.id, owner.storeId);
    expect(published.single.data['latitude'], 33.3);
    expect(published.single.data['longitude'], 44.4);
    await admin.updateStoreApproval(
        owner.storeId!, StoreApprovalStatus.rejected, 'test');
    expect(await customer.fetchApprovedStoreApplications(), isEmpty);
  });
}
