import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/core/font_options.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/main_font_preview.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  testWidgets('original layout previews four fonts and retains cart',
      (tester) async {
    for (final family in fontOptions.keys) {
      final variable = family == 'Cairo' || family == 'NotoNaskhArabic';
      final loader = FontLoader(family)
        ..addFont(rootBundle.load(
            'assets/fonts/$family-${variable ? 'Variable' : 'Regular'}.ttf'));
      if (!variable) {
        loader.addFont(rootBundle.load('assets/fonts/$family-Bold.ttf'));
      }
      await loader.load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    addTearDown(() {
      AppTheme.font.value = AppTheme.defaultFont;
      AppTheme.mode.value = ThemeMode.system;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey();
    await tester.pumpWidget(
        RepaintBoundary(key: key, child: FontPreviewApp(state: state)));
    await tester.runAsync(() async {
      for (final asset in [
        'premium_hero.png',
        'product_gift.png',
        'product_red_roses.png',
        'product_dessert.png',
        'product_bouquet.png',
        'category_beauty.png'
      ]) {
        await precacheImage(
            AssetImage('assets/images/$asset'), key.currentContext!);
      }
    });
    for (final font in fontOptions.entries) {
      await tester.ensureVisible(find.text(font.value));
      await tester.tap(find.text(font.value));
      await tester.pumpAndSettle();
      expect(AppTheme.font.value, font.key);
      expect(tester.takeException(), isNull, reason: font.key);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('artifacts/font-previews/${font.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    state.addToCart(state.products.first);
    for (final font in fontOptions.keys) {
      AppTheme.font.value = font;
      await tester.pumpAndSettle();
      expect(state.cartCount, 1);
    }
  });
}
