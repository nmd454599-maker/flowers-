import '../../widgets/glass_panel.dart';
import '../../widgets/catalog_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'orders_screen.dart';
import '../../core/app_theme.dart';
import '../../core/market_theme.dart';
import '../../core/home_design.dart';
import 'home/design_home.dart';
import 'home/design_navigation.dart';
import 'home_screen.dart';
import '../../core/font_options.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';

class CustomerShell extends StatefulWidget {
  final AppState state;
  final bool compareDesigns;
  final bool compareFonts;
  final CatalogLayout? catalogLayout;
  final int initialIndex;
  const CustomerShell(
      {super.key,
      required this.state,
      this.compareDesigns = false,
      this.compareFonts = false,
      this.catalogLayout,
      this.initialIndex = 0});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int index = widget.initialIndex;
  HomeDesign design = HomeDesign.a;

  @override
  Widget build(BuildContext context) {
    final pages = [
      widget.compareDesigns
          ? DesignHome(state: widget.state, design: design)
          : HomeScreen(state: widget.state),
      CategoriesScreen(state: widget.state, layout: widget.catalogLayout),
      FavoritesScreen(state: widget.state),
      OrdersScreen(state: widget.state),
      ProfileScreen(state: widget.state),
    ];
    return Theme(
        data: widget.compareDesigns
            ? design.theme(Theme.of(context).brightness)
            : MarketTheme.apply(Theme.of(context)),
        child: Builder(
            builder: (context) => AnimatedBuilder(
                animation: widget.state,
                builder: (context, _) => Scaffold(
                      body: Column(children: [
                        if (widget.compareDesigns || widget.compareFonts)
                          SafeArea(
                              bottom: false,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(children: [
                                  if (!widget.compareDesigns)
                                    const Expanded(child: FontOptions()),
                                  if (widget.compareDesigns)
                                    Expanded(
                                        child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(children: [
                                              for (final option
                                                  in HomeDesign.values)
                                                Padding(
                                                    padding:
                                                        const EdgeInsetsDirectional
                                                            .only(end: 6),
                                                    child: ChoiceChip(
                                                        label:
                                                            Text(option.label),
                                                        selected:
                                                            design == option,
                                                        onSelected: (_) =>
                                                            setState(() =>
                                                                design =
                                                                    option))),
                                            ]))),
                                  if (index != 4) const ThemeModeButton(),
                                ]),
                              )),
                        Expanded(
                            child:
                                AnimatedTabBody(index: index, children: pages)),
                      ]),
                      floatingActionButtonLocation:
                          FloatingActionButtonLocation.startFloat,
                      floatingActionButton: !widget.compareDesigns ||
                              (widget.state.cartCount == 0 &&
                                  widget.state.orders.isEmpty)
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.state.orders.isNotEmpty) ...[
                                      FloatingActionButton.small(
                                        heroTag: 'tracking',
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    OrderTrackingScreen(
                                                        order: widget.state
                                                            .orders.first))),
                                        child: const Icon(
                                            Icons.delivery_dining_rounded),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Badge(
                                      isLabelVisible:
                                          widget.state.cartCount > 0,
                                      label: Text('${widget.state.cartCount}'),
                                      child: FloatingActionButton(
                                        heroTag: 'cart',
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => CartScreen(
                                                    state: widget.state))),
                                        child: const Icon(
                                            Icons.shopping_bag_rounded),
                                      ),
                                    ),
                                  ]),
                            ),
                      bottomNavigationBar: _navigation(
                        selectedIndex: index,
                        onSelected: (value) => setState(() => index = value),
                        destinations: const [
                          NavigationDestination(
                              icon: Icon(CupertinoIcons.house),
                              selectedIcon: Icon(CupertinoIcons.house_fill),
                              label: 'الرئيسية'),
                          NavigationDestination(
                              icon: Icon(Icons.category_outlined),
                              selectedIcon: Icon(Icons.category_rounded),
                              label: 'التصنيفات'),
                          NavigationDestination(
                              icon: Icon(Icons.favorite_border_rounded),
                              selectedIcon: Icon(Icons.favorite_rounded),
                              label: 'المفضلة'),
                          NavigationDestination(
                              icon: Icon(Icons.receipt_long_outlined),
                              selectedIcon: Icon(Icons.receipt_long_rounded),
                              label: 'الطلبات'),
                          NavigationDestination(
                              icon: Icon(CupertinoIcons.person),
                              selectedIcon: Icon(CupertinoIcons.person_fill),
                              label: 'حسابي'),
                        ],
                      ),
                    ))));
  }

  Widget _navigation(
          {required int selectedIndex,
          required ValueChanged<int> onSelected,
          required List<NavigationDestination> destinations}) =>
      widget.compareDesigns
          ? DesignNavigation(
              design: design,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              destinations: destinations)
          : Builder(builder: (context) {
              final colors = Theme.of(context).colorScheme;
              return DecoratedBox(
                decoration: BoxDecoration(
                    color: colors.surface,
                    border:
                        Border(top: BorderSide(color: colors.outlineVariant))),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 68,
                    elevation: 0,
                    backgroundColor: colors.surface,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: Colors.transparent,
                    iconTheme: WidgetStateProperty.resolveWith((states) =>
                        IconThemeData(
                            size: 26,
                            color: states.contains(WidgetState.selected)
                                ? colors.onSurface
                                : colors.onSurfaceVariant)),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) =>
                        TextStyle(
                            fontFamily: AppTheme.font.value,
                            fontSize: 11,
                            fontWeight: states.contains(WidgetState.selected)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: colors.onSurface)),
                  ),
                  child: NavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onSelected,
                      destinations: destinations),
                ),
              );
            });
}
