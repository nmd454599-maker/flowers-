import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/admin/store_applications_screen.dart';
class ReviewRepository extends DemoRepository {
  Completer<String> result = Completer<String>();
  int calls = 0;
  @override
  Future<List<AdminRecord>> fetchAdminRecords(String scope) async => [AdminRecord(id: 'request', scope: scope, data: const {'name': 'متجر', 'status': 'pending'})];
  @override
  Future<String> saveAdminRecord(String scope, String? id, Map<String, Object?> data) { calls++; return result.future; }
}
void main() {
  testWidgets('review buttons prevent duplicate writes and report invalid map and save failure', (tester) async {
    final repository = ReviewRepository();
    final state = AppState(repository: repository);
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(home: StoreApplicationsScreen(state: state)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض الموقع على الخريطة'));
    await tester.pumpAndSettle();
    expect(find.text('لم يحدد المتجر موقعاً صالحاً بعد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('موافقة ونشر'));
    await tester.pump();
    await tester.tap(find.text('موافقة ونشر'));
    expect(repository.calls, 1);
    repository.result.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('تعذر حفظ القرار، حاول مجدداً'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
