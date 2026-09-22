import 'package:flutter/material.dart';

import '../../models/models.dart';

class OrderTrackingScreen extends StatelessWidget {
  final AppOrder order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تتبع الطلب')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF087E9A), Color(0xFF064C65)]),
                  borderRadius: BorderRadius.circular(26)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        order.status == OrderStatus.cancelled
                            ? 'تم إلغاء الطلب'
                            : switch (order.status) {
                                OrderStatus.newOrder => 'تم استلام الطلب',
                                OrderStatus.preparing => 'قيد التجهيز',
                                OrderStatus.delivering => 'في الطريق',
                                OrderStatus.delivered => 'تم التسليم',
                                OrderStatus.cancelled => 'تم إلغاء الطلب',
                              },
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(order.id,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Icon(Icons.schedule_rounded, color: Colors.white),
                      SizedBox(width: 7),
                      Flexible(
                          child: Text('تابع مراحل طلبك أدناه',
                              style: TextStyle(color: Colors.white)))
                    ])
                  ])),
          const SizedBox(height: 26),
          Text('المطلوب نقدًا: ${order.cashDue} د.ع'),
          if (order.walletUsed > 0) Text('من المحفظة: ${order.walletUsed} د.ع'),
          const Text('حالة الطلب',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _Step(Icons.check_rounded, 'تم استلام الطلب', 'تم تسجيل طلبك بنجاح',
              order.status != OrderStatus.cancelled),
          _Step(
              Icons.inventory_2_outlined,
              'جاري تجهيز الهدية',
              'تنسيق وتجهيز المنتجات',
              [
                OrderStatus.preparing,
                OrderStatus.delivering,
                OrderStatus.delivered
              ].contains(order.status)),
          _Step(
              Icons.delivery_dining_rounded,
              'خرج للتوصيل',
              'الطلب في الطريق للمستلم',
              [OrderStatus.delivering, OrderStatus.delivered]
                  .contains(order.status)),
          _Step(
              Icons.home_outlined,
              'تم التسليم',
              'نتمنى أن تنال الهدية إعجابكم',
              order.status == OrderStatus.delivered,
              last: true),
          const SizedBox(height: 20),
          ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Icon(Icons.storefront_rounded,
                      color: Theme.of(context).colorScheme.primary)),
              title: const Text('عنوان التوصيل',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(order.address)),
        ]),
      );
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final bool last;
  const _Step(this.icon, this.title, this.subtitle, this.active,
      {this.last = false});
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
            width: 48,
            child: Column(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: BoxShape.circle),
                  child: Icon(icon,
                      size: 20,
                      color: active
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant)),
              if (!last)
                Expanded(
                    child: Container(
                        width: 2,
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow))
            ])),
        const SizedBox(width: 10),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black54)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))
                    ])))
      ]));
}
