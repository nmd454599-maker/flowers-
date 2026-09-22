import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_config.dart';
import 'package:azharna_pro/data/app_repository.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/data/mock_data.dart' as seed;
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/state/operation_runner.dart';
import 'package:azharna_pro/domain/orders/order_transitions.dart';

class DelayedAdminRepository extends DemoRepository {
  final users = Completer<List<AdminUserRecord>>();
  @override
  Future<List<AdminUserRecord>> fetchAdminUsers() => users.future;
}

class DelayedLoginRepository extends DemoRepository {
  final login = Completer<AppUser>();
  bool backendSignedIn = false;
  int orderReads = 0;
  @override
  Future<AppUser> verifyOtp(
      {required AuthChallenge challenge,
      required String code,
      required String phone,
      required UserRole role}) async {
    final user = await login.future;
    backendSignedIn = true;
    return user;
  }

  @override
  Future<void> signOut() async {
    backendSignedIn = false;
  }

  @override
  Future<List<AppOrder>> fetchOrders(
      {String? customerId, String? storeId}) async {
    orderReads++;
    return [];
  }
}

class DelayedCitiesRepository extends DemoRepository {
  final cities = <String, Completer<List<Store>>>{};
  @override
  Future<List<Store>> fetchStores(String city) =>
      (cities[city] = Completer<List<Store>>()).future;
}

void main() {
  test('late admin result cannot restore account data after logout', () async {
    final repo = DelayedAdminRepository();
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    final loading =
        expectLater(state.loadAdminData(), throwsA(isA<StaleOperation>()));
    final logout = state.logout();
    expect(state.adminUsers, isEmpty);
    repo.users.complete([
      const AdminUserRecord(
          id: 'secret',
          name: 'Private',
          phone: '0',
          role: UserRole.customer,
          active: true)
    ]);
    await loading;
    await logout;
    expect(state.adminUsers, isEmpty);
    expect(state.adminStores, isEmpty);
    expect(state.errorMessage, isNull);
    expect(state.busy, isFalse);
  });
  test('logout drains late authentication before signing out the backend',
      () async {
    final repo = DelayedLoginRepository();
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    state.authChallenge = const AuthChallenge('test');
    final login = expectLater(state.verifyOtp('0', '0', UserRole.customer),
        throwsA(isA<StaleOperation>()));
    final logout = state.logout();
    await expectLater(state.requestOtp('new'), throwsA(isA<StaleOperation>()));
    repo.login.complete(const AppUser(
        id: 'old', name: 'Old', phone: '0', role: UserRole.customer));
    await login;
    await logout;
    expect(state.user, isNull);
    expect(repo.backendSignedIn, isFalse);
    expect(repo.orderReads, 0);
  });
  test('overlapping loads stay busy and old city results are ignored',
      () async {
    final repo = DelayedCitiesRepository();
    final state = AppState(repository: repo);
    addTearDown(state.dispose);
    final first = state.selectCity('A');
    final second = state.selectCity('B');
    repo.cities['B']!.complete([seed.stores.first]);
    await second;
    expect(state.busy, isTrue);
    expect(state.stores.single.id, seed.stores.first.id);
    repo.cities['A']!.complete([]);
    await first;
    expect(state.busy, isFalse);
    expect(state.selectedCity, 'B');
    expect(state.stores, isNotEmpty);
  });
  test('late result after disposal does not notify or publish state', () async {
    final repo = DelayedCitiesRepository();
    final state = AppState(repository: repo);
    final loading =
        expectLater(state.selectCity('A'), throwsA(isA<StaleOperation>()));
    state.dispose();
    repo.cities['A']!.complete(seed.stores);
    await loading;
    expect(state.stores, isEmpty);
  });
  test('production and release refuse the local authentication backend', () {
    for (final env in ['production', 'staging']) {
      expect(
          () => AppConfig.validateEnvironment(
              environment: env, firebase: false, release: false),
          throwsStateError);
    }
    expect(
        () => AppConfig.validateEnvironment(
            environment: 'local', firebase: true, release: true),
        throwsStateError);
    expect(
        () => AppConfig.validateEnvironment(
            environment: 'production', firebase: true, release: true),
        returnsNormally);
    expect(
        () => AppConfig.validateEnvironment(
            environment: 'local', firebase: false, release: false),
        returnsNormally);
  });
  test('only the three normal order transitions are accepted', () {
    var accepted = 0;
    for (final from in OrderStatus.values) {
      for (final to in OrderStatus.values) {
        if (canAdvanceOrder(from, to)) accepted++;
      }
    }
    expect(accepted, 3);
    expect(
        canAdvanceOrder(OrderStatus.delivered, OrderStatus.preparing), isFalse);
    expect(
        canAdvanceOrder(OrderStatus.preparing, OrderStatus.delivered), isFalse);
    expect(
        canAdvanceOrder(OrderStatus.cancelled, OrderStatus.preparing), isFalse);
  });
}
