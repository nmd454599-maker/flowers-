import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/color_direction.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/main_color_preview.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  testWidgets('ten coordinated palettes render in light and dark',
      (tester) async {
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
    final state = AppState(repository: DemoRepository());
    await state.loadCatalog();
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final snapshots = <ui.Image>[];
    for (final palette in ColorDirection.values) {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: ColorPreviewApp(
              key: ValueKey(palette),
              state: state,
              initialDirection: palette)));
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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: palette.label);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        snapshots.add(image);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
            'artifacts/color-previews/${palette.number}-${palette.name}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
      await tester.tap(find.byTooltip('الفاتح والداكن'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${palette.label} dark');
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('artifacts/color-previews/${palette.number}-dark.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFFE4E9EC), BlendMode.src);
      for (var i = 0; i < snapshots.length; i++) {
        final x = (4 - i % 5) * 320.0 + 10;
        final y = (i ~/ 5) * 720.0 + 10;
        canvas.drawImageRect(snapshots[i], const Rect.fromLTWH(0, 0, 430, 1000),
            Rect.fromLTWH(x, y, 300, 697.7), Paint());
      }
      final picture = recorder.endRecording();
      final board = await picture.toImage(1600, 1440);
      final bytes = await board.toByteData(format: ui.ImageByteFormat.png);
      await File('artifacts/color-previews/all-ten.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      board.dispose();
      picture.dispose();
      for (final image in snapshots) {
        image.dispose();
      }
    });
  });
}
