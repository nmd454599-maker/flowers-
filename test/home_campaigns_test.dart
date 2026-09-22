import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/screens/customer/home/home_campaigns.dart';
import 'package:azharna_pro/screens/customer/home/home_content.dart';

void main() {
  Future<void> showStrip(WidgetTester tester,
      {bool reduceMotion = false,
      double textScale = 1,
      ValueChanged<String>? onSearch}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: HomeCampaigns(onSearch: onSearch ?? (_) {}),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 16));
  }

  testWidgets('compact strip advances in steps, rests and pauses on touch',
      (tester) async {
    await showStrip(tester);
    expect(tester.getSize(find.byType(HomeCampaigns)).height, 104);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final start = position.pixels;
    await tester.pump(const Duration(seconds: 2));
    expect(position.pixels, start);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(position.pixels, 320);
    await tester.pump(const Duration(seconds: 1));
    expect(position.pixels, 320);
    final touch = await tester.startGesture(const Offset(200, 50));
    final paused = position.pixels;
    await tester.pump(const Duration(seconds: 3));
    expect(position.pixels, paused);
    await touch.up();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(position.pixels, greaterThan(paused));
    // Crossing the loop boundary keeps the scroll in a single cycle.
    position.jumpTo(homeCategories.length * 320.0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(position.pixels, 320);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('every category is reachable and opens its search',
      (tester) async {
    String? query;
    await showStrip(tester,
        reduceMotion: true, onSearch: (value) => query = value);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    for (var i = 0; i < homeCategories.length; i++) {
      position.jumpTo((i * 320.0).clamp(0, position.maxScrollExtent));
      await tester.pump();
      await tester.tap(find.text(homeCategories[i].title));
      expect(query, homeCategories[i].query);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('strip moves when phone transition animations are disabled',
      (tester) async {
    await showStrip(tester, reduceMotion: true);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final start = position.pixels;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(position.pixels, greaterThan(start));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('large Arabic text fits the compact cards', (tester) async {
    await showStrip(tester, reduceMotion: true, textScale: 2);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    for (var i = 0; i < homeCategories.length; i++) {
      position.jumpTo((i * 320.0).clamp(0, position.maxScrollExtent));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
