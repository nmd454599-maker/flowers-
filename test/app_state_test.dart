import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/data/mock_data.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppState production flows', () {
    late AppState state;

    setUp(() {
      state = AppState(repository: DemoRepository());
    });

    test('OTP request and verification create a customer session', () async {
      await state.requestOtp('07701234567');
      await state.verifyOtp('07701234567', '1234', UserRole.customer);

      expect(state.user, isNotNull);
      expect(state.user!.role, UserRole.customer);
      expect(state.busy, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('catalog is loaded through the repository', () async {
      await state.loadCatalog();

      expect(state.stores, isNotEmpty);
      expect(state.products, isNotEmpty);
    });

    test('invalid OTP is rejected and exposes a safe error', () async {
      await state.requestOtp('07701234567');

      await expectLater(
        state.verifyOtp('07701234567', '0000', UserRole.customer),
        throwsA(isA<FormatException>()),
      );
      expect(state.user, isNull);
      expect(state.errorMessage, contains('رمز التحقق غير صحيح'));
      expect(state.busy, isFalse);
    });

    test('checkout persists the order before clearing the cart', () async {
      await state.requestOtp('07701234567');
      await state.verifyOtp('07701234567', '1234', UserRole.customer);
      state.addToCart(products.first);

      final order = await state.checkout('بغداد - الكرادة');

      expect(order.items, hasLength(1));
      expect(state.orders.single.id, order.id);
      expect(state.cart, isEmpty);
    });

    test('super admin data and metrics load through the repository', () async {
      await state.requestOtp('07501234567');
      await state.verifyOtp('07501234567', '1234', UserRole.superAdmin);

      await state.loadAdminData();

      expect(state.adminUsers, isNotEmpty);
      expect(state.adminStores, isNotEmpty);
      expect(state.adminMetrics['users'], state.adminUsers.length);
    });

    test('super admin changes are persisted per tool scope', () async {
      await state.requestOtp('07501234567');
      await state.verifyOtp('07501234567', '1234', UserRole.superAdmin);

      final id = await state.saveAdminRecord('finance', 'commission', {
        'percentage': 14,
        'active': true,
      });
      await state.loadAdminScope('finance');

      expect(id, 'commission');
      expect(state.adminRecords['finance'], hasLength(1));
      expect(state.adminRecords['finance']!.single.data['percentage'], 14);
    });
  });
}
