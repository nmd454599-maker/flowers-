import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/color_direction.dart';
import 'package:azharna_pro/core/market_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/screens/customer/store_details_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  testWidgets(
      'Arabic store profile fits phones and opens videos and information',
      (tester) async {
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('Cairo')
          ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf')))
        .load();
    await (FontLoader('NotoNaskhArabic')
          ..addFont(
              rootBundle.load('assets/fonts/NotoNaskhArabic-Variable.ttf')))
        .load();
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      final boundary = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MarketTheme.apply(
              ColorDirection.turquoise.theme(Brightness.light)),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: RepaintBoundary(
              key: boundary,
              child: StoreDetailsScreen(
                  store: state.stores.first, state: state))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('مختارات المتجر'), findsOneWidget);
      if (width == 390) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('artifacts/store-profile-preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(find.text('الصور والفيديوهات'), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('إضافة فيديو'), findsNothing);
      await tester.tap(find.text('عن المتجر'));
      await tester.pumpAndSettle();
      expect(find.text('نبذة عن المتجر'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
