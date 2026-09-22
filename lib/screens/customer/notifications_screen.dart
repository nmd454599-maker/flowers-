import 'package:flutter/material.dart';
import '../../data/firebase_repository.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  final AppState state;
  const NotificationsScreen({super.key, required this.state});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<(String, String)>> future = load();
  Future<List<(String, String)>> load() async {
    final state = widget.state;
    final user = state.user;
    final result = <(String, String)>[
      for (final n in state.notifications) (n.title, n.body)
    ];
    if (user == null || state.repository is FirebaseRepository) return result;
    for (final r in await state.repository.fetchAdminRecords('content')) {
      if (r.data['active'] == true)
        result.add(('${r.data['title']}', '${r.data['body']}'));
    }
    for (final record
        in await state.repository.fetchAdminRecords('notifications')) {
      final data = record.data;
      final scheduled = DateTime.tryParse('${data['scheduledFor']}');
      if (scheduled != null && scheduled.isAfter(DateTime.now())) continue;
      final target = data['target'];
      if (target == 'الكل' ||
          user.role == UserRole.superAdmin ||
          (target == 'العملاء' && user.role == UserRole.customer) ||
          (target == 'المتاجر' && user.role == UserRole.store) ||
          (target == 'مدينة محددة' && data['city'] == state.selectedCity)) {
        result.add(('${data['title']}', '${data['body']}'));
      }
    }
    final orders = await state.repository.fetchOrders(
        customerId: user.role == UserRole.customer ? user.id : null,
        storeId: user.role == UserRole.store ? user.storeId : null);
    for (final order in orders) {
      result.add(('طلب ${order.id}', 'الحالة: ${order.status.label}'));
    }
    for (final r
        in await state.repository.fetchAdminRecords('customer_requests')) {
      if (user.role == UserRole.superAdmin || r.data['ownerId'] == user.id) {
        result.add((
          'طلب دعم أو انضمام • ${r.data['name']}',
          '${r.data['reply'] ?? 'بانتظار المراجعة'}'
        ));
      }
    }
    if (user.role == UserRole.store) {
      for (final p in await state.repository.fetchAdminProducts()) {
        if (p.storeId == user.storeId)
          result.add((
            p.name,
            'مراجعة المنتج: ${p.status.name}${p.rejectionReason == null ? '' : '\n${p.rejectionReason}'}'
          ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإشعارات'), actions: [
          IconButton(
              tooltip: 'تحديث',
              onPressed: () => setState(() => future = load()),
              icon: const Icon(Icons.refresh))
        ]),
        body: FutureBuilder<List<(String, String)>>(
            future: future,
            builder: (_, snapshot) {
              if (snapshot.hasError)
                return Center(
                    child: TextButton(
                        onPressed: () => setState(() => future = load()),
                        child: const Text('تعذر التحميل — إعادة المحاولة')));
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.isEmpty)
                return const Center(child: Text('لا توجد إشعارات بعد'));
              return ListView(children: [
                for (final item in snapshot.data!)
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.notifications_none),
                          title: Text(item.$1),
                          subtitle: Text(item.$2)))
              ]);
            }),
      );
}
