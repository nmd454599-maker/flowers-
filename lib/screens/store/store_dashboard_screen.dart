import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'store_products_screen.dart';
import 'store_messages_screen.dart';
import '../shared/image_library_screen.dart';
import '../customer/notifications_screen.dart';

class StoreDashboardScreen extends StatelessWidget {
  final AppState state;
  final ValueChanged<int> openTab;
  const StoreDashboardScreen(
      {super.key, required this.state, required this.openTab});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        final sales = state.orders
            .where((o) => o.status == OrderStatus.delivered)
            .fold<int>(0, (sum, o) => sum + o.subtotal);
        final pending = state.orders
            .where((o) =>
                o.status == OrderStatus.newOrder ||
                o.status == OrderStatus.preparing)
            .length;
        void page(Widget child) =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => child));
        return Scaffold(
            appBar: AppBar(title: const Text('لوحة المتجر'), actions: [
              const ImageLibraryButton(),
              IconButton(
                  tooltip: 'الإشعارات',
                  onPressed: () => page(NotificationsScreen(state: state)),
                  icon: const Icon(Icons.notifications_none)),
              IconButton(
                  tooltip: 'تحديث',
                  onPressed: state.busy
                      ? null
                      : () async {
                          try {
                            await state.refreshOrders();
                          } catch (_) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تعذر التحديث')));
                          }
                        },
                  icon: const Icon(Icons.refresh)),
            ]),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              Text('أهلًا، ${state.user?.name ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _StoreMetric(
                    label: 'طلبات المتجر',
                    value: '${state.orders.length}',
                    onTap: () => openTab(1)),
                _StoreMetric(
                    label: 'بحاجة للتجهيز',
                    value: '$pending',
                    onTap: () => openTab(1)),
              ]),
              const SizedBox(height: 20),
              Text('قيمة المنتجات المسلّمة',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('$sales د.ع',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Text('قبل خصم العمولة والتسويات'),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('إدارة المنتجات والصور'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => page(StoreProductsScreen(state: state))),
              ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('محادثات العملاء'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => page(StoreMessagesScreen(state: state))),
              ListTile(
                  leading: const Icon(Icons.storefront),
                  title: const Text('بروفايل المتجر'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => openTab(2)),
              ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('إعدادات المتجر'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => openTab(3)),
            ]));
      });
}

class _StoreMetric extends StatelessWidget {
  const _StoreMetric(
      {required this.label, required this.value, required this.onTap});
  final String label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 140,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  ]),
            )),
      ));
}
