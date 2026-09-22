import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../state/app_state.dart';
import '../../../widgets/product_photo.dart';
import 'product_post_media.dart';
import '../product_details_screen.dart';
import '../store_details_screen.dart';

class ProductPost extends StatelessWidget {
  const ProductPost({super.key, required this.product, required this.state});
  final Product product;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final store =
        state.stores.where((s) => s.id == product.storeId).firstOrNull;
    final favorite = state.favorites.contains(product.id);
    void details() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ProductDetailsScreen(product: product, state: state)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox.square(
            dimension: 40,
            child: ClipOval(child: ProductPhoto(product: product))),
        title: Text(store?.name ?? product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        subtitle: Text(
            store == null
                ? product.category
                : '${store.city} · ${product.category}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: store == null
            ? details
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        StoreDetailsScreen(store: store, state: state))),
      ),
      ProductPostMedia(
        key: ValueKey(product.id),
        product: product,
        onOpen: details,
        onSave: () {
          if (!state.favorites.contains(product.id)) {
            state.toggleFavorite(product);
          }
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Row(children: [
          IconButton(
            tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            isSelected: favorite,
            onPressed: () => state.toggleFavorite(product),
            icon: Icon(
                favorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                size: 27,
                color: favorite ? const Color(0xFFE53955) : colors.onSurface),
          ),
          IconButton(
              tooltip: 'تفاصيل المنتج',
              onPressed: details,
              icon: const Icon(CupertinoIcons.info_circle, size: 25)),
          const SizedBox(width: 12),
          Expanded(
              child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Tooltip(
                    message: 'إضافة إلى السلة: ${product.name}',
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(48, 44),
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        state.addToCart(product);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                              content: Text('تمت الإضافة إلى السلة'),
                              duration: Duration(seconds: 2)));
                      },
                      icon: const Icon(CupertinoIcons.bag_badge_plus, size: 19),
                      label:
                          const Text('أضف للسلة', textAlign: TextAlign.center),
                    ),
                  ))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${product.price} د.ع',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              if (product.rating > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded,
                      size: 17, color: Color(0xFFAF7100)),
                  const SizedBox(width: 4),
                  Text('${product.rating}',
                      style: TextStyle(color: colors.onSurfaceVariant)),
                ]),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
              onTap: details,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              )),
          if (product.description.isNotEmpty)
            Text(product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: colors.onSurfaceVariant)),
        ]),
      ),
      const Divider(height: 1),
    ]);
  }
}
