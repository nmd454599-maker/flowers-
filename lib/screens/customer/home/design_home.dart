import 'package:flutter/material.dart';
import '../../../core/home_design.dart';
import '../../../models/models.dart';
import '../../../state/app_state.dart';
import '../../../widgets/product_photo.dart';
import '../../shared/stores_map_screen.dart';
import '../addresses_screen.dart';
import '../announcements_screen.dart';
import '../cart_screen.dart';
import '../conversations_screen.dart';
import '../notifications_screen.dart';
import '../product_details_screen.dart';
import '../search_screen.dart';
import '../store_details_screen.dart';
import 'home_content.dart';
import 'home_delivery_header.dart';
import 'home_store_list.dart';

/// Four compositions sharing the live catalog and existing application actions.
class DesignHome extends StatelessWidget {
  const DesignHome({super.key, required this.state, required this.design});
  final AppState state;
  final HomeDesign design;

  void _open(BuildContext context, Widget page) {
    final theme = Theme.of(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => Theme(data: theme, child: page)));
  }

  void _search(BuildContext context, [String query = '']) =>
      _open(context, SearchScreen(state: state, initialQuery: query));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final gap = design == HomeDesign.b
              ? 28.0
              : design == HomeDesign.d
                  ? 12.0
                  : 20.0;
          final intro = _intro(context);
          final search = _searchBar(context);
          final categories = _collections(context, homeCategories);
          final campaigns = _campaigns(context);
          final occasions =
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _heading(context, 'تبحث عن هدية؟', () => _search(context)),
            _collections(context, homeOccasions, occasions: true),
          ]);
          final featured = Column(children: [
            _heading(context, 'مختارات تستحق الإهداء', () => _search(context)),
            _products(context, state.products.take(8).toList()),
          ]);
          final sections = switch (design) {
            HomeDesign.a => [
                intro,
                search,
                categories,
                campaigns,
                occasions,
                featured
              ],
            HomeDesign.b => [
                intro,
                campaigns,
                search,
                categories,
                featured,
                occasions
              ],
            HomeDesign.c => [
                search,
                intro,
                categories,
                occasions,
                campaigns,
                featured
              ],
            HomeDesign.d => [
                search,
                categories,
                campaigns,
                intro,
                featured,
                occasions
              ],
          };
          return SafeArea(
              bottom: false,
              child: CustomScrollView(
                key: PageStorageKey('home-${design.name}'),
                slivers: [
                  SliverToBoxAdapter(
                      child: HomeDeliveryHeader(
                    city: state.selectedCity,
                    cartCount: state.cartCount,
                    onAddressTap: () =>
                        _open(context, AddressesScreen(state: state)),
                    onNotificationsTap: () =>
                        _open(context, NotificationsScreen(state: state)),
                    onCartTap: () => _open(context, CartScreen(state: state)),
                  )),
                  SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: gap),
                      sliver: SliverList.list(children: [
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          ActionChip(
                              avatar: const Icon(Icons.map_outlined),
                              label: const Text('الخريطة'),
                              onPressed: () => _open(
                                  context, StoresMapScreen(state: state))),
                          ActionChip(
                              avatar: const Icon(Icons.chat_outlined),
                              label: const Text('المحادثات'),
                              onPressed: () => _open(
                                  context, ConversationsScreen(state: state))),
                          ActionChip(
                              avatar: const Icon(Icons.campaign_outlined),
                              label: const Text('الإعلانات'),
                              onPressed: () => _open(
                                  context, AnnouncementsScreen(state: state))),
                        ]),
                        SizedBox(height: gap),
                        for (final section in sections) ...[
                          section,
                          SizedBox(height: gap)
                        ],
                        _heading(
                            context,
                            'متاجر قريبة منك',
                            () =>
                                _open(context, StoresMapScreen(state: state))),
                        HomeStoreList(
                            stores: state.stores,
                            products: state.products,
                            onStoreTap: (store) => _open(
                                context,
                                StoreDetailsScreen(
                                    store: store, state: state))),
                        for (final category in state.products
                            .map((p) => p.category)
                            .toSet()) ...[
                          _heading(context, category,
                              () => _search(context, category)),
                          _products(
                              context,
                              state.products
                                  .where((p) => p.category == category)
                                  .take(8)
                                  .toList()),
                        ],
                        const SizedBox(height: 100),
                      ])),
                ],
              ));
        },
      );

  Widget _intro(BuildContext context) => Column(
        crossAxisAlignment: design == HomeDesign.b
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(design.title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              switch (design) {
                HomeDesign.a => 'خلّي يومهم يزهر.',
                HomeDesign.b => 'فنّ الهدية،\nوجمال التفاصيل.',
                HomeDesign.c => 'فرحة لكل مناسبة!',
                HomeDesign.d => 'هديتك، على ذوقك.',
              },
              textAlign:
                  design == HomeDesign.b ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('ورد، هدايا، وحلويات لمن تحب.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );

  Widget _searchBar(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SearchBar(
      key: const ValueKey('design-search'),
      hintText: 'ابحث عن هدية أو متجر',
      readOnly: true,
      onTap: () => _search(context),
      leading: Icon(Icons.search_rounded, color: c.primary),
      elevation: WidgetStatePropertyAll(design == HomeDesign.c ? 2 : 0),
      backgroundColor: WidgetStatePropertyAll(
          design == HomeDesign.b ? c.surface : c.surfaceContainerHigh),
      side: WidgetStatePropertyAll(design == HomeDesign.b
          ? BorderSide(color: c.outline)
          : BorderSide.none),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              design == HomeDesign.a ? 40 : design.radius))),
      trailing: [
        IconButton(
            tooltip: 'فتح البحث',
            onPressed: () => _search(context),
            icon: const Icon(Icons.arrow_back_rounded))
      ],
    );
  }

  Widget _heading(BuildContext context, String title, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 12),
        child: Row(children: [
          if (design == HomeDesign.c) ...[
            Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8)
          ],
          Expanded(
              child:
                  Text(title, style: Theme.of(context).textTheme.titleLarge)),
          IconButton(
              tooltip: 'عرض الكل: $title',
              onPressed: onTap,
              icon: const Icon(Icons.arrow_back_rounded)),
        ]),
      );

  Widget _collections(BuildContext context, List<HomeCollection> items,
      {bool occasions = false}) {
    final c = Theme.of(context).colorScheme;
    if (design == HomeDesign.d) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final item in items)
          ActionChip(
              label: Text(item.title),
              avatar: Icon(
                  occasions
                      ? Icons.celebration_outlined
                      : Icons.local_florist_outlined,
                  size: 18),
              onPressed: () => _search(context, item.query))
      ]);
    }
    Widget tile(HomeCollection item) => Material(
          color: design == HomeDesign.c
              ? c.secondaryContainer
              : c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(design.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => _search(context, item.query),
              child: Column(children: [
                ClipRRect(
                    borderRadius:
                        BorderRadius.circular(design == HomeDesign.a ? 80 : 0),
                    child: Image.asset(item.image,
                        height: occasions ? 80 : 92,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high)),
                Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: design == HomeDesign.c
                                ? c.onSecondaryContainer
                                : c.onSurface,
                            fontWeight: FontWeight.w500))),
              ])),
        );
    if (design == HomeDesign.c && !occasions) {
      return LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 700 ? 4 : 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final item in items)
            SizedBox(
                width: (constraints.maxWidth - (count - 1) * 12) / count,
                child: tile(item))
        ]);
      });
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
        height: (occasions ? 100 : 112) + 56 * scale,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
                width: design == HomeDesign.b ? 170 : 116,
                child: tile(items[i]))));
  }

  Widget _campaigns(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget banner(int i) {
      final image = Image.asset(
          i == 0
              ? 'assets/images/premium_hero.png'
              : 'assets/images/product_gift.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: design == HomeDesign.b ? 220 : 130,
          filterQuality: FilterQuality.high);
      final copy = Padding(
          padding: EdgeInsets.all(design == HomeDesign.d ? 12 : 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i == 0 ? 'من أزهارنا، بكل حب' : 'تفاصيل تصنع الفرحة',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(i == 0 ? 'هدية صغيرة، أثر كبير.' : 'لكل شخص هدية تشبهه.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: Text(i == 0 ? 'اكتشف الورد' : 'اكتشف الهدايا',
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.arrow_back_rounded)
            ]),
          ]));
      return Material(
          color: i == 0 ? c.primaryContainer : c.tertiaryContainer,
          borderRadius: BorderRadius.circular(design.radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => _search(context, i == 0 ? 'الزهور' : 'الهدايا'),
              child: DefaultTextStyle.merge(
                  style: TextStyle(
                      color: i == 0
                          ? c.onPrimaryContainer
                          : c.onTertiaryContainer),
                  child: design == HomeDesign.d
                      ? Row(children: [
                          SizedBox(width: 84, child: image),
                          Expanded(child: copy)
                        ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [image, copy]))));
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 620 ||
          design == HomeDesign.c && constraints.maxWidth >= 360) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: design == HomeDesign.b ? 3 : 1, child: banner(0)),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: banner(1)),
        ]);
      }
      return Column(
          children: [banner(0), const SizedBox(height: 12), banner(1)]);
    });
  }

  Widget _products(BuildContext context, List<Product> items) {
    if (items.isEmpty) {
      return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.busy
              ? 'نجهّز لك أجمل الهدايا…'
              : 'ستظهر الهدايا المتاحة هنا'));
    }
    if (design == HomeDesign.d) {
      return Column(children: [
        for (final item in items)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _product(context, item, horizontal: true))
      ]);
    }
    if (design == HomeDesign.b) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return SizedBox(
          height: 480 + (scale - 1) * 180,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, i) => SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width - 70).clamp(230, 340),
                  child: _product(context, items[i]))));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final count = (constraints.maxWidth / (scale > 1.3 ? 240 : 165))
          .floor()
          .clamp(1, 4);
      return Wrap(
          spacing: 12,
          runSpacing: design == HomeDesign.a ? 20 : 12,
          children: [
            for (final item in items)
              SizedBox(
                  width: (constraints.maxWidth - (count - 1) * 12) / count,
                  child: _product(context, item))
          ]);
    });
  }

  Widget _product(BuildContext context, Product p, {bool horizontal = false}) {
    final c = Theme.of(context).colorScheme;
    final favorite = state.favorites.contains(p.id);
    final photo = Stack(children: [
      AspectRatio(
          aspectRatio: design == HomeDesign.b ? 1.1 : 1,
          child: ProductPhoto(product: p)),
      Positioned(
          top: 4,
          left: 4,
          child: IconButton.filledTonal(
              tooltip: favorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              onPressed: () => state.toggleFavorite(p),
              icon: Icon(favorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded))),
    ]);
    final details = Padding(
        padding: EdgeInsets.all(design == HomeDesign.b ? 18 : 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('★ ${p.rating} • توصيل اليوم',
              style: TextStyle(color: c.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${p.price} د.ع',
                    style: TextStyle(
                        color: c.primary, fontWeight: FontWeight.w700)),
                IconButton.filled(
                    tooltip: 'إضافة إلى السلة: ${p.name}',
                    onPressed: () => state.addToCart(p),
                    icon: const Icon(Icons.add_rounded)),
              ]),
        ]));
    return Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(design.radius),
            side: design == HomeDesign.b || design == HomeDesign.d
                ? BorderSide(color: c.outlineVariant)
                : BorderSide.none),
        child: InkWell(
            onTap: () =>
                _open(context, ProductDetailsScreen(product: p, state: state)),
            child: horizontal
                ? Row(children: [
                    SizedBox(width: 112, child: photo),
                    Expanded(child: details)
                  ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [photo, details])));
  }
}
