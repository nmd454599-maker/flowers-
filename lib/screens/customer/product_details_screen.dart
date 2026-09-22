import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image_gallery.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'store_details_screen.dart';
import '../shared/store_chat_screen.dart';
import '../../core/product_assets.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final AppState state;
  const ProductDetailsScreen(
      {super.key, required this.product, required this.state});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product get product => widget.product;
  AppState get state => widget.state;
  int quantity = 1;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final favorite = state.favorites.contains(product.id);
          Store? store;
          for (final item in state.stores) {
            if (item.id == product.storeId) store = item;
          }
          final productStore = store;
          final category = product.category.trim().toLowerCase();
          final similar = state.products
              .where((item) =>
                  item.id != product.id &&
                  category.isNotEmpty &&
                  item.category.trim().toLowerCase() == category)
              .toList();
          return Scaffold(
            bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(children: [
                    DecoratedBox(
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          IconButton(
                              tooltip: 'تقليل الكمية',
                              onPressed: quantity > 1
                                  ? () => setState(() => quantity--)
                                  : null,
                              icon: const Icon(Icons.remove)),
                          Text('$quantity',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                              tooltip: 'زيادة الكمية',
                              onPressed: () => setState(() => quantity++),
                              icon: const Icon(Icons.add)),
                        ])),
                    const SizedBox(width: 10),
                    Expanded(
                        child: FilledButton(
                            onPressed: () {
                              for (var i = 0; i < quantity; i++) {
                                state.addToCart(product);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('أضيف المنتج إلى السلة')));
                            },
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                    'أضف إلى السلة • ${product.price * quantity} د.ع',
                                    textAlign: TextAlign.center)))),
                  ]),
                )),
            body: CustomScrollView(slivers: [
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                leading: Padding(
                    padding: const EdgeInsets.all(7),
                    child: IconButton.filledTonal(
                        tooltip: 'رجوع',
                        onPressed: () => Navigator.pop(context),
                        icon: const BackButtonIcon())),
                actions: [
                  Padding(
                      padding: const EdgeInsets.all(7),
                      child: IconButton.filledTonal(
                          onPressed: () => state.toggleFavorite(product),
                          icon: Icon(
                              favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favorite
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary)))
                ],
              ),
              SliverToBoxAdapter(child: ProductImageGallery(product: product)),
              SliverToBoxAdapter(
                  child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                borderRadius: BorderRadius.circular(99)),
                            child: Text(product.category,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700))),
                        const Spacer(),
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB547), size: 20),
                        Text(' ${product.rating}',
                            style: const TextStyle(fontWeight: FontWeight.w700))
                      ]),
                      const SizedBox(height: 14),
                      Text(product.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (productStore != null)
                        Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.storefront_outlined),
                              title: Text(productStore.name),
                              subtitle: const Text(
                                  'زيارة المتجر • المنتجات والفيديوهات'),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => StoreDetailsScreen(
                                          store: productStore, state: state))),
                            )),
                      const SizedBox(height: 7),
                      if (productStore != null &&
                          state.user?.role == UserRole.customer)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('محادثة المتجر عن المنتج'),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => StoreChatScreen(
                                        state: state,
                                        conversation: {
                                          'storeId': productStore.id,
                                          'storeName': productStore.name,
                                          'customerId': state.user!.id,
                                          'customerName': state.user!.name,
                                        },
                                        initialText:
                                            'استفسار عن ${product.name}\nالسعر: ${product.price} د.ع',
                                        initialImage: product.photos.isEmpty
                                            ? productImage(product.id)
                                            : product.photos.first,
                                      ))),
                        ),
                      Text('${product.price} د.ع',
                          style: TextStyle(
                              fontSize: 23,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 20),
                      const Row(children: [
                        Expanded(
                            child: _Feature(Icons.schedule_rounded,
                                'تجهيز سريع', '30–45 دقيقة')),
                        SizedBox(width: 10),
                        Expanded(
                            child: _Feature(Icons.local_shipping_outlined,
                                'توصيل آمن', 'حتى باب المنزل'))
                      ]),
                      const SizedBox(height: 24),
                      const Text('تفاصيل الهدية',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 7),
                      Text(product.description,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.7)),
                      const SizedBox(height: 20),
                      const Card(
                          child: ListTile(
                              leading: Icon(Icons.card_giftcard_rounded),
                              title: Text('أضف لمستك الخاصة'),
                              subtitle: Text(
                                  'يمكنك كتابة بطاقة الإهداء واختيار المستلم عند إتمام الطلب'))),
                      const SizedBox(height: 24),
                    ]),
              )),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text('منتجات مشابهة (${similar.length})',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              if (similar.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: state.busy
                        ? const Center(child: CircularProgressIndicator())
                        : Text('لا توجد منتجات مشابهة متاحة حالياً',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid(
                    key: const ValueKey('similar-products'),
                    gridDelegate: AppDimensions.productGrid(context),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(
                          key: ValueKey('similar-${similar[index].id}'),
                          product: similar[index],
                          state: state),
                      childCount: similar.length,
                    ),
                  ),
                ),
            ]),
          );
        },
      );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _Feature(this.icon, this.title, this.detail);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerLow)),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Text(detail,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant))
        ]))
      ]));
}
