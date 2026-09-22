import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/screens/customer/home/product_post_media.dart';

void main() {
  const product = Product(
      id: 'gallery',
      storeId: 'store',
      name: 'باقة',
      category: 'ورد',
      price: 20000,
      emoji: '',
      rating: 5,
      description: '',
      imageUrls: [
        'assets/images/product_bouquet.png',
        'assets/images/product_gift.png'
      ]);
  testWidgets('RTL swipe changes photo and double tap saves without opening',
      (tester) async {
    var opened = 0;
    var saved = 0;
    await tester.pumpWidget(MaterialApp(
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
                body: ProductPostMedia(
                    product: product,
                    onOpen: () => opened++,
                    onSave: () => saved++)))));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byType(PageView));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(saved, 1);
    expect(opened, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(opened, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
