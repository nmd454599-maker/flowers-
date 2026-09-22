import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/core/market_theme.dart';

void main() {
  testWidgets('shared input appearance supports text, dropdown and error', (tester) async {
    await (FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'))).load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        theme: MarketTheme.apply(dark ? AppTheme.dark() : AppTheme.light()),
        home: RepaintBoundary(key: key, child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Padding(padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 30),
              const Text('تفاصيل الحساب', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 30),
              const TextField(decoration: InputDecoration(labelText: 'الاسم الكامل', hintText: 'أدخل اسمك')),
              const SizedBox(height: 26),
              const TextField(obscureText: true, decoration: InputDecoration(labelText: 'كلمة المرور', hintText: '••••••••', suffixIcon: Icon(Icons.visibility_off_outlined))),
              const SizedBox(height: 26),
              DropdownButtonFormField<String>(initialValue: 'بغداد',
                decoration: const InputDecoration(labelText: 'المدينة'),
                items: const [DropdownMenuItem(value: 'بغداد', child: Text('بغداد')), DropdownMenuItem(value: 'البصرة', child: Text('البصرة'))], onChanged: (_) {}),
              const SizedBox(height: 26),
              const TextField(decoration: InputDecoration(labelText: 'رقم الهاتف', hintText: '0770 123 4567', errorText: 'تحقق من رقم الهاتف')),
            ])),
          ),
        )),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'أزهارنا');
      await tester.pumpAndSettle();
      expect(find.text('أزهارنا'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final bitmap = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 2);
        final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        final file = File('artifacts/reference/inputs-${dark ? 'dark' : 'light'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        bitmap.dispose();
      });
    }
  });
}
