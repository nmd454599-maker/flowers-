import '../../domain/catalog/catalog_search.dart';
import '../../core/design_tokens.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/product_card.dart';
import 'store_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final AppState state;
  final String initialQuery;
  const SearchScreen({super.key, required this.state, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    controller.text = query;
  }

  static const suggestions = ['ورد', 'هدايا', 'عطور', 'شوكولاتة', 'بالونات'];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  static const _catalogSearch = CatalogSearch();
  List<Product> get products =>
      _catalogSearch.products(widget.state.products, query);
  List<Store> get stores => _catalogSearch.stores(widget.state.stores, query);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('اكتشف ما تحب')),
        body: CustomScrollView(slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            toolbarHeight: 78,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            titleSpacing: 18,
            title: TextField(
              controller: controller,
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'ابحث عن ورد، هدية أو متجر',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? const Icon(Icons.tune_rounded)
                    : IconButton(
                        onPressed: () {
                          controller.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('اقتراحات سريعة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions
                      .map((value) => ActionChip(
                            avatar: const Icon(Icons.auto_awesome_rounded,
                                size: 16),
                            label: Text(value),
                            onPressed: () {
                              controller.text = value;
                              setState(() => query = value);
                            },
                          ))
                      .toList()),
              if (stores.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('المتاجر',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...stores.map((store) => Card(
                        child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          child: Text(store.emoji)),
                      title: Text(store.name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          '${store.city} • ${store.deliveryMinutes} دقيقة'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StoreDetailsScreen(
                                  store: store, state: widget.state))),
                    ))),
              ],
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: Text(query.isEmpty ? 'مختارة لك' : 'نتائج المنتجات',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800))),
                Text('${products.length} نتيجة',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            ]),
          )),
          if (products.isEmpty)
            SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('لم نجد نتيجة مطابقة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('جرّب كلمة أقصر أو قسمًا مختلفًا',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ])))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              sliver: SliverGrid.builder(
                itemCount: products.length,
                gridDelegate: AppDimensions.productGrid(context),
                itemBuilder: (_, index) =>
                    ProductCard(product: products[index], state: widget.state),
              ),
            ),
        ]),
      );
}
