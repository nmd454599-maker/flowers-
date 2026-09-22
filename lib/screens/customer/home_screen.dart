import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../widgets/app_components.dart';
import '../shared/stores_map_screen.dart';
import 'conversations_screen.dart';
import 'announcements_screen.dart';
import 'addresses_screen.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'home/home_categories.dart';
import 'home/product_post.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});
  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        return Material(
          color: colors.surface,
          child: SafeArea(
            bottom: false,
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    await state.loadCatalog();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تعذر تحديث المنتجات، حاول مجدداً')));
                    }
                  }
                },
                child: CustomScrollView(
                  key: const PageStorageKey('customer-feed'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: colors.surface,
                      centerTitle: false,
                      title: const Text('أزهارنا',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w700)),
                      actions: [
                        IconButton(
                            tooltip: 'الإشعارات',
                            onPressed: () => _open(
                                context, NotificationsScreen(state: state)),
                            icon: const Icon(CupertinoIcons.bell)),
                        IconButton(
                            tooltip: 'المحادثات',
                            onPressed: () => _open(
                                context, ConversationsScreen(state: state)),
                            icon: const Icon(CupertinoIcons.chat_bubble)),
                        IconButton(
                            tooltip: 'السلة',
                            onPressed: () =>
                                _open(context, CartScreen(state: state)),
                            icon: Badge(
                                isLabelVisible: state.cartCount > 0,
                                label: Text('${state.cartCount}'),
                                child: const Icon(CupertinoIcons.bag))),
                        const SizedBox(width: 8),
                      ],
                    ),
                    SliverToBoxAdapter(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        Expanded(
                            child: TextButton.icon(
                          style: TextButton.styleFrom(
                              alignment: AlignmentDirectional.centerStart),
                          onPressed: () =>
                              _open(context, AddressesScreen(state: state)),
                          icon: const Icon(CupertinoIcons.location, size: 18),
                          label: Text('التوصيل إلى ${state.selectedCity}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                        IconButton(
                            tooltip: 'البحث',
                            onPressed: () =>
                                _open(context, SearchScreen(state: state)),
                            icon: const Icon(CupertinoIcons.search)),
                        IconButton(
                            tooltip: 'الخريطة',
                            onPressed: () =>
                                _open(context, StoresMapScreen(state: state)),
                            icon: const Icon(CupertinoIcons.map)),
                        IconButton(
                            tooltip: 'الإعلانات',
                            onPressed: () => _open(
                                context, AnnouncementsScreen(state: state)),
                            icon: const Icon(Icons.campaign_outlined)),
                      ]),
                    )),
                    SliverToBoxAdapter(
                        child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: HomeCategories(
                          onSearch: (query) => _open(context,
                              SearchScreen(state: state, initialQuery: query))),
                    )),
                    const SliverToBoxAdapter(child: Divider(height: 1)),
                    if (state.products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: state.busy
                            ? const Center(child: CircularProgressIndicator())
                            : const AppEmptyState(
                                icon: CupertinoIcons.gift,
                                title: 'هدايا جديدة قريباً',
                                message: 'لا توجد منتجات متاحة حالياً'),
                      )
                    else
                      SliverList.builder(
                        itemCount: state.products.length,
                        itemBuilder: (_, index) => ProductPost(
                            key: ValueKey(state.products[index].id),
                            product: state.products[index], state: state),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            )),
          ),
        );
      });
}
