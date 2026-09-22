import 'package:flutter/material.dart';

import '../../widgets/product_photo.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final AppState state;
  const CartScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: Text('سلة التسوق (${state.cartCount})')),
          body: state.cart.isEmpty
              ? const _EmptyCart()
              : Column(children: [
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.all(18),
                          children: [
                        const Text('المنتجات المختارة',
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        ...state.cart.entries.map((entry) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow)),
                              child: Row(children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(17),
                                    child: ProductPhoto(
                                        product: entry.key,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(entry.key.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      Text('${entry.key.price} د.ع',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        _QtyButton(Icons.remove_rounded,
                                            () => state.decrement(entry.key)),
                                        Expanded(
                                            child: Text('${entry.value}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800))),
                                        _QtyButton(Icons.add_rounded,
                                            () => state.addToCart(entry.key)),
                                      ]),
                                    ])),
                                IconButton(
                                    onPressed: () =>
                                        state.removeFromCart(entry.key),
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary)),
                              ]),
                            )),
                      ])),
                  Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28)),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x16000000),
                                blurRadius: 24,
                                offset: Offset(0, -5))
                          ]),
                      child: SafeArea(
                          top: false,
                          child: Column(children: [
                            _Price('المجموع', state.cartSubtotal),
                            const SizedBox(height: 6),
                            _Price('رسم التوصيل', state.deliveryFee),
                            const Divider(height: 22),
                            _Price('الإجمالي', state.cartTotal, bold: true),
                            const SizedBox(height: 14),
                            SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                CheckoutScreen(state: state))),
                                    child: const Text('متابعة إتمام الطلب'))),
                          ]))),
                ]),
        ),
      );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback tap;
  const _QtyButton(this.icon, this.tap);
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary)));
}

class _Price extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;
  const _Price(this.label, this.amount, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
        Text('$amount د.ع',
            style: TextStyle(
                fontSize: bold ? 19 : 14,
                color: bold ? Theme.of(context).colorScheme.primary : null,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600))
      ]);
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => const AppEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'سلتك فارغة',
      message: 'أضف المنتجات التي تحبها للمتابعة');
}
