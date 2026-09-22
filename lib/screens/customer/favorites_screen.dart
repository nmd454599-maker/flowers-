import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';
import '../../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('المفضلة')),
        body: AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              final items = state.products
                  .where((p) => state.favorites.contains(p.id))
                  .toList();
              if (items.isEmpty) {
                return const AppEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'قائمتك تنتظر ذوقك',
                    message: 'اضغط القلب على أي منتج لتحفظه هنا');
              }
              return GridView.builder(
                  padding: AppDimensions.pagePadding,
                  itemCount: items.length,
                  gridDelegate: AppDimensions.productGrid(context),
                  itemBuilder: (_, i) =>
                      ProductCard(product: items[i], state: state));
            }),
      );
}
