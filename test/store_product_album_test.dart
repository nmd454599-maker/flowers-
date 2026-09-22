import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/screens/store/store_product_album.dart';
import 'package:azharna_pro/screens/store/store_products_screen.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';

class AlbumRepository extends DemoRepository {
  List<Product> saved = [];
  bool fail = false;
  @override
  Future<List<Product>> fetchProducts() async {
    if (fail) throw StateError('offline');
    return [...saved];
  }
}

const products = [
  Product(
      id: 'p1',
      storeId: 's1',
      name: 'باقة الورد',
      category: 'ورود',
      price: 25000,
      emoji: '💐',
      rating: 4,
      description: ''),
  Product(
      id: 'p2',
      storeId: 's1',
      name: 'علبة هدية',
      category: 'هدايا',
      price: 30000,
      emoji: '🎁',
      rating: 4,
      description: ''),
];

void main() {
  testWidgets(
      'merchant album excludes other stores and opens existing category in editor',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = AlbumRepository();
    final state = AppState(repository: repository);
    state.user = const AppUser(
        id: 'u1',
        name: 'متجر',
        phone: '07701234567',
        role: UserRole.store,
        storeId: 's1');
    repository.saved = [
      const Product(
          id: 'p1',
          storeId: 's1',
          name: 'نبتة منزلية',
          category: 'النباتات',
          price: 20000,
          emoji: '🌿',
          rating: 4,
          description: ''),
      const Product(
          id: 'p9',
          storeId: 's2',
          name: 'منتج متجر آخر',
          category: 'هدايا',
          price: 30000,
          emoji: '🎁',
          rating: 4,
          description: ''),
    ];
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(), home: StoreProductsScreen(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('منتج متجر آخر'), findsNothing);
    await tester.tap(find.text('تعديل'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل المنتج'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'album reloads after logout and supports retry after load failure',
      (tester) async {
    final repository = AlbumRepository()..saved = products;
    final state = AppState(repository: repository);
    await state.loadCatalog();
    await state.logout();
    expect(state.products, isEmpty);
    await state.requestOtp('07811234567');
    await state.verifyOtp('07811234567', '1234', UserRole.store);
    repository.fail = true;
    await tester
        .pumpWidget(MaterialApp(home: StoreProductsScreen(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('تعذر تحميل المنتجات'), findsOneWidget);
    expect(find.text('ألبوم متجرك فارغ'), findsNothing);
    repository.fail = false;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('2 منتج'), findsOneWidget);
    expect(state.products, hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets(
      'album filters products, enlarges photo and edits selected product',
      (tester) async {
    Product? edited;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
            body: StoreProductAlbum(
                products: products, onAdd: () {}, onEdit: (p) => edited = p))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'باقة');
    await tester.pumpAndSettle();
    expect(find.text('1 منتج'), findsOneWidget);
    expect(find.text('علبة هدية'), findsNothing);
    await tester.tap(find.byIcon(Icons.zoom_in_rounded).first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعديل').first);
    expect(edited?.id, 'p1');
  });

  testWidgets('album fits phone and tablet, large text and both layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 390.0, 900.0]) {
      for (final dark in [false, true]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.4)),
                child: Directionality(
                    textDirection: TextDirection.rtl, child: child!)),
            home: Scaffold(
                body: StoreProductAlbum(
                    products: products, onAdd: () {}, onEdit: (_) {}))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('شبكة'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
