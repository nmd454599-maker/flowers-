import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/screens/customer/account_feature_screen.dart';

void main() {
  testWidgets('deletion reports success only after backend acknowledgement',
      (tester) async {
    final result = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: AccountFeatureScreen(
      title: 'حذف الحساب',
      icon: Icons.delete,
      items: const [],
      editable: false,
      onDeleteAccount: () {
        calls++;
        return result.future;
      },
    )));
    await tester.tap(find.text('طلب حذف الحساب نهائياً'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('جارٍ إرسال الطلب…'), findsOneWidget);
    expect(find.text('تم تسجيل طلب الحذف'), findsNothing);
    result.completeError(StateError('تعذر الاتصال'));
    await tester.pumpAndSettle();
    expect(find.text('تعذر الاتصال'), findsOneWidget);
    expect(find.text('طلب حذف الحساب نهائياً'), findsOneWidget);
    expect(find.text('تم تسجيل طلب الحذف'), findsNothing);
  });
  testWidgets('acknowledged request disables duplicate submission',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: AccountFeatureScreen(
      title: 'حذف الحساب',
      icon: Icons.delete,
      items: const [],
      editable: false,
      onDeleteAccount: () async {
        calls++;
      },
    )));
    await tester.tap(find.text('طلب حذف الحساب نهائياً'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    expect(find.text('تم تسجيل طلب الحذف'), findsOneWidget);
    await tester.tap(find.text('تم تسجيل طلب الحذف'));
    expect(calls, 1);
  });
}
