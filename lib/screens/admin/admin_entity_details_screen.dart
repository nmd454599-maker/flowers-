import 'customer_wallet_admin_screen.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_products_screen.dart';
import 'admin_finance_screen.dart';

class AdminUserDetailsScreen extends StatelessWidget {
  final AppState state;
  final AdminUserRecord user;

  const AdminUserDetailsScreen({
    super.key,
    required this.state,
    required this.user,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final current =
              state.adminUsers.where((item) => item.id == user.id).firstOrNull;
          final value = current ?? user;
          final orders = state.adminOrders
              .where((order) => order.customerId == value.id)
              .toList();
          final audit = state.adminAuditLogs
              .where((record) => record.targetId == value.id)
              .toList();
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: const Text('تفاصيل المستخدم')),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _identityCard(
                  icon: Icons.person_rounded,
                  title: value.name,
                  subtitle: value.phone,
                  status: value.active ? 'حساب نشط' : 'حساب موقوف',
                  active: value.active,
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'معلومات الحساب',
                  child: Column(children: [
                    _InfoRow('معرف المستخدم', value.id),
                    _InfoRow('نوع الحساب', _roleLabel(value.role)),
                    _InfoRow('تاريخ التسجيل', _date(value.createdAt)),
                    _InfoRow('عدد الطلبات', '${orders.length}'),
                    _InfoRow('إجمالي المشتريات',
                        '${orders.fold<int>(0, (total, order) => total + order.total)} د.ع'),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => _editAccount(context, value),
                      icon: const Icon(Icons.manage_accounts_rounded),
                      label: const Text('إدارة الحساب'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showOrders(context, orders),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('الطلبات'),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                if (value.role == UserRole.customer)
                  FilledButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CustomerWalletAdminScreen(
                                  state: state, customer: value))),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('إدارة رصيد المحفظة')),
                _AuditSection(records: audit),
              ],
            ),
          );
        },
      );

  Future<void> _editAccount(
      BuildContext context, AdminUserRecord current) async {
    var role = current.role;
    var active = current.active;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(current.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<UserRole>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'الدور والصلاحية'),
              items: UserRole.values
                  .where((item) =>
                      item != UserRole.courier ||
                      current.role == UserRole.courier)
                  .map((item) => DropdownMenuItem(
                      value: item, child: Text(_roleLabel(item))))
                  .toList(),
              onChanged: current.role == UserRole.courier
                  ? null
                  : (value) {
                      if (value != null) setDialogState(() => role = value);
                    },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('الحساب نشط'),
              subtitle: const Text('إيقاف الحساب يمنع صاحبه من الدخول'),
              value: active,
              onChanged: (value) => setDialogState(() => active = value),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (save != true) return;
    try {
      await state.updateManagedUser(current, role, active);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الحساب وتسجيل العملية')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'تعذر تحديث الحساب')));
    }
  }

  void _showOrders(BuildContext context, List<AdminOrderRecord> orders) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => orders.isEmpty
          ? const Center(child: Text('لا توجد طلبات لهذا المستخدم'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, index) => ListTile(
                title: Text(orders[index].id),
                subtitle: Text(orders[index].address),
                trailing: Text('${orders[index].total} د.ع'),
              ),
            ),
    );
  }
}

class AdminStoreDetailsScreen extends StatelessWidget {
  final AppState state;
  final AdminStoreRecord store;

