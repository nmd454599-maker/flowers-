import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/auth/welcome_screen.dart';
import 'package:azharna_pro/screens/customer/home_screen.dart';
import 'package:azharna_pro/screens/customer/customer_shell.dart';
import 'package:azharna_pro/main.dart';
import 'package:azharna_pro/screens/customer/profile_screen.dart';
import 'package:azharna_pro/screens/customer/search_screen.dart';
import 'package:azharna_pro/screens/customer/cart_screen.dart';
import 'package:azharna_pro/screens/auth/onboarding_screen.dart';
import 'package:azharna_pro/screens/customer/categories_screen.dart';
import 'package:azharna_pro/screens/customer/favorites_screen.dart';
import 'package:azharna_pro/screens/customer/orders_screen.dart';
import 'package:azharna_pro/screens/customer/order_review_screen.dart';
import 'package:azharna_pro/screens/customer/announcements_screen.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';
import 'package:azharna_pro/screens/store/store_dashboard_screen.dart';
import 'package:azharna_pro/screens/store/store_shell.dart';
import 'package:azharna_pro/screens/admin/admin_shell.dart';
import 'package:azharna_pro/screens/admin/admin_tools_screen.dart';
import 'package:azharna_pro/widgets/glass_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
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
  testWidgets('redesigned screens fit phone and tablet in both themes',
      (tester) async {
    final issues = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    state.addToCart(state.products.first);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0, 768.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 1024);
        final screens = <String, Widget>{
          'home': Scaffold(body: HomeScreen(state: state)),
          'welcome': WelcomeScreen(state: state),
          'account': ProfileScreen(state: state),
          'search': SearchScreen(state: state),
          'cart': CartScreen(state: state),
          'onboarding': OnboardingScreen(onComplete: () async {}),
          'categories': CategoriesScreen(state: state),
          'favorites': FavoritesScreen(state: state),
          'orders': OrdersScreen(state: state),
          'review': OrderReviewScreen(
              state: state,
              recipient: 'مستلم الهدية',
              phone: '+9647701234567',
              address: 'بغداد، شارع النخيل، منزل 12',
              schedule: 'أقرب وقت متاح',
              gift: 'كل عام وأنتم بخير'),
          'announcements': AnnouncementsScreen(state: state),
          'product':
              ProductDetailsScreen(state: state, product: state.products.first),
          'store': StoreDashboardScreen(state: state, openTab: (_) {}),
          'admin': AdminToolsScreen(state: state),
        };
        for (final entry in screens.entries) {
          await tester.pumpWidget(MaterialApp(
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              builder: (_, child) => Directionality(
                  textDirection: TextDirection.rtl, child: child!),
              home: entry.value));
          await tester.pumpAndSettle();
          final initialError = tester.takeException();
          if (initialError != null) {
            issues.add('${entry.key}: $width, dark=$dark: $initialError');
          }
          // Also inspect content below the fold, including larger product cards.
          final scroll = find.byType(Scrollable).first;
          await tester.drag(scroll, const Offset(0, -480));
          await tester.pumpAndSettle();
          final scrolledError = tester.takeException();
          if (scrolledError != null) {
            issues.add(
                '${entry.key} scrolled: $width, dark=$dark: $scrolledError');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
    expect(issues, isEmpty);
  });

  testWidgets('existing customer shell opens announcements and account',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: CustomerShell(state: state)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('الإعلانات'));
    await tester.pumpAndSettle();
    expect(find.text('أفكار تُزهر بالفرح'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    expect(find.byType(ThemeModeButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final shell in [StoreShell(state: state), AdminShell(state: state)]) {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: shell));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${shell.runtimeType}');
    }
  });

  testWidgets('appearance selection changes the existing app theme',
      (tester) async {
    AppTheme.mode.value = ThemeMode.light;
    addTearDown(() => AppTheme.mode.value = ThemeMode.system);
    await tester.pumpWidget(const AzharnaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الوضع الداكن'));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark);
    expect(Theme.of(tester.element(find.byType(WelcomeScreen))).brightness,
        Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating tabs preserve local state and expose all destinations',
      (tester) async {
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AnimatedTabBody(index: selected, children: const [
              TextField(key: ValueKey('draft')),
              Text('الخريطة'),
              Text('المحادثات'),
              Text('الإعلانات'),
              Text('حسابي')
            ]),
            bottomNavigationBar: FloatingNavigation(
                selectedIndex: selected,
                onSelected: (value) => setState(() => selected = value),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
                  NavigationDestination(
                      icon: Icon(Icons.map_outlined), label: 'الخريطة'),
                  NavigationDestination(
                      icon: Icon(Icons.chat_outlined), label: 'المحادثات'),
                  NavigationDestination(
                      icon: Icon(Icons.campaign_outlined), label: 'الإعلانات'),
                  NavigationDestination(
                      icon: Icon(Icons.person_outlined), label: 'حسابي')
                ]),
          ),
        )));
    await tester.enterText(find.byType(TextField), 'هدية محفوظة');
    await tester.tap(find.byIcon(Icons.campaign_outlined));
    await tester.pumpAndSettle();
    expect(selected, 3);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('هدية محفوظة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture light and dark home with floating navigation',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: RepaintBoundary(key: key, child: CustomerShell(state: state))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(const AssetImage('assets/images/premium_hero.png'),
            key.currentContext!);
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file =
            File('artifacts/reference/home-${dark ? 'dark' : 'light'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
