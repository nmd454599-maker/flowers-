import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/screens/auth/welcome_screen.dart';
import 'package:azharna_pro/state/app_state.dart';

void main() {
  testWidgets('capture redesigned welcome in both appearances', (tester) async {
    await (FontLoader('NotoNaskhArabic')
          ..addFont(rootBundle.load('assets/fonts/NotoNaskhArabic-Variable.ttf')))
        .load();
    await (FontLoader('IBMPlexSansArabic')
          ..addFont(
              rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(repository: DemoRepository());
    for (final dark in [false, true]) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: RepaintBoundary(key: key, child: WelcomeScreen(state: state)),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      final beforeDrag = tester.getTopLeft(find.byType(FilledButton));
      await tester.drag(find.text('أهلاً بعودتك'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(FilledButton)), beforeDrag);
      await tester.runAsync(() async {
        final bitmap = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
            'artifacts/reference/welcome-new-${dark ? 'dark' : 'light'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
      await tester.tap(find.widgetWithText(TextButton, 'إنشاء حساب').first);
      await tester.pumpAndSettle();
      expect(find.text('أنشئ حسابك'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final bitmap = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary).toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        await File('artifacts/reference/register-new-${dark ? 'dark' : 'light'}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
      await tester.tap(find.widgetWithText(TextButton, 'تسجيل الدخول').first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final inputState = tester.state<EditableTextState>(find.byType(EditableText));
    expect(inputState.widget.focusNode.hasFocus, isTrue);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.state<EditableTextState>(find.byType(EditableText)), same(inputState));
    expect(inputState.widget.focusNode.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), '07701234567');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.getRect(find.byType(FilledButton)).bottom, lessThanOrEqualTo(328));
  });
}
