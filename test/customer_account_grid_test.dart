import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/customer/profile_screen.dart';
import 'package:azharna_pro/screens/customer/customer_account_screen.dart';

void main() {
  testWidgets('account options fit screens and text sizes and open details',
      (tester) async {
    final state = AppState(repository: DemoRepository());
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 390.0, 768.0]) {
      for (final scale in [1.0, 1.6]) {
        for (final dark in [false, true]) {
          tester.view.physicalSize = Size(width, 844);
          await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                  textDirection: TextDirection.rtl, child: child!),
            ),
            home: ProfileScreen(state: state),
          ));
          await tester.pumpAndSettle();
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          expect(tester.takeException(), isNull);
          while (position.pixels < position.maxScrollExtent) {
            position.jumpTo(
                (position.pixels + 450).clamp(0, position.maxScrollExtent));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'width=$width scale=$scale dark=$dark');
          }
          expect(find.text('حذف الحساب'), findsOneWidget);
          position.jumpTo(0);
          await tester.pumpAndSettle();
          await tester.tap(find.text('مستوى العضوية'));
          await tester.pumpAndSettle();
          expect(find.byType(CustomerAccountScreen), findsOneWidget);
          expect(find.text('نوع الحساب'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });
}
