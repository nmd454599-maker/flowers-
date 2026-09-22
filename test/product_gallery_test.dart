import 'dart:io';
import 'dart:typed_data';
import 'package:azharna_pro/services/local_product_images.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:azharna_pro/data/sqlite_repository.dart';
import 'package:azharna_pro/data/local/database_schema.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/widgets/product_image_gallery.dart';
import 'package:azharna_pro/screens/customer/product_details_screen.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/core/color_direction.dart';
import 'package:azharna_pro/core/market_theme.dart';
import 'account_database_test.dart' show RecordingDatabase;

class PhotoDatabase implements Database {
  Map<String, Object?> row = {};
  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    row = Map.of(values);
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(String table,
          {bool? distinct,
          List<String>? columns,
          String? where,
          List<Object?>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset}) async =>
      [row];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class PhotoRepository extends SqliteRepository {
  PhotoRepository(this.database);
  final Database database;
  @override
  Database get db => database;
}

const product = Product(
    id: 'p1',
    storeId: 's1',
    name: 'باقة ورد مميزة',
    category: 'ورود',
    price: 45000,
    emoji: '',
    rating: 4.8,
    description: 'باقة ورد بتغليف أنيق',
    imageUrl: 'assets/images/catalog/photo_05.png',
    imageUrls: [
      'assets/images/catalog/photo_05.png',
      'assets/images/catalog/photo_20.png',
      'assets/images/catalog/photo_13.png'
    ]);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'local image remains readable without storing image bytes in product row',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('product-gallery-test-');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    try {
      final url = await PhotoRepository(PhotoDatabase()).saveProductImage(
          storeId: 's1',
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'photo.png');
      expect(url, startsWith('file:'));
      expect(await File.fromUri(Uri.parse(url)).readAsBytes(), [1, 2, 3]);
      expect(localProductImage(url), isNotNull);
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    }
  });
  test('gallery order persists and legacy photo survives additive migration',
      () async {
    final database = PhotoDatabase();
    await PhotoRepository(database).saveProduct(product);
    expect((await PhotoRepository(database).fetchProducts()).single.photos,
        product.photos);
    database.row.remove('image_urls');
    expect((await PhotoRepository(database).fetchProducts()).single.photos,
        [product.imageUrl]);
    final migration = RecordingDatabase();
    await DatabaseSchema.upgrade(migration, 6, 7);
    expect(migration.statements,
        ['ALTER TABLE products ADD COLUMN image_urls TEXT']);
  });
  testWidgets('RTL thumbnails select photos and swipe stays synchronized',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
                body: SizedBox(
                    width: 320,
                    child: ProductImageGallery(product: product))))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('product-thumbnail-2')));
    await tester.pumpAndSettle();
    final page = tester
        .widget<PageView>(find.byKey(const ValueKey('product-photo-pages')));
    expect(page.controller!.page, 2);
    await tester.drag(find.byKey(const ValueKey('product-photo-pages')),
        const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(page.controller!.page, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'product detail fits phone widths and fixed quantity adds correct amount',
      (tester) async {
    for (final font in ['Tajawal', 'Cairo', 'NotoNaskhArabic']) {
      final file =
          font == 'Tajawal' ? 'Tajawal-Regular.ttf' : '$font-Variable.ttf';
      await (FontLoader(font)..addFont(rootBundle.load('assets/fonts/$file')))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    final state = AppState(repository: DemoRepository());
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
              child: ProductDetailsScreen(product: product, state: state))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      if (width == 390) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('artifacts/product-gallery-preview.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byTooltip('زيادة الكمية'));
      await tester.pumpAndSettle();
      expect(find.textContaining('90000'), findsOneWidget);
      final before = state.cartCount;
      await tester.tap(find.textContaining('أضف إلى السلة'));
      expect(state.cartCount, before + 2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
