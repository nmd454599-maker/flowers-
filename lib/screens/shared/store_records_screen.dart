import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

/// Reads operational records shared by the merchant and administrator.
class StoreRecordsScreen extends StatefulWidget {
  const StoreRecordsScreen(
      {super.key, required this.state, required this.title, this.storeId});
  final AppState state;
  final String title;
  final String? storeId;
  @override
  State<StoreRecordsScreen> createState() => _StoreRecordsScreenState();
}

class _StoreRecordsScreenState extends State<StoreRecordsScreen> {
  late Future<List<(String, String)>> future = load();
  Future<List<(String, String)>> load() async {
    final repo = widget.state.repository;
    final id = widget.storeId;
    if (widget.title == 'المالية والتسويات') {
      return [
        for (final s in await repo.fetchStoreSettlements())
          if (id == null || s.storeId == id)
            (
              '${s.storeId} • ${s.netAmount} د.ع',
              'الحالة: ${s.status.name}\nمرجع التحويل: ${s.transferReference ?? '—'}'
            )
      ];
    }
    if (widget.title == 'حالة التوثيق') {
      return [
        for (final s in await repo.fetchAdminStores())
          if (id == null || s.id == id) (s.name, 'الحالة: ${s.status.name}')
      ];
    }
    if (widget.title == 'سجل النشاط والأمان') {
      return [
        for (final a in await repo.fetchAdminAuditLogs())
          if (id == null ||
              a.targetId == id ||
              a.actorId == widget.state.user?.id ||
              a.details['storeId'] == id)
            (a.action, '${a.targetId}\n${a.createdAt ?? ''}')
      ];
    }
    if (widget.title == 'التقييمات وجودة الخدمة') {
      return [
        for (final r in await repo.fetchAdminRecords('store_reviews'))
          if (id == null || r.data['storeId'] == id)
            (
              '${r.data['customerName']} • ${r.data['rating']} / 5',
              '${r.data['comment']}'
            )
      ];
    }
    if (widget.title == 'سجلات المتاجر') {
      final result = <(String, String)>[];
      for (final scope in [
        'store_payout_methods',
        'store_settings',
        for (final title in [
          'وثائق التحقق',
          'الفروع وساعات العمل',
          'مناطق ورسوم التوصيل',
          'العطل والإغلاق المؤقت',
          'المخزون والمواد الخام',
          'الموردون وأوامر الشراء',
          'الموظفون والصلاحيات',
          'جدولة الطلبات والطاقة',
          'الباقات والتخصيص'
        ])
          'store_feature_$title'
      ]) {
        for (final r in await repo.fetchAdminRecords(scope)) {
          result.add((
            '${r.data['title'] ?? scope} • ${r.data['storeId'] ?? ''}',
            r.data.entries
                .where((e) => !['ownerId'].contains(e.key))
                .map((e) => '${e.key}: ${e.value}')
                .join('\n')
          ));
        }
      }
      return result;
    }
    final orders = (await repo.fetchAdminOrders())
        .where((o) => id == null || o.storeIds.contains(id))
        .toList();
    return [
      ('عدد الطلبات', '${orders.length}'),
      for (final o in orders)
        ('${o.id} • ${o.status.label}', '${o.total} د.ع\n${o.address}'),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: [
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
                return const Center(child: Text('لا توجد سجلات بعد'));
              return ListView(children: [
                for (final row in snapshot.data!)
                  Card(
                      child:
                          ListTile(title: Text(row.$1), subtitle: Text(row.$2)))
              ]);
            }),
      );
}
