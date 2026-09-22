import 'package:flutter/material.dart';
import '../../data/firebase_repository.dart';
import '../../data/sqlite_repository.dart';
import '../../state/app_state.dart';

class CustomerRequestsScreen extends StatefulWidget {
  final AppState state;
  const CustomerRequestsScreen({super.key, required this.state});
  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {
  late Future<List<Map<String, Object?>>> future = load();
  Future<List<Map<String, Object?>>> load() async {
    final repo = widget.state.repository;
    if (repo is FirebaseRepository) {
      final docs = await repo.firestore.collection('customerRequests').get();
      return docs.docs
          .map((d) => <String, Object?>{...d.data(), 'id': d.id})
          .toList();
    }
    return (await repo.fetchAdminRecords('customer_requests'))
        .map((r) => <String, Object?>{...r.data, 'id': r.id})
        .toList();
  }

  Future<void> reply(Map<String, Object?> request) async {
    final value = await showDialog<String>(
        context: context, builder: (_) => const _ReplyDialog());
    if (value == null || !mounted) return;
    try {
      final repo = widget.state.repository;
      if (repo is FirebaseRepository) {
        await repo.firestore
            .collection('customerRequests')
            .doc(request['id'] as String)
            .update({'reply': value, 'status': 'replied'});
      } else {
        final data = {
          ...request,
          'reply': value,
          'status': ['approved', 'rejected'].contains(request['status'])
              ? request['status']
              : 'replied'
        }..remove('id');
        await repo.saveAdminRecord(
            'customer_requests', request['id'] as String, data);
      }
      if (mounted) setState(() => future = load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر إرسال الرد')));
      }
    }
  }

  Future<void> review(Map<String, Object?> request, bool approve) async {
    try {
      await (widget.state.repository as SqliteRepository)
          .reviewJoinRequest(request['id'] as String, approve);
      if (mounted) setState(() => future = load());
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('طلبات العملاء والانضمام')),
      body: FutureBuilder<List<Map<String, Object?>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: TextButton(
                      onPressed: () => setState(() => future = load()),
                      child: const Text('تعذر التحميل • إعادة المحاولة')));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('لا توجد طلبات'));
            }
            return RefreshIndicator(
                onRefresh: () async {
                  setState(() => future = load());
                  await future;
                },
                child: ListView(children: [
                  for (final r in snapshot.data!)
                    Card(
                        child: ListTile(
                      title: Text(
                          '${r['name']} • ${r['kind'] == 'support' ? 'دعم' : r['kind'] == 'store' ? 'متجر' : 'مندوب'}'),
                      subtitle: Text(
                          '${r['phone']}\n${(r['fields'] as Map).values.join('\n')}\n${r['reply'] ?? 'بانتظار الرد'}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (widget.state.repository is SqliteRepository &&
                            ['store', 'courier'].contains(r['kind']) &&
                            !['approved', 'rejected']
                                .contains(r['status'])) ...[
                          IconButton(
                              tooltip: 'قبول الانضمام',
                              onPressed: () => review(r, true),
                              icon: const Icon(Icons.check)),
                          IconButton(
                              tooltip: 'رفض الانضمام',
                              onPressed: () => review(r, false),
                              icon: const Icon(Icons.close)),
                        ],
                        IconButton(
                            tooltip: 'الرد',
                            onPressed: () => reply(r),
                            icon: const Icon(Icons.reply)),
                      ]),
                    )),
                ]));
          }));
}

class _ReplyDialog extends StatefulWidget {
  const _ReplyDialog();
  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('الرد على الطلب'),
          content:
              TextField(controller: controller, maxLength: 2000, maxLines: 4),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    Navigator.pop(context, controller.text.trim());
                  }
                },
                child: const Text('إرسال'))
          ]);
}
