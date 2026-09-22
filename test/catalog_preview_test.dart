import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/color_direction.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/main_catalog_preview.dart';
import 'package:azharna_pro/widgets/catalog_layout.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';
import 'package:azharna_pro/screens/customer/categories_screen.dart';

void main() {
  testWidgets('default categories use three columns and retain search',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
        theme: ColorDirection.turquoise.theme(Brightness.light),
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: CategoriesScreen(state: state, layout: null))));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CatalogProductView>(find.byType(CatalogProductView))
            .layout,
        CatalogLayout.dense);
    expect(
        (tester.widget<GridView>(find.byType(GridView)).gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        3);
    await tester.enterText(find.byType(TextField), 'لايوجدمنتجباسمهذا');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  setUpAll(() async {
    await (FontLoader('NotoNaskhArabic')
          ..addFont(
              rootBundle.load('assets/fonts/NotoNaskhArabic-Variable.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });
  testWidgets('export six catalog layouts', (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final images = <ui.Image>[];
    for (final layout in CatalogLayout.values) {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: CatalogPreviewApp(
              key: ValueKey(layout), state: state, initialLayout: layout)));
      await tester.runAsync(() async {
        for (final file in Directory('assets/images/catalog')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png'))) {
          await precacheImage(
              AssetImage(file.path.replaceAll('\\', '/')), key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: layout.label);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        images.add(image);
        final file = File('artifacts/catalog-previews/${layout.name}.png');
        await file.parent.create(recursive: true);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawColor(const Color(0xFFE2E8EC), BlendMode.src);
      for (var i = 0; i < images.length; i++) {
        canvas.drawImage(images[i],
            Offset((2 - i % 3) * 380.0 + 10, (i ~/ 3) * 920.0 + 10), Paint());
      }
      final picture = recorder.endRecording();
      final board = await picture.toImage(1140, 1840);
      final bytes = await board.toByteData(format: ui.ImageByteFormat.png);
      await File('artifacts/catalog-previews/all-six.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      board.dispose();
      picture.dispose();
      for (final image in images) {
        image.dispose();
      }
    });
  });

  testWidgets('all layouts keep favorites cart and product details working',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    final product = state.products.first;
    for (final layout in CatalogLayout.values) {
      await tester.pumpWidget(MaterialApp(
          theme: ColorDirection.turquoise.theme(Brightness.light),
          home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                  body: CatalogProductView(
                      items: [product], state: state, layout: layout)))));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('إضافة إلى المفضلة'));
      expect(state.favorites, contains(product.id));
      await tester.tap(find.byTooltip('إضافة إلى السلة: ${product.name}'));
      expect(state.cartCount, layout.index + 1);
      await tester.tap(find.text(product.name));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailsScreen), findsOneWidget);
      state.toggleFavorite(product);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
