import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class AdminRefundsScreen extends StatefulWidget {
  final AppState state;
  const AdminRefundsScreen({super.key, required this.state});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('الإلغاءات واسترداد الأموال'),
          actions: [
            IconButton(onPressed: _create, icon: const Icon(Icons.add_rounded)),
          ],
        ),
        body: AnimatedBuilder(
          animation: widget.state,
          builder: (_, __) {
            final items = widget.state.refundRequests;
            if (items.isEmpty) {
              return Center(
                child: FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('إنشاء طلب استرداد'),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _refundCard(items[index]),
            );
          },
        ),
      );

  Widget _refundCard(RefundRequest refund) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('الطلب ${refund.orderId}',
                      style: const TextStyle(fontWeight: FontWeight.w800))),
              Chip(label: Text(_status(refund.status))),
            ]),
            Text(
                '${refund.amount} د.ع • يتحملها ${refund.liability == RefundLiability.platform ? 'المنصة' : 'المتجر'}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(refund.reason),
            if (refund.note?.isNotEmpty == true) Text('ملاحظة: ${refund.note}'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              if (refund.status == RefundStatus.requested)
                OutlinedButton(
                    onPressed: () => _update(refund, RefundStatus.underReview),
                    child: const Text('بدء المراجعة')),
              if (refund.status == RefundStatus.requested ||
                  refund.status == RefundStatus.underReview)
                FilledButton(
                    onPressed: () => _update(refund, RefundStatus.approved),
                    child: const Text('موافقة')),
              if (refund.status == RefundStatus.approved)
                FilledButton.icon(
                    onPressed: () => _update(refund, RefundStatus.completed),
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('تأكيد إعادة المبلغ')),
              if (refund.status != RefundStatus.completed &&
                  refund.status != RefundStatus.rejected)
                TextButton(
                    onPressed: () => _update(refund, RefundStatus.rejected),
                    child: const Text('رفض')),
            ]),
          ]),
        ),
      );

  Future<void> _create() async {
    if (widget.state.adminOrders.isEmpty) {
      _message('لا توجد طلبات قابلة للاسترداد');
      return;
    }
    var order = widget.state.adminOrders.first;
    var liability = RefundLiability.platform;
    final amount = TextEditingController(text: '${order.total}');
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: const Text('طلب استرداد جديد'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<AdminOrderRecord>(
                    initialValue: order,
                    decoration: const InputDecoration(labelText: 'الطلب'),
                    items: widget.state.adminOrders
                        .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text('${item.id} • ${item.total} د.ع')))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          order = value;
                          amount.text = '${value.total}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المبلغ')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: reason,
                      decoration: const InputDecoration(
                          labelText: 'سبب الإلغاء أو الاسترداد')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<RefundLiability>(
                    initialValue: liability,
                    decoration:
                        const InputDecoration(labelText: 'الجهة المتحملة'),
                    items: const [
                      DropdownMenuItem(
                          value: RefundLiability.platform,
                          child: Text('المنصة')),
                      DropdownMenuItem(
                          value: RefundLiability.store, child: Text('المتجر')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => liability = value);
                      }
                    },
                  ),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('إنشاء')),
                ],
              ),
            ));
    if (accepted != true) return;
    final value = int.tryParse(amount.text) ?? 0;
    if (value <= 0 || value > order.total || reason.text.trim().isEmpty) {
      _message('تحقق من المبلغ والسبب');
      return;
    }
    try {
      await widget.state.createRefund(RefundRequest(
        id: '',
        orderId: order.id,
        customerId: order.customerId,
        amount: value,
        reason: reason.text.trim(),
        liability: liability,
        status: RefundStatus.requested,
      ));
      _message('تم إنشاء طلب الاسترداد');
    } catch (_) {
      _message(widget.state.errorMessage ?? 'تعذر إنشاء الطلب');
    }
  }

  Future<void> _update(RefundRequest refund, RefundStatus status) async {
    try {
      await widget.state.updateRefund(refund, status);
      _message('تم تحديث حالة الاسترداد');
    } catch (_) {
      _message(widget.state.errorMessage ?? 'تعذر تحديث الحالة');
    }
  }

  String _status(RefundStatus value) => switch (value) {
        RefundStatus.requested => 'جديد',
        RefundStatus.underReview => 'قيد المراجعة',
        RefundStatus.approved => 'مقبول',
        RefundStatus.completed => 'تم الاسترداد',
        RefundStatus.rejected => 'مرفوض',
      };

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }
}
