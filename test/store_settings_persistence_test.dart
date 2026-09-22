import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/store/store_account_screen.dart';

void main() {
  testWidgets(
      'merchant settings add and edit real scoped records across reopening',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = DemoRepository();
    final state = AppState(repository: repo)
      ..user = const AppUser(
          id: 'owner',
          name: 'متجر',
          phone: '07811234567',
          role: UserRole.store,
          storeId: 's1');
    const feature = StoreFeature(
        'المخزون والمواد الخام', 'بيانات المخزون', Icons.inventory);
    Widget screen() => MaterialApp(
        home: StoreFeatureScreen(
            key: UniqueKey(), state: state, feature: feature));
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ورد أحمر');
    await tester.enterText(find.byType(TextField).at(2), 'الكمية: 30');
    await tester.ensureVisible(find.text('حفظ التغييرات'));
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pumpAndSettle();
    var records =
        await repo.fetchAdminRecords('store_feature_المخزون والمواد الخام');
    expect(records, hasLength(1));
    expect(records.single.data['storeId'], 's1');
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        'ورد أحمر');
    await tester.ensureVisible(find.text('إضافة سجل جديد'));
    await tester.tap(find.text('إضافة سجل جديد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ورد أبيض');
    await tester.ensureVisible(find.text('حفظ التغييرات'));
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pumpAndSettle();
    records =
        await repo.fetchAdminRecords('store_feature_المخزون والمواد الخام');
    expect(records, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
