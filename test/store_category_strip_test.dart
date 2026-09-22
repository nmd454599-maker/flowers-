import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/customer/store_details_screen.dart';
import 'package:azharna_pro/widgets/store_category_strip.dart';
import 'package:azharna_pro/widgets/store_profile_photos.dart';

void main() {
  testWidgets(
      'store categories filter its products and all restores the catalog',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final store = state.stores.first;
    final products =
        state.products.where((p) => p.storeId == store.id).toList();
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: StoreDetailsScreen(store: store, state: state),
    ));
    await tester.pumpAndSettle();
    final strip = find.byType(StoreCategoryStrip);
    final category = products.last.category;
    expect(tester.widget<StoreCategoryStrip>(strip).products,
        everyElement(predicate((dynamic p) => p.storeId == store.id)));
    final categoryLabel =
        find.descendant(of: strip, matching: find.text(category));
    await tester.ensureVisible(categoryLabel);
    await tester.tap(categoryLabel);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(StoreProfilePhotos), 150,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<StoreProfilePhotos>(find.byType(StoreProfilePhotos))
            .products
            .every((p) => p.category == category),
        isTrue);
    await tester.ensureVisible(
        find.descendant(of: strip, matching: find.text('كل الأصناف')));
    await tester
        .tap(find.descendant(of: strip, matching: find.text('كل الأصناف')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<StoreProfilePhotos>(find.byType(StoreProfilePhotos))
            .products
            .length,
        products.length);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    for (final scale in [1.0, 1.8]) {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
                body: StoreCategoryStrip(
                    products: products,
                    selectedCategory: null,
                    onSelected: (_) {}))),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
