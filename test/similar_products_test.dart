import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

Product item(String id, {String category = 'الزهور', String store = 's1'}) =>
    Product(
        id: id,
        storeId: store,
        name: 'منتج $id',
        category: category,
        price: 10000,
        emoji: '',
        rating: 4.5,
        description: 'تفاصيل المنتج');

void main() {
  Future<void> show(
      WidgetTester tester, AppState state, Product selected) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProductDetailsScreen(product: selected, state: state))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'all matching products from every store appear without the selected product',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    addTearDown(state.dispose);
    final selected = item('selected');
    state.products = [
      selected,
      item('unrelated', category: 'العطور'),
      for (var i = 0; i < 12; i++)
        item('match$i', category: ' الزهور ', store: i.isEven ? 's1' : 's2')
    ];
    await show(tester, state, selected);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('similar-match0')), 450,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final grid = tester
        .widget<SliverGrid>(find.byKey(const ValueKey('similar-products')));
    expect(grid.delegate.estimatedChildCount, 12);
    expect(find.byKey(const ValueKey('similar-selected')), findsNothing);
    expect(find.byKey(const ValueKey('similar-unrelated')), findsNothing);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('similar-match11')), 450,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('منتج match11'));
    await tester.tap(find.text('منتج match11'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ProductDetailsScreen>(find.byType(ProductDetailsScreen))
            .product
            .id,
        'match11');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a category with no alternatives displays an empty message',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    addTearDown(state.dispose);
    final selected = item('selected');
    state.products = [selected, item('other', category: 'العطور')];
    await show(tester, state, selected);
    await tester.scrollUntilVisible(
        find.text('لا توجد منتجات مشابهة متاحة حالياً'), 450,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const ValueKey('similar-products')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
