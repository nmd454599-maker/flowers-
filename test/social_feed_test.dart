import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/screens/customer/customer_shell.dart';
import 'package:azharna_pro/screens/customer/home/product_post.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  setUpAll(() async {
    for (final font in {
      'Tajawal': [
        'assets/fonts/Tajawal-Regular.ttf',
        'assets/fonts/Tajawal-Bold.ttf'
      ],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
      'packages/cupertino_icons/CupertinoIcons': [
        'packages/cupertino_icons/assets/CupertinoIcons.ttf'
      ],
    }.entries) {
      final loader = FontLoader(font.key);
      for (final asset in font.value) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  });

  testWidgets(
      'feed fits RTL phones and tablet with enlarged text in both themes',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0, 768.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 900);
          final boundary = GlobalKey();
          await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                  textDirection: TextDirection.rtl, child: child!),
            ),
            home: RepaintBoundary(
                key: boundary, child: CustomerShell(state: state)),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$width / $scale / $dark');
          if (width == 390 && scale == 1) {
            await tester.runAsync(() async {
              for (final path in [
                'assets/images/catalog/photo_05.png',
                'assets/images/product_bouquet.png',
                'assets/images/product_gift.png',
                'assets/images/product_dessert.png',
                'assets/images/category_beauty.png'
              ]) {
                await precacheImage(AssetImage(path), boundary.currentContext!);
              }
            });
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final image = await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  'artifacts/social-redesign/home-${dark ? 'dark' : 'light'}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.drag(
              find.byType(CustomScrollView).first, const Offset(0, -500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'Scrolled $width / $scale / $dark');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });

  testWidgets(
      'feed favorites cart details and tab navigation remain functional',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: CustomerShell(state: state)));
    await tester.pumpAndSettle();
    final product = state.products.first;
    await tester.tap(find.byTooltip('إضافة إلى المفضلة').first);
    await tester.pumpAndSettle();
    expect(state.favorites, contains(product.id));
    await tester.tap(find.byTooltip('إضافة إلى السلة: ${product.name}').first);
    await tester.pumpAndSettle();
    expect(state.cartCount, 1);
    await tester.tap(find.byTooltip('تفاصيل المنتج').first);
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المفضلة').last);
    await tester.pumpAndSettle();
    expect(find.text(product.name), findsOneWidget);
    await tester.tap(find.text('الرئيسية').last);
    await tester.pumpAndSettle();
    expect(find.byType(ProductPost), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