  const AdminStoreDetailsScreen({
    super.key,
    required this.state,
    required this.store,
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final current = state.adminStores
              .where((item) => item.id == store.id)
              .firstOrNull;
          final value = current ?? store;
          final products = state.adminProducts
              .where((product) => product.storeId == value.id)
              .toList();
          final orders = state.adminOrders
              .where((order) => order.storeIds.contains(value.id))
              .toList();
          final audit = state.adminAuditLogs
              .where((record) => record.targetId == value.id)
              .toList();
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: const Text('تفاصيل المتجر')),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _identityCard(
                  icon: Icons.storefront_rounded,
                  title: value.name,
                  subtitle: '${value.city} · ${value.ownerName}',
                  status: _storeStatus(value.status),
                  active: value.status == StoreApprovalStatus.approved,
                ),
                const SizedBox(height: 14),
                _Section(
                  title: 'بيانات المتجر',
                  child: Column(children: [
                    _InfoRow('معرف المتجر', value.id),
                    _InfoRow('اسم المالك', value.ownerName),
                    _InfoRow('هاتف المالك', value.ownerPhone),
                    _InfoRow('المدينة', value.city),
                    _InfoRow('الوثائق',
                        value.documentsComplete ? 'مكتملة' : 'ناقصة'),
                    _InfoRow('تاريخ التسجيل', _date(value.createdAt)),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _MetricBox('المنتجات', '${products.length}',
                          Icons.inventory_2_outlined)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _MetricBox('الطلبات', '${orders.length}',
                          Icons.receipt_long_outlined)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _MetricBox(
                          'المبيعات',
                          '${orders.fold<int>(0, (total, order) => total + order.total)}',
                          Icons.payments_outlined)),
                ]),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminProductsScreen(
                          state: state, initialStoreId: value.id),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: const Text('عرض منتجات المتجر'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminFinanceScreen(state: state),
                    ),
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(
                      'التسويات المالية (${state.storeSettlements.where((item) => item.storeId == value.id).length})'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: state.busy ? null : () => _manage(context, value),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('تغيير حالة المتجر'),
                ),
                const SizedBox(height: 14),
                _AuditSection(records: audit),
              ],
            ),
          );
        },
      );

  Future<void> _manage(BuildContext context, AdminStoreRecord current) async {
    var status = current.status;
    final reason = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(current.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<StoreApprovalStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'حالة المتجر'),
              items: StoreApprovalStatus.values
                  .map((item) => DropdownMenuItem(
                      value: item, child: Text(_storeStatus(item))))
                  .toList(),
              onChanged: (value) {
                if (value != null) setDialogState(() => status = value);
              },
            ),
            if (status == StoreApprovalStatus.rejected ||
                status == StoreApprovalStatus.suspended) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'سبب الإجراء'),
              ),
            ],
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (save != true) {
      reason.dispose();
      return;
    }
    final reasonText = reason.text.trim();
    reason.dispose();
    if ((status == StoreApprovalStatus.rejected ||
            status == StoreApprovalStatus.suspended) &&
        reasonText.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب كتابة سبب الإجراء')));
      }
      return;
    }
    try {
      await state.reviewStore(current, status,
          reason: reasonText.isEmpty ? null : reasonText);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المتجر وتسجيل العملية')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'تعذر تحديث المتجر')));
    }
  }
}

Widget _identityCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required String status,
  required bool active,
}) =>
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF087E9A), Color(0xFF064C65)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19)),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF4DB68D)
                      : const Color(0xFFD65E57),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    );

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricBox(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10)),
        ]),
      );
}

class _AuditSection extends StatelessWidget {
  final List<AdminAuditRecord> records;
  const _AuditSection({required this.records});

  @override
  Widget build(BuildContext context) => _Section(
        title: 'سجل الإجراءات',
        child: records.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: Text('لا توجد إجراءات إدارية مسجلة')),
              )
            : Column(
                children: records
                    .take(10)
                    .map((record) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const CircleAvatar(
                              child: Icon(Icons.history_rounded, size: 18)),
                          title: Text(_actionLabel(record.action)),
                          subtitle: Text(_date(record.createdAt)),
                        ))
                    .toList(),
              ),
      );
}

String _roleLabel(UserRole role) => role.label;

String _storeStatus(StoreApprovalStatus status) => switch (status) {
      StoreApprovalStatus.pending => 'بانتظار الموافقة',
      StoreApprovalStatus.approved => 'نشط ومعتمد',
      StoreApprovalStatus.rejected => 'مرفوض',
      StoreApprovalStatus.suspended => 'موقوف مؤقتًا',
    };

String _actionLabel(String action) => switch (action) {
      'user.update' => 'تعديل الحساب والصلاحيات',
      'store.approval' => 'تغيير حالة المتجر',
      'product.review' => 'مراجعة منتج',
      'order.status' => 'تغيير حالة طلب',
      _ => action,
    };

String _date(DateTime? value) {
  if (value == null) return 'غير متوفر';
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
