import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/data/mock_data.dart' as seed;
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/customer/checkout_screen.dart';

class PendingOrderRepository extends DemoRepository {
  final result = Completer<String>();
  int calls = 0;
  AppOrder? submitted;
  @override
  Future<String> createOrder(AppOrder order) {
    calls++;
    submitted = order;
    return result.future;
  }
}

void main() {
  testWidgets(
      'cash checkout validates address, sends gift and prevents duplicate taps',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = PendingOrderRepository();
    final state = AppState(repository: repository);
    state.addToCart(seed.products.first);
    await tester.pumpWidget(MaterialApp(home: CheckoutScreen(state: state)));
    await tester.tap(find.text('حب'));
    await tester.enterText(find.byType(TextField).at(0), 'هدية سعيدة');
    await tester.enterText(find.byType(TextField).at(1), 'المستلم');
    await tester.enterText(find.byType(TextField).at(2), '٠٧٧٠١٢٣٤٥٦٧');
    final confirm = find.widgetWithText(
        FilledButton, 'مراجعة الطلب • ${state.cartTotal} د.ع');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    await tester.enterText(
        find.byType(TextField).at(3), 'شارع النخيل، منزل 12');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    await tester.ensureVisible(find.text('تأكيد وإرسال الطلب'));
    await tester.tap(find.text('تأكيد وإرسال الطلب'));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(repository.submitted!.paymentMethod, PaymentMethod.cash);
    expect(repository.submitted!.address, contains('+9647701234567'));
    expect(repository.submitted!.address, contains('بطاقة الإهداء: حب'));
    expect(repository.submitted!.total, state.cartTotal);
    await tester.tap(find.text('جارٍ تأكيد الطلب…'));
    expect(repository.calls, 1);
    repository.result.completeError(StateError('انقطع الاتصال'));
    await tester.pumpAndSettle();
    expect(state.cart, isNotEmpty);
    expect(confirm, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
