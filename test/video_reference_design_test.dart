import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/color_direction.dart';

import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/screens/customer/customer_shell.dart';
import 'package:azharna_pro/screens/customer/home_screen.dart';
import 'package:azharna_pro/widgets/glass_panel.dart';
import 'package:azharna_pro/screens/customer/profile_screen.dart';
import 'package:azharna_pro/screens/customer/favorites_screen.dart';
import 'package:azharna_pro/screens/customer/categories_screen.dart';
import 'package:azharna_pro/screens/customer/cart_screen.dart';
import 'package:azharna_pro/screens/customer/orders_screen.dart';
import 'package:azharna_pro/screens/customer/search_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path);
    await (FontLoader('IBMPlexSansArabic')
          ..addFont(
              rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(rootBundle
              .load('packages/cupertino_icons/assets/CupertinoIcons.ttf')))
        .load();
  });

  Widget app(AppState state,
          {Brightness brightness = Brightness.light,
          double scale = 1,
          Widget? home}) =>
      MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ColorDirection.turquoise.theme(brightness),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                  textDirection: TextDirection.rtl, child: child!)),
          home: home ?? CustomerShell(state: state));

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
      'classic layout fits phones, enlarged Arabic, dark mode and tablet',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final (width, scale, brightness) in [
      (320.0, 1.0, Brightness.light),
      (390.0, 2.0, Brightness.light),
      (390.0, 1.0, Brightness.dark),
      (768.0, 1.0, Brightness.light),
    ]) {
      tester.view.physicalSize = Size(width, 850);
      await tester.pumpWidget(app(state,
          brightness: brightness,
          scale: scale,
          home: Scaffold(body: HomeScreen(key: UniqueKey(), state: state))));
      await frames(tester);
      expect(tester.takeException(), isNull, reason: 'initial $width / $scale');
      final scroll =
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      while (scroll.pixels < scroll.maxScrollExtent) {
        scroll.jumpTo((scroll.pixels + 550).clamp(0, scroll.maxScrollExtent));
        await frames(tester);
        expect(tester.takeException(), isNull,
            reason: 'scroll $width / $scale');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('export reference views and verify search and account navigation',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: app(state)));
    await frames(tester);
    Future<void> capture(String name) => tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('artifacts/classic-restored').create(recursive: true);
          await File('artifacts/classic-restored/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
    await capture('azharna-home');
    final cartButton = find.byTooltip('السلة');

    await tester.tap(cartButton);
    await frames(tester);
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('سلة التسوق (0)'), findsOneWidget);
    Navigator.of(tester.element(find.byType(CartScreen))).pop();
    await tester.pumpAndSettle();
    await frames(tester);
    await tester.tap(find.text('ابحث عن هدية أو متجر'));
    await frames(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SearchScreen))).pop();
    await frames(tester);
    final navigation = find.byType(FloatingNavigation);
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('حسابي')));
    await frames(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);

    await capture('azharna-profile');
    for (final (label, type) in [
      ('المفضلة', FavoritesScreen),
      ('التصنيفات', CategoriesScreen),
      ('الطلبات', OrdersScreen),
    ]) {
      await tester
          .tap(find.descendant(of: navigation, matching: find.text(label)));
      await frames(tester);
      expect(find.byType(type), findsOneWidget);
    }
    await tester
        .tap(find.descendant(of: navigation, matching: find.text('الرئيسية')));
    await frames(tester);
    final scroll =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    scroll.jumpTo(620);
    await frames(tester);
    state.addToCart(state.products.first);
    await frames(tester);

    await tester.tap(find.byType(FloatingActionButton).last);
    await frames(tester);
    expect(find.text('سلة التسوق (1)'), findsOneWidget);
    Navigator.of(tester.element(find.byType(CartScreen))).pop();
    await tester.pumpAndSettle();
    await frames(tester);
    await capture('azharna-catalog');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
