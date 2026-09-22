import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/customer/profile_screen.dart';
import 'package:azharna_pro/screens/customer/cart_screen.dart';

void main() {
  testWidgets('account cart stays accessible empty and uses the current basket', (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(),
      home: Directionality(textDirection: TextDirection.rtl,
        child: ProfileScreen(state: state))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('سلة التسوق'));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
    expect(tester.widget<CartScreen>(find.byType(CartScreen)).state, same(state));
    expect(find.text('سلة التسوق (0)'), findsOneWidget);
    Navigator.of(tester.element(find.byType(CartScreen))).pop();
    state.addToCart(state.products.first);
    await tester.pumpAndSettle();
    final badge = tester.widget<Badge>(find.descendant(
      of: find.byTooltip('سلة التسوق'), matching: find.byType(Badge)));
    expect(badge.isLabelVisible, isTrue);
    expect((badge.label as Text).data, '1');
    await tester.ensureVisible(find.text('سلة التسوق'));
    await tester.tap(find.text('سلة التسوق'));
    await tester.pumpAndSettle();
    expect(find.text('سلة التسوق (1)'), findsOneWidget);
    expect(state.cartCount, 1);
    expect(tester.takeException(), isNull);
  });
}
