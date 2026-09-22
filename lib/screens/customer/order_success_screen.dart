import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/app_components.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final AppOrder order;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تم استلام طلبك')),
        body: AppEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'هدية جميلة في طريقها إلى التجهيز',
            message:
                'رقم الطلب: ${order.id}\nيمكنك متابعة حالته من صفحة الطلبات.',
            action: Column(mainAxisSize: MainAxisSize.min, children: [
              FilledButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(order: order))),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('تتبع الطلب')),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('العودة للرئيسية')),
            ])),
      );
}
