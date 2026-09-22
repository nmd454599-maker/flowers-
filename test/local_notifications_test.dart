import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/data/demo_repository.dart';
import 'package:azharna_pro/models/models.dart';
import 'package:azharna_pro/state/app_state.dart';
import 'package:azharna_pro/screens/customer/notifications_screen.dart';

void main() {
  testWidgets('local broadcasts reach selected roles and respect schedules', (tester) async {
    final repo = DemoRepository();
    await repo.saveAdminRecord('notifications', 'customer', {'title': 'رسالة العملاء', 'body': 'نص العميل', 'target': 'العملاء'});
    await repo.saveAdminRecord('notifications', 'merchant', {'title': 'رسالة المتاجر', 'body': 'نص المتجر', 'target': 'المتاجر'});
    await repo.saveAdminRecord('notifications', 'later', {'title': 'رسالة مستقبلية', 'body': 'لاحقًا', 'target': 'الكل', 'scheduledFor': DateTime.now().add(const Duration(days: 1)).toIso8601String()});
    await repo.saveAdminRecord('content', 'published', {'title': 'خبر منشور', 'body': 'للجميع', 'active': true});
    await repo.saveAdminRecord('content', 'hidden', {'title': 'خبر مخفي', 'body': 'مسودة', 'active': false});
    final state = AppState(repository: repo);
    for (final role in [UserRole.customer, UserRole.store]) {
      state.user = AppUser(id: role.name, name: 'فحص', phone: '', role: role, storeId: role == UserRole.store ? 's1' : null);
      await tester.pumpWidget(MaterialApp(home: NotificationsScreen(key: UniqueKey(), state: state)));
      await tester.pumpAndSettle();
      expect(find.text(role == UserRole.customer ? 'رسالة العملاء' : 'رسالة المتاجر'), findsOneWidget);
      expect(find.text(role == UserRole.customer ? 'رسالة المتاجر' : 'رسالة العملاء'), findsNothing);
      expect(find.text('رسالة مستقبلية'), findsNothing);
      expect(find.text('خبر منشور'), findsOneWidget);
      expect(find.text('خبر مخفي'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
