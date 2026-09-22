import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:azharna_pro/core/market_theme.dart';
import 'package:azharna_pro/core/color_direction.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/store/store_account_screen.dart';
import 'package:azharna_pro/screens/store/store_dashboard_screen.dart';
import 'package:azharna_pro/screens/store/store_profile_screen.dart';
import 'package:azharna_pro/screens/store/store_shell.dart';
import 'package:azharna_pro/screens/store/store_products_screen.dart';
import 'package:azharna_pro/widgets/store_profile_photo.dart';
import 'package:azharna_pro/widgets/store_media_photos.dart';
import 'package:azharna_pro/screens/shared/store_chat_screen.dart';
import 'package:azharna_pro/screens/store/store_videos_panel.dart';
import 'package:azharna_pro/screens/customer/store_details_screen.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf')))
        .load();
  });
  Future<AppState> catalog() async {
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    return state;
  }

  testWidgets('merchant settings stay complete and profile opens independently',
      (tester) async {
    final state = await catalog();
    state.user = AppUser(
        id: 'owner',
        name: 'Owner',
        phone: '07700000000',
        role: UserRole.store,
        storeId: state.stores.first.id);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
        theme:
            MarketTheme.apply(ColorDirection.turquoise.theme(Brightness.light)),
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: StoreAccountScreen(state: state))));
    await tester.pumpAndSettle();
    expect(find.byType(StoreDetailsScreen), findsNothing);
    expect(find.byType(StoreSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'settings');
    await tester.scrollUntilVisible(find.text('الدعم والإعدادات'), 450,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('الدعم والإعدادات'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(
        theme:
            MarketTheme.apply(ColorDirection.turquoise.theme(Brightness.light)),
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: StoreDashboardScreen(state: state, openTab: (_) {}))));
    await tester.pumpAndSettle();
    expect(find.text('بروفايل المتجر'), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator)).push(
        MaterialPageRoute<void>(
            builder: (_) => StoreProfileScreen(state: state)));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProfileScreen), findsOneWidget);
    expect(find.byType(StoreDetailsScreen), findsOneWidget);
    expect(find.text('مختارات المتجر'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الصور والفيديوهات'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreVideosPanel), findsOneWidget);
    expect(find.text('إضافة فيديو'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'videos');
    Navigator.of(tester.element(find.byType(StoreProfileScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(StoreProfileScreen), findsNothing);
    expect(find.text('لوحة المتجر'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'merchant profile tab replaces products and management remains reachable',
      (tester) async {
    final state = await catalog();
    state.user = AppUser(
        id: 'owner',
        name: 'Owner',
        phone: '07700000000',
        role: UserRole.store,
        storeId: state.stores.first.id);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
        theme:
            MarketTheme.apply(ColorDirection.turquoise.theme(Brightness.light)),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: StoreShell(state: state)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('البروفايل'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProfileScreen), findsOneWidget);
    expect(find.byType(StoreDetailsScreen), findsOneWidget);
    expect(find.byType(StoreProductsScreen), findsNothing);
    await tester.scrollUntilVisible(find.byType(StoreMediaPhotos), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(StoreMediaPhotos), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(StoreVideosPanel), 250,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<StoreVideosPanel>(find.byType(StoreVideosPanel))
            .showManagement,
        isFalse);
    expect(find.text('المحادثات'), findsOneWidget);
    expect(find.text('محادثة'), findsNothing);
    expect(find.text('صورة المتجر'), findsNothing);
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('تغيير صورة المتجر'));
    await tester.tap(find.byTooltip('تغيير صورة المتجر'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProfilePhoto), findsOneWidget);
    Navigator.of(tester.element(find.byType(StoreProfilePhoto))).pop();
    await tester.pumpAndSettle();
    expect(find.text('صور وفيديوهات المتجر'), findsNothing);
    await tester.tap(find.text('الصور والفيديوهات'));
    await tester.pumpAndSettle();
    expect(find.text(state.stores.first.name), findsNothing);
    expect(find.byTooltip('تغيير صورة المتجر'), findsNothing);
    expect(find.text('رفع صور المنتجات'), findsOneWidget);
    expect(find.byType(StoreMediaPhotos), findsOneWidget);
    await tester.tap(find.text('رفع صور المنتجات'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProductsScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(StoreProductsScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('الصور والفيديوهات'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreVideosPanel), findsOneWidget);
    expect(find.text('إضافة فيديو'), findsOneWidget);
    await tester.tap(find.text('المحادثات'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreChatInboxScreen), findsOneWidget);
    expect(find.text('محادثات العملاء'), findsOneWidget);
    await tester.tap(find.text('عن المتجر'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل معلومات المتجر'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('إعدادات المتجر'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreSettingsScreen), findsOneWidget);
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('إضافة منتج'), 250,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.text('إضافة منتج')),
        alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة منتج'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProductsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('product opens its own store profile', (tester) async {
    final state = await catalog();
    final product = state.products.first;
    await tester.pumpWidget(MaterialApp(
        home: ProductDetailsScreen(product: product, state: state)));
    await tester.pumpAndSettle();
    final link = find.text('زيارة المتجر • المنتجات والفيديوهات');
    await tester.scrollUntilVisible(link, 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<StoreDetailsScreen>(find.byType(StoreDetailsScreen))
            .store
            .id,
        product.storeId);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
