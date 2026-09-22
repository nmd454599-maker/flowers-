import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';

class AdminFinanceScreen extends StatefulWidget {
  final AppState state;

  const AdminFinanceScreen({super.key, required this.state});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  double commissionRate = 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.state.loadAdminScope('finance');
    final records = widget.state.adminRecords['finance'] ?? const [];
    final commission = records.where((record) => record.id == 'commission');
    if (commission.isNotEmpty && mounted) {
      setState(() {
        commissionRate =
            (commission.first.data['percentage'] as num?)?.toDouble() ?? 12;
      });
    }
  }

  int get totalDue => widget.state.storeSettlements
      .where((item) => item.status == SettlementStatus.approved)
      .fold(0, (total, item) => total + item.netAmount);

  int get totalPaid => widget.state.storeSettlements
      .where((item) => item.status == SettlementStatus.paid)
      .fold(0, (total, item) => total + item.netAmount);

  int get platformRevenue => widget.state.storeSettlements
      .fold(0, (total, item) => total + item.commission);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('المالية والتسويات'),
          actions: [
            IconButton(
                tooltip: 'تحديث',
                onPressed:
                    widget.state.busy ? null : widget.state.loadAdminData,
                icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: AnimatedBuilder(
          animation: widget.state,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
            children: [
              if (widget.state.busy)
                const LinearProgressIndicator(minHeight: 2),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF153F34), Color(0xFF238C69)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الوضع المالي للمنصة',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('${_money(totalDue)} د.ع',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 27)),
                      const Text('مستحقات معتمدة بانتظار التحويل',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: _bannerMetric('تم تحويله', totalPaid)),
                        Container(width: 1, height: 42, color: Colors.white24),
                        Expanded(
                            child:
                                _bannerMetric('دخل المنصة', platformRevenue)),
                      ]),
                    ]),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      const Text('العمولة العامة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${commissionRate.round()}%',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ]),
                    Slider(
                      value: commissionRate,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '${commissionRate.round()}%',
                      onChanged: (value) =>
                          setState(() => commissionRate = value),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.state.busy ? null : _saveCommission,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('حفظ نسبة العمولة'),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                const Expanded(
                  child: Text('مستحقات المتاجر',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                ),
                FilledButton.tonalIcon(
                  onPressed: _createSettlement,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('تسوية'),
                ),
              ]),
              const SizedBox(height: 10),
              if (widget.state.storeSettlements.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 48,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      const Text('لا توجد تسويات مالية بعد',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Text('أنشئ أول تسوية لمتجر من الزر أعلاه'),
                    ]),
                  ),
                )
              else
                ...widget.state.storeSettlements.map(_settlementCard),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _requestExport,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('إنشاء كشف مالي PDF / Excel'),
              ),
            ],
          ),
        ),
      );

  Widget _bannerMetric(String label, int value) => Column(children: [
        Text('${_money(value)} د.ع',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]);

  Widget _settlementCard(StoreSettlement settlement) {
    final store = widget.state.adminStores
        .where((item) => item.id == settlement.storeId)
        .firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.storefront_rounded)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store?.name ?? settlement.storeId,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                        '${_date(settlement.periodStart)} — ${_date(settlement.periodEnd)}',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11)),
                  ]),
            ),
            _status(settlement.status),
          ]),
          const Divider(height: 22),
          _amountRow('إجمالي المبيعات', settlement.grossSales),
          _amountRow('عمولة المنصة', -settlement.commission),
          _amountRow('الاسترجاعات', -settlement.refunds),
          _amountRow('التعديلات', settlement.adjustments),
          const Divider(),
          _amountRow('صافي المستحق', settlement.netAmount, emphasized: true),
          if (settlement.transferReference?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('مرجع التحويل: ${settlement.transferReference}',
                  style: const TextStyle(fontSize: 11)),
            ),
          const SizedBox(height: 10),
          Row(children: [
            if (settlement.status == SettlementStatus.draft ||
                settlement.status == SettlementStatus.underReview)
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () =>
                      _changeStatus(settlement, SettlementStatus.approved),
                  child: const Text('اعتماد التسوية'),
                ),
              ),
            if (settlement.status == SettlementStatus.approved) ...[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _markPaid(settlement),
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('تسجيل التحويل'),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _amountRow(String label, int amount, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontWeight:
                      emphasized ? FontWeight.w800 : FontWeight.normal)),
          const Spacer(),
          Text('${amount < 0 ? '-' : ''}${_money(amount.abs())} د.ع',
              style: TextStyle(
                  color:
                      emphasized ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600)),
        ]),
      );

  Widget _status(SettlementStatus status) {
    final (text, color) = switch (status) {
      SettlementStatus.draft => ('مسودة', Colors.grey),
      SettlementStatus.underReview => ('قيد المراجعة', Colors.orange),
      SettlementStatus.approved => ('معتمدة', Colors.blue),
      SettlementStatus.paid => ('مدفوعة', Colors.green),
      SettlementStatus.rejected => ('مرفوضة', Colors.red),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Future<void> _saveCommission() async {
    try {
      await widget.state.saveAdminRecord('finance', 'commission', {
        'percentage': commissionRate.round(),
        'active': true,
      });
      if (!mounted) return;
      _message('تم حفظ نسبة العمولة');
    } catch (_) {
      if (mounted) _message(widget.state.errorMessage ?? 'تعذر حفظ العمولة');
    }
  }

  Future<void> _createSettlement() async {
    if (widget.state.adminStores.isEmpty) {
      _message('لا يوجد متجر لإنشاء تسوية');
      return;
    }
    var selectedStore = widget.state.adminStores.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('إنشاء تسوية مالية'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedStore,
            decoration: const InputDecoration(labelText: 'المتجر'),
            items: widget.state.adminStores
                .map((store) =>
                    DropdownMenuItem(value: store.id, child: Text(store.name)))
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => selectedStore = value);
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('إنشاء')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final now = DateTime.now();
    final gross = widget.state.adminOrders
        .where((order) =>
            order.storeIds.contains(selectedStore) &&
            order.status == OrderStatus.delivered &&
            (order.createdAt == null ||
                order.createdAt!
                    .isAfter(now.subtract(const Duration(days: 30)))))
        .fold<int>(0, (total, order) => total + order.total);
    final commission = (gross * commissionRate / 100).round();
    final settlement = StoreSettlement(
      id: '',
      storeId: selectedStore,
      periodStart: now.subtract(const Duration(days: 30)),
      periodEnd: now,
      grossSales: gross,
      commission: commission,
      refunds: 0,
      adjustments: 0,
      netAmount: gross - commission,
      status: SettlementStatus.draft,
      createdAt: now,
    );
    try {
      await widget.state.createSettlement(settlement);
      if (mounted) _message('تم إنشاء التسوية المالية');
    } catch (_) {
      if (mounted) _message(widget.state.errorMessage ?? 'تعذر إنشاء التسوية');
    }
  }

  Future<void> _changeStatus(
      StoreSettlement settlement, SettlementStatus status) async {
    try {
      await widget.state.updateSettlement(settlement, status);
      if (mounted) _message('تم اعتماد التسوية');
    } catch (_) {
      if (mounted) _message(widget.state.errorMessage ?? 'تعذر تحديث التسوية');
    }
  }

  Future<void> _markPaid(StoreSettlement settlement) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل التحويل المالي'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              labelText: 'رقم أو مرجع الحوالة', hintText: 'مثال: TRX-2026-001'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأكيد التحويل')),
        ],
      ),
    );
    final reference = controller.text.trim();
    controller.dispose();
    if (confirmed != true) return;
    if (reference.isEmpty) {
      _message('يجب إدخال مرجع التحويل');
      return;
    }
    try {
      await widget.state.updateSettlement(settlement, SettlementStatus.paid,
          transferReference: reference);
      if (mounted) _message('تم تسجيل دفع التسوية');
    } catch (_) {
      if (mounted) _message(widget.state.errorMessage ?? 'تعذر تسجيل التحويل');
    }
  }

  Future<void> _requestExport() async {
    try {
      await widget.state.saveAdminRecord('finance', null, {
        'type': 'settlementsExport',
        'status': 'requested',
        'format': 'xlsx_pdf',
      });
      if (mounted) _message('تم إنشاء طلب تصدير الكشف');
    } catch (_) {
      if (mounted) _message(widget.state.errorMessage ?? 'تعذر طلب التصدير');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _money(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

  String _date(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
