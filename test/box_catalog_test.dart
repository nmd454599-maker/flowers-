import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/main_box_catalog.dart';

void main() {
  testWidgets('render twelve box options together', (tester) async {
    await (FontLoader('NotoNaskhArabic')
          ..addFont(
              rootBundle.load('assets/fonts/NotoNaskhArabic-Variable.ttf')))
        .load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 1630);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final key = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: key, child: const BoxCatalogApp()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BoxChoice), findsNWidgets(12));
    await tester.runAsync(() async {
      final image = await (key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary)
          .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('artifacts/dialog-previews/twelve-options.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
