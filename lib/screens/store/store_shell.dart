import '../../widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'store_account_screen.dart';
import 'store_dashboard_screen.dart';
import 'store_orders_screen.dart';
import 'store_profile_screen.dart';

class StoreShell extends StatefulWidget {
  final AppState state;
  const StoreShell({super.key, required this.state});
  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      StoreDashboardScreen(state: widget.state, openTab: _openTab),
      StoreOrdersScreen(state: widget.state),
      StoreProfileScreen(
          state: widget.state,
          onBack: () => _openTab(0),
          onOpenSettings: () => _openTab(3)),
      StoreAccountScreen(state: widget.state)
    ];
    return Scaffold(
        body: AnimatedTabBody(index: index, children: pages),
        bottomNavigationBar: FloatingNavigation(
            selectedIndex: index,
            onSelected: _openTab,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined), label: 'الطلبات'),
              NavigationDestination(
                  icon: Icon(Icons.account_box_outlined), label: 'البروفايل'),
              NavigationDestination(
                  icon: Icon(Icons.storefront_outlined), label: 'المتجر')
            ]));
  }

  void _openTab(int value) => setState(() => index = value);
}
