import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/core/market_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/customer/profile_screen.dart';
import 'package:azharna_pro/screens/store/store_shell.dart';
import 'package:azharna_pro/screens/admin/admin_shell.dart';
import 'package:azharna_pro/screens/shared/image_library_screen.dart';

void main() {
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path);
    for (final entry in {
      'Tajawal': [
        'assets/fonts/Tajawal-Regular.ttf',
        'assets/fonts/Tajawal-Bold.ttf'
      ],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
      'packages/cupertino_icons/CupertinoIcons': [
        'packages/cupertino_icons/assets/CupertinoIcons.ttf'
      ]
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final asset in entry.value) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  });
  testWidgets('all account shells fit and their navigation opens actual pages',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final role in [
      UserRole.customer,
      UserRole.store,
      UserRole.superAdmin
    ]) {
      final state = AppState(repository: DemoRepository());
      state.user = AppUser(
          id: 'test-${role.name}',
          name: 'أزهارنا',
          phone: '07701234567',
          role: role,
          storeId: role == UserRole.store ? 's1' : null);
      await state.loadCatalog();
      await state.loadAdminData();
      for (final dark in [false, true]) {
        for (final width in [320.0, 390.0]) {
          tester.view.physicalSize = Size(width, 900);
          final boundary = GlobalKey();
          final screen = switch (role) {
            UserRole.customer => ProfileScreen(state: state),
            UserRole.store => StoreShell(state: state),
            _ => AdminShell(state: state)
          };
          await tester.pumpWidget(MaterialApp(
              debugShowCheckedModeBanner: false,
              theme:
                  MarketTheme.apply(dark ? AppTheme.dark() : AppTheme.light()),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(width == 320 ? 1.6 : 1)),
                  child: Directionality(
                      textDirection: TextDirection.rtl, child: child!)),
              home: RepaintBoundary(key: boundary, child: screen)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '${role.name} $width $dark');
          if (width == 390) {
            await tester.runAsync(() async {
              final image = await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final path = File(
                  'artifacts/all-accounts-design/${role.name}-${dark ? 'dark' : 'light'}.png');
              await path.parent.create(recursive: true);
              await path.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          final navigation = find.byType(NavigationBar);
          if (navigation.evaluate().isNotEmpty) {
            final labels = role == UserRole.store
                ? ['الطلبات', 'البروفايل', 'المتجر', 'الرئيسية']
                : ['المتاجر', 'الطلبات', 'المستخدمون', 'حسابي', 'الرئيسية'];
            for (final label in labels) {
              await tester.tap(find
                  .descendant(of: navigation, matching: find.text(label))
                  .last);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull,
                  reason: '${role.name}/$label/$width/$dark');
            }
          }
          await tester.pumpWidget(const SizedBox());
        }
      }
      state.dispose();
    }
  });
  testWidgets(
      'all bundled images are available and gallery selection returns the asset',
      (tester) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final disk = Directory('assets/images')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => RegExp(r'\.(png|jpe?g|webp)$').hasMatch(f.path))
        .map((f) => f.path.replaceAll('\\', '/'))
        .toList();
    expect(disk.length, greaterThanOrEqualTo(38));
    for (final asset in disk) {
      expect(manifest.listAssets(), contains(asset));
    }
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ImageLibraryScreen(selectImage: true)));
                    },
                    child: const Text('فتح'))))));
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    await tester.tap(find
        .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
        .hitTestable()
        .first);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
    expect(disk, contains(selected));
  });
}
