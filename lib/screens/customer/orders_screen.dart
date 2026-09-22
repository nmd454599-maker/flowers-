import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.state});
  final AppState state;
  String status(OrderStatus value) => switch (value) {
        OrderStatus.newOrder => 'تم استلام الطلب',
        OrderStatus.preparing => 'قيد التجهيز',
        OrderStatus.delivering => 'في الطريق',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.cancelled => 'ملغي',
      };
  @override
  Widget build(BuildContext context) => DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
              title: const Text('طلباتي'),
              actions: [
                IconButton(
                    tooltip: 'تحديث الطلبات',
                    onPressed: state.busy ? null : state.refreshOrders,
                    icon: const Icon(Icons.refresh_rounded))
              ],
              bottom: const TabBar(tabs: [
                Tab(text: 'الحالية'),
                Tab(text: 'المكتملة'),
                Tab(text: 'الملغاة')
              ])),
          body: AnimatedBuilder(
              animation: state,
              builder: (context, _) => TabBarView(children: [
                    _list(
                        context,
                        state.orders
                            .where((o) =>
                                o.status != OrderStatus.delivered &&
                                o.status != OrderStatus.cancelled)
                            .toList()),
                    _list(
                        context,
                        state.orders
                            .where((o) => o.status == OrderStatus.delivered)
                            .toList()),
                    _list(
                        context,
                        state.orders
                            .where((o) => o.status == OrderStatus.cancelled)
                            .toList()),
                  ]))));
  Widget _list(BuildContext context, List<AppOrder> orders) {
    if (orders.isEmpty) {
      return const AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'لا توجد طلبات هنا',
          message: 'ستظهر طلباتك وحالتها في هذا القسم');
    }
    return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, index) {
          final order = orders[index];
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(order.id,
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          Chip(label: Text(status(order.status)))
                        ]),
                        const SizedBox(height: 8),
                        Text(order.address,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Text('${order.total} د.ع',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                        if (order.discount > 0)
                          Text('خصم الكوبون: ${order.discount} د.ع'),
                        if (order.walletUsed > 0)
                          Text('من المحفظة: ${order.walletUsed} د.ع'),
                        Text('المطلوب نقدًا: ${order.cashDue} د.ع'),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        OrderTrackingScreen(order: order))),
                            icon: const Icon(Icons.local_shipping_outlined),
                            label: const Text('عرض تفاصيل الطلب')),
                      ])));
        });
  }
}
