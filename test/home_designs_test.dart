import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/home_design.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/main_design_preview.dart';
import 'package:azharna_pro/screens/customer/home/design_home.dart';
import 'package:azharna_pro/screens/customer/search_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
    for (final font in ['Tajawal', 'IBMPlexSansArabic']) {
      await (FontLoader(font)
            ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/$font-Bold.ttf')))
          .load();
    }
  });
  testWidgets('all compositions fit RTL phones and tablets in both modes',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final design in HomeDesign.values) {
      for (final brightness in Brightness.values) {
        for (final width in [320.0, 390.0, 768.0, 1200.0]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpWidget(MaterialApp(
              theme: design.theme(brightness),
              home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                      body: DesignHome(
                          key: UniqueKey(), state: state, design: design)))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$design $brightness $width initial');
          final scroll = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          for (int step = 0; step < 5; step++) {
            scroll
                .jumpTo((scroll.pixels + 650).clamp(0, scroll.maxScrollExtent));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: '$design $brightness $width scroll $step');
          }
        }
      }
    }
  });

  testWidgets(
      'comparison retains cart and favorites and search navigation works',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    state.addToCart(state.products.first);
    state.toggleFavorite(state.products.first);
    await tester.pumpWidget(DesignPreviewApp(state: state));
    await tester.pumpAndSettle();
    for (final design in HomeDesign.values) {
      await tester.tap(find.text(design.label));
      await tester.pumpAndSettle();
      expect(tester.widget<DesignHome>(find.byType(DesignHome)).design, design);
      expect(state.cartCount, 1);
      expect(state.favorites, contains(state.products.first.id));
    }
    await tester.tap(find.byKey(const ValueKey('design-search')));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('export four phone previews', (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: DesignPreviewApp(state: state)));
    await tester.pumpAndSettle();
    for (final design in HomeDesign.values) {
      await tester.ensureVisible(find.text(design.label));
      await tester.tap(find.text(design.label));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts/home-designs').create(recursive: true);
        await File('artifacts/home-designs/design-${design.name}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
