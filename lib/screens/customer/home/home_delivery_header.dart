import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HomeDeliveryHeader extends StatelessWidget {
  final String city;
  final int cartCount;
  final VoidCallback onAddressTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onCartTap;
  const HomeDeliveryHeader(
      {super.key,
      required this.city,
      required this.cartCount,
      required this.onAddressTap,
      required this.onNotificationsTap,
      required this.onCartTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: .5)),
                borderRadius: BorderRadius.circular(24)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.gift,
                  color: Theme.of(context).colorScheme.secondary, size: 19),
              const SizedBox(width: 5),
              const Text('أزهارنا',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))
            ])),
        const SizedBox(width: 10),
        Expanded(
            child: InkWell(
                onTap: onAddressTap,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('توصيل الهدية إلى',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 10)),
                          Row(children: [
                            Flexible(
                                child: Text('$city، العراق',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700))),
                            const SizedBox(width: 4),
                            const Icon(CupertinoIcons.chevron_down, size: 11)
                          ]),
                        ])))),
        IconButton(
            tooltip: 'الإشعارات',
            onPressed: onNotificationsTap,
            icon: const Icon(CupertinoIcons.bell, size: 21)),
        Badge(
            isLabelVisible: cartCount > 0,
            label: Text('$cartCount'),
            child: IconButton(
                tooltip: 'السلة',
                onPressed: onCartTap,
                icon: const Icon(CupertinoIcons.bag, size: 22))),
      ]));
}
