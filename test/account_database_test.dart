import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/domain/accounts/account_identity.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/data/local/database_schema.dart';
import 'package:sqflite/sqflite.dart';

class RecordingDatabase implements Database {
  final statements = <String>[];
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    statements.add(sql);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  AppUser account(String phone, [UserRole role = UserRole.customer]) =>
      AppUser(id: 'customer-1', name: 'Customer', phone: phone, role: role);
  test('persisted roles include courier and preserve the legacy admin alias',
      () {
    expect(parseUserRole('courier'), UserRole.courier);
    expect(parseUserRole('admin'), UserRole.superAdmin);
    expect(parseUserRole('unexpected'), isNull);
    expect(UserRole.courier.canSelfRegister, isFalse);
    expect(UserRole.superAdmin.canSelfRegister, isFalse);
  });
  test('equivalent Iraqi phone formats identify the same local account', () {
    final expected = localAccount(account('07701234567'), null).id;
    for (final phone in ['+9647701234567', '009647701234567', '٠٧٧٠١٢٣٤٥٦٧']) {
      expect(localAccount(account(phone), null).id, expected);
    }
    expect(localAccount(account('07709999999'), null).id, isNot(expected));
  });
  test('legacy identity and role survive sign-in with another selected role',
      () {
    final existing = <String, Object?>{
      'id': 'legacy',
      'name': 'Saved',
      'phone': '07701234567',
      'role': 'customer',
      'points': 900,
      'active': 1
    };
    final user = localAccount(account('07701234567', UserRole.store), existing);
    expect(user.id, 'legacy');
    expect(user.name, 'Saved');
    expect(user.role, UserRole.customer);
    expect(existing['points'], 900);
  });
  test('disabled and unrecognized accounts cannot silently become customers',
      () {
    for (final data in [
      <String, Object?>{'role': 'customer', 'active': 0},
      <String, Object?>{'role': 'unknown', 'active': 1},
      <String, Object?>{'role': 'courier', 'active': 1}
    ]) {
      expect(
          () => localAccount(account('07701234567'), data), throwsStateError);
    }
  });
  test('upgrade dispatcher preserves historical migrations and runs v6 once',
      () async {
    final current = RecordingDatabase();
    await DatabaseSchema.upgrade(current, 6, 6);
    expect(current.statements, isEmpty);
    final legacy = RecordingDatabase();
    await DatabaseSchema.upgrade(legacy, 4, 6);
    expect(legacy.statements.first, contains('image_url'));
    expect(legacy.statements.where((s) => s.contains('ADD COLUMN active')),
        hasLength(1));
    expect(legacy.statements.any((s) => s.contains('DROP TABLE')), isFalse);
  });
}
