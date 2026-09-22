import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/core/app_theme.dart';
import 'package:azharna_pro/widgets/account_value_sheet.dart';

void main() {
  testWidgets('bottom editor saves trimmed value, cancels and accommodates keyboard', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(),
      home: Builder(builder: (context) => Scaffold(body: TextButton(
        child: const Text('open'), onPressed: () async {
          result = await showModalBottomSheet<String>(context: context,
            isScrollControlled: true, showDragHandle: true,
            builder: (_) => const Directionality(textDirection: TextDirection.rtl,
              child: AccountValueSheet(title: 'نوع الحساب', initialValue: 'عميل ذهبي')));
        },
      )))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  عميل فضي  ');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(result, 'عميل فضي');
    tester.view.resetViewInsets();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
