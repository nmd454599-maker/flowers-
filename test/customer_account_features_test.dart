import 'package:azharna_pro/screens/customer/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/services/customer_account_service.dart';
import 'package:azharna_pro/screens/customer/customer_account_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

const alice = AppUser(
    id: 'alice', name: 'Alice', phone: '07701234567', role: UserRole.customer);
const bob = AppUser(
    id: 'bob', name: 'Bob', phone: '07709876543', role: UserRole.customer);

class FailedRepository extends DemoRepository {
  @override
  Future<String> saveAdminRecord(
          String scope, String? id, Map<String, Object?> data) async =>
      throw StateError('offline');
}

void main() {
  test('saved sections survive reopening and are isolated per account',
      () async {
    final repo = DemoRepository();
    final a = CustomerAccountService(repo, alice);
    await a.save('profile', {'name': 'New name'});
    await a.save('recipients', {
      'items': [
        {'id': 'r1', 'name': 'Recipient'}
      ]
    });
    await CustomerAccountService(repo, bob)
        .save('profile', {'name': 'Bob new'});
    final reopened = CustomerAccountService(repo, alice);
    expect((await reopened.read('profile'))['name'], 'New name');
    expect(
        CustomerAccountService.rows(await reopened.read('recipients'))
            .single['name'],
        'Recipient');
    expect(await CustomerAccountService(repo, bob).read('recipients'), isEmpty);
  });
  test('client cannot change financial benefits', () async {
    final service = CustomerAccountService(DemoRepository(), alice);
    await expectLater(
        service.save('benefits', {'balance': 500000}), throwsStateError);
  });
  test('support requests are separated from other accounts and applications',
      () async {
    final repo = DemoRepository();
    final service = CustomerAccountService(repo, alice);
    await service.submit('support', {'subject': 'Order question'});
    expect((await service.requests('support')).single['status'], 'pending');
    expect(await service.requests('store'), isEmpty);
    expect(
        await CustomerAccountService(repo, bob).requests('support'), isEmpty);
  });
  testWidgets('profile edit persists and updates the signed in name',
      (tester) async {
    final repo = DemoRepository();
    final state = AppState(repository: repo)..user = alice;
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
        home: CustomerAccountScreen(state: state, title: 'الملف الشخصي')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعديل الملف الشخصي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'اسم جديد');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(state.user!.name, 'اسم جديد');
    expect((await CustomerAccountService(repo, alice).read('profile'))['name'],
        'اسم جديد');
    expect(find.text('تم الحفظ'), findsOneWidget);
  });
  testWidgets('failed save never reports success or changes profile',
      (tester) async {
    final state = AppState(repository: FailedRepository())..user = alice;
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
        home: CustomerAccountScreen(state: state, title: 'الملف الشخصي')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعديل الملف الشخصي'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'اسم جديد');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(state.user!.name, 'Alice');
    expect(find.text('تم الحفظ'), findsNothing);
    expect(find.textContaining('تعذر الحفظ'), findsOneWidget);
  });
  testWidgets('checkout restores saved default address and opted-in gift message', (tester) async {
    final repo = DemoRepository();
    final state = AppState(repository: repo)..user = alice;
    addTearDown(state.dispose);
    final service = CustomerAccountService(repo, alice);
    await service.save('addresses', {'defaultId': 'home', 'items': [
      {'id': 'home', 'name': 'Home', 'city': 'بغداد', 'address': 'شارع الاختبار'}
    ]});
    await service.save('preferences', {'saveGiftMessage': true, 'lastGiftMessage': 'كل عام وأنت بخير'});
    await tester.pumpWidget(MaterialApp(home: CheckoutScreen(state: state)));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.any((f) => f.controller?.text == 'كل عام وأنت بخير'), isTrue);
    // Scroll builds the delivery inputs below the fold.
    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.widgetList<TextField>(find.byType(TextField)).any(
      (f) => f.controller?.text == 'بغداد، شارع الاختبار'), isTrue);
  });
}

