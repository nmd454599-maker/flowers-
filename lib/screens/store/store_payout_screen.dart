import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class StorePayoutScreen extends StatefulWidget {
  final AppState state;
  const StorePayoutScreen({super.key, required this.state});
  @override
  State<StorePayoutScreen> createState() => _StorePayoutScreenState();
}

class _StorePayoutScreenState extends State<StorePayoutScreen> {
  final holder = TextEditingController();
  final card = TextEditingController();
  final expiry = TextEditingController();
  final iban = TextEditingController();
  String method = 'card';
  bool loading = true, saving = false;
  String? savedLast4;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows =
        await widget.state.repository.fetchAdminRecords('store_payout_methods');
    final saved = rows
        .where((r) => r.id == 'payout_${widget.state.user?.storeId}')
        .firstOrNull;
    if (saved != null) {
      final d = saved.data;
      holder.text = '${d['holder'] ?? ''}';
      iban.text = '${d['iban'] ?? ''}';
      savedLast4 = d['last4']?.toString();
      method = '${d['method'] ?? 'card'}';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('استلام الأموال')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(18), children: [
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF087E9A), Color(0xFF087E9A)]),
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.credit_card_rounded,
                            color: Colors.white, size: 34),
                        const SizedBox(height: 18),
                        Text(
                            savedLast4 == null
                                ? 'أضف وسيلة التسوية'
                                : '••••  ••••  ••••  $savedLast4',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        const Text('تُحوّل أرباح المتجر بعد خصم العمولة',
                            style: TextStyle(color: Colors.white70))
                      ])),
              const SizedBox(height: 18),
              SegmentedButton<String>(segments: const [
                ButtonSegment(
                    value: 'card',
                    label: Text('بطاقة ائتمان'),
                    icon: Icon(Icons.credit_card_rounded)),
                ButtonSegment(
                    value: 'bank',
                    label: Text('حساب مصرفي'),
                    icon: Icon(Icons.account_balance_rounded))
              ], selected: {
                method
              }, onSelectionChanged: (v) => setState(() => method = v.first)),
              const SizedBox(height: 16),
              TextField(
                  controller: holder,
                  decoration: const InputDecoration(
                      labelText: 'اسم صاحب الحساب',
                      prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 12),
              if (method == 'card') ...[
                TextField(
                    controller: card,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    decoration: InputDecoration(
                        labelText: savedLast4 == null
                            ? 'رقم البطاقة'
                            : 'بطاقة محفوظة تنتهي بـ $savedLast4',
                        prefixIcon: const Icon(Icons.credit_card_rounded))),
                const SizedBox(height: 4),
                TextField(
                    controller: expiry,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                        labelText: 'تاريخ الانتهاء MM/YY',
                        prefixIcon: Icon(Icons.date_range_rounded)))
              ] else
                TextField(
                    controller: iban,
                    decoration: const InputDecoration(
                        labelText: 'IBAN أو رقم الحساب',
                        prefixIcon: Icon(Icons.account_balance_rounded))),
              const SizedBox(height: 12),
              const Row(children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: Colors.green),
                SizedBox(width: 7),
                Expanded(
                    child: Text(
                        'لا يتم حفظ رقم البطاقة كاملًا أو رمز CVV على الهاتف.',
                        style: TextStyle(fontSize: 12, color: Colors.grey)))
              ]),
              const SizedBox(height: 18),
              FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('تفعيل استلام الأموال')),
            ]));
  Future<void> _save() async {
    if (holder.text.trim().isEmpty) {
      _toast('أدخل اسم صاحب الحساب');
      return;
    }
    String? last4 = savedLast4;
    if (method == 'card') {
      final digits = card.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 12 && savedLast4 == null) {
        _toast('أدخل رقم بطاقة صحيح');
        return;
      }
      if (digits.length >= 4) last4 = digits.substring(digits.length - 4);
    } else if (iban.text.trim().isEmpty) {
      _toast('أدخل رقم الحساب أو IBAN');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.state.repository.saveAdminRecord('store_payout_methods',
          'payout_${widget.state.user?.storeId ?? 's1'}', {
        'method': method,
        'storeId': widget.state.user!.storeId,
        'holder': holder.text.trim(),
        'last4': last4,
        'iban': iban.text.trim(),
        'verified': false,
        'updatedAt': DateTime.now().toIso8601String()
      });
      if (!mounted) return;
      setState(() {
        saving = false;
        savedLast4 = last4;
        card.clear();
      });
      _toast('تم حفظ وسيلة الاستلام للمراجعة؛ لم يُنفّذ أي تحويل');
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        _toast('تعذر الحفظ؛ أعد المحاولة');
      }
    }
  }

  void _toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
}
