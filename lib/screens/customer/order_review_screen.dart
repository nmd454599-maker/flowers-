import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';

class OrderReviewScreen extends StatelessWidget {
  const OrderReviewScreen(
      {super.key,
      required this.state,
      required this.recipient,
      required this.phone,
      required this.address,
      required this.schedule,
      required this.gift,
      this.discount = 0,
      this.walletUsed = 0});
  final AppState state;
  final int discount, walletUsed;
  final String recipient, phone, address, schedule, gift;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مراجعة الطلب')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          AppSection(
              title: 'المنتجات',
              child: Column(
                  children: state.cart.entries
                      .map((entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.key.name),
                          subtitle: Text('الكمية: ${entry.value}'),
                          trailing:
                              Text('${entry.key.price * entry.value} د.ع')))
                      .toList())),
          const SizedBox(height: 16),
          AppSection(
              title: 'المستلم والتوصيل',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(recipient),
                    Text(phone, textDirection: TextDirection.ltr),
                    const SizedBox(height: 8),
                    Text(address),
                    const SizedBox(height: 8),
                    Text('الموعد: $schedule')
                  ])),
          const SizedBox(height: 16),
          AppSection(
              title: 'بطاقة الإهداء',
              child: Text(gift.isEmpty ? 'بدون رسالة' : gift)),
          const SizedBox(height: 16),
          AppSection(
              title: 'الدفع عند الاستلام',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('المنتجات: ${state.cartSubtotal} د.ع'),
                    Text('التوصيل: ${state.deliveryFee} د.ع'),
                    const Divider(height: 24),
                    if (discount > 0) Text('خصم الكوبون: -$discount د.ع'),
                    if (walletUsed > 0) Text('من المحفظة: $walletUsed د.ع'),
                    Text(
                        'المطلوب نقدًا: ${state.cartTotal - discount - walletUsed} د.ع',
                        style: Theme.of(context).textTheme.titleLarge)
                  ])),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد وإرسال الطلب')),
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تعديل البيانات')),
        ]),
      );
}
