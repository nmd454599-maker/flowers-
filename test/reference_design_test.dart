import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/screens/customer/home_screen.dart';
import 'package:azharna_pro/screens/customer/search_screen.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/widgets/product_card.dart';

void main() {
  testWidgets(
      'reference design fits narrow phones and categories filter the catalog',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    final font = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'));
    await font.load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    for (final width in [320.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: RepaintBoundary(
              key: boundary, child: Scaffold(body: HomeScreen(state: state)))));
      await tester.runAsync(() async {
        for (final file in Directory('assets/images')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png'))) {
          await precacheImage(
              AssetImage(file.path.replaceAll('\\', '/').replaceAll(r'\', '/')),
              boundary.currentContext!);
        }
        for (final photo in [
          'photo_05.png',
          'photo_20.png',
          'photo_02.png',
          'photo_13.png',
          'photo_24.png',
          'photo_07.png'
        ]) {
          await precacheImage(AssetImage('assets/images/catalog/$photo'),
              boundary.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Layout at $width');
      if (width == 390) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('artifacts/reference/home-redesign.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.tap(find.text('ورد وبوكيهات'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'الزهور');
    expect(
        tester
            .widgetList<ProductCard>(find.byType(ProductCard))
            .every((card) => card.product.category == 'الزهور'),
        isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
