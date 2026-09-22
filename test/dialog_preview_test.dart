import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/main_dialog_preview.dart';

void main() {
  testWidgets('export account dialog shape choices', (tester) async {
    await (FontLoader('NotoNaskhArabic')
          ..addFont(
              rootBundle.load('assets/fonts/NotoNaskhArabic-Variable.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 740);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final shape in DialogShape.values) {
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key, child: DialogPreviewApp(initialShape: shape)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('artifacts/dialog-previews/${shape.name}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountDialogSample), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
