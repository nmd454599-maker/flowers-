import '../../domain/orders/order_transitions.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class StoreOrdersScreen extends StatelessWidget {
  final AppState state;
  const StoreOrdersScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('طلبات المتجر'), actions: [
          IconButton(
              tooltip: 'تحديث الطلبات',
              onPressed: state.busy ? null : state.refreshOrders,
              icon: const Icon(Icons.refresh_rounded))
        ]),
        body: state.orders.isEmpty
            ? const Center(child: Text('لا توجد طلبات جديدة'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.orders.length,
                itemBuilder: (_, i) {
                  final o = state.orders[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.id,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          Text('الإجمالي: ${o.total} د.ع'),
                          Text('المطلوب نقدًا: ${o.cashDue} د.ع'),
                          if (o.walletUsed > 0) Text('مدفوع من المحفظة: ${o.walletUsed} د.ع'),
                          Text(o.address),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('تجهيز'),
                                onPressed: state.busy ||
                                        !canAdvanceOrder(
                                            o.status, OrderStatus.preparing)
                                    ? null
                                    : () async {
                                        try {
                                          await state.updateOrderStatus(
                                              o, OrderStatus.preparing);
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'تعذر تحديث الطلب، حاول مجدداً')));
                                          }
                                        }
                                      },
                              ),
                              ActionChip(
                                label: const Text('في الطريق'),
                                onPressed: state.busy ||
                                        !canAdvanceOrder(
                                            o.status, OrderStatus.delivering)
                                    ? null
                                    : () async {
                                        try {
                                          await state.updateOrderStatus(
                                              o, OrderStatus.delivering);
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'تعذر تحديث الطلب، حاول مجدداً')));
                                          }
                                        }
                                      },
                              ),
                              ActionChip(
                                label: const Text('تم التسليم'),
                                onPressed: state.busy ||
                                        !canAdvanceOrder(
                                            o.status, OrderStatus.delivered)
                                    ? null
                                    : () async {
                                        try {
                                          await state.updateOrderStatus(
                                              o, OrderStatus.delivered);
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'تعذر تحديث الطلب، حاول مجدداً')));
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
