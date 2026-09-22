import 'package:azharna_courier/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('courier login is shown before assigned order access', (
    tester,
  ) async {
    await tester.pumpWidget(const CourierApp());
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('طلباتي المسندة'), findsNothing);
  });
}
