import 'package:flutter/material.dart';
import '../../data/firebase_repository.dart';
import '../../models/models.dart';
import '../../services/customer_account_service.dart';
import '../../services/rewards_service.dart';
import '../../state/app_state.dart';

class CustomerWalletAdminScreen extends StatefulWidget {
  final AppState state;
  final AdminUserRecord customer;
  const CustomerWalletAdminScreen(
      {super.key, required this.state, required this.customer});
  @override
  State<CustomerWalletAdminScreen> createState() =>
      _CustomerWalletAdminScreenState();
}

class _CustomerWalletAdminScreenState extends State<CustomerWalletAdminScreen> {
  final amount = TextEditingController(), reason = TextEditingController();
  Map<String, Object?> data = {};
  bool loading = true, saving = false;
  String? error, requestId, fingerprint;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    amount.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final repo = widget.state.repository;
      final value = repo is FirebaseRepository
          ? (await repo.firestore
                      .collection('users')
                      .doc(widget.customer.id)
                      .collection('account')
                      .doc('benefits')
                      .get())
                  .data() ??
              <String, Object?>{}
          : await CustomerAccountService(
                  repo,
                  AppUser(
                      id: widget.customer.id,
                      name: widget.customer.name,
                      phone: widget.customer.phone,
                      role: UserRole.customer))
              .read('benefits');
      if (mounted) {
        setState(() {
          data = value;
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'تعذر تحميل المحفظة';
        });
      }
    }
  }

  Future<void> credit() async {
    final normalized = amount.text.trim().replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) { final c=m[0]!; final a='٠١٢٣٤٥٦٧٨٩'.indexOf(c); return (a >= 0 ? a : '۰۱۲۳۴۵۶۷۸۹'.indexOf(c)).toString(); });
    final value = int.tryParse(normalized);
    if (value == null ||
        value <= 0 ||
        value > 100000000 ||
        reason.text.trim().isEmpty) {
      setState(() => error = 'أدخل مبلغًا موجبًا وسبب إضافة الرصيد');
      return;
    }
    final actor = widget.state.user;
    if (actor == null || actor.role != UserRole.superAdmin) return;
    final service = RewardsService(widget.state.repository, actor);
    final input = '$value|${reason.text.trim()}';
    if (fingerprint != input) {
      fingerprint = input;
      requestId = service.id();
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await service.credit(
          widget.customer.id, value, reason.text.trim(), requestId!);
      if (!mounted) return;
      amount.clear();
      reason.clear();
      requestId = null;
      fingerprint = null;
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل رصيد المحفظة')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'تعذر تأكيد الإضافة. أعد المحاولة بنفس البيانات لمنع التكرار.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('محفظة ${widget.customer.name}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Text('الرصيد الحالي: ${data['balance'] ?? 0} د.ع',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Text(
                  'إضافة رصيد داخلي قابل للاستخدام في الطلبات. سجّل سبب الإضافة أو مرجع المبلغ المستلم.'),
              TextField(
                  controller: amount,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'المبلغ بالدينار العراقي')),
              TextField(
                  controller: reason,
                  enabled: !saving,
                  maxLength: 300,
                  decoration: const InputDecoration(
                      labelText: 'سبب الإضافة / مرجع الاستلام')),
              if (error != null) Text(error!),
              FilledButton(
                  onPressed: saving ? null : credit,
                  child: Text(saving ? 'جارٍ التسجيل…' : 'إضافة الرصيد')),
              TextButton(
                  onPressed: saving ? null : load,
                  child: const Text('تحديث الرصيد')),
              for (final row in (data['transactions'] as List? ?? [])
                  .where((r) => r['type'] == 'credit' || r['type'] == 'debit'))
                ListTile(
                    title: Text('${row['amount']} د.ع'),
                    subtitle:
                        Text('${row['description']}\n${row['createdAt']}')),
            ]));
}
