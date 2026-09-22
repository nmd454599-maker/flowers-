import 'package:flutter/material.dart';
import '../../../models/models.dart';

class HomeProductList extends StatelessWidget {
  final List<Product> items;
  final bool isLoading;
  final Widget Function(Product) itemBuilder;
  const HomeProductList(
      {super.key,
      required this.items,
      required this.isLoading,
      required this.itemBuilder});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
              isLoading
                  ? 'نجهّز لك أجمل الهدايا…'
                  : 'ستظهر الهدايا المتاحة هنا',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)));
    }
    return SizedBox(
        height: 340 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
        child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) =>
                SizedBox(width: 222, child: itemBuilder(items[i]))));
  }
}
