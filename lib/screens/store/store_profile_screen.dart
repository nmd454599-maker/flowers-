import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../customer/store_details_screen.dart';

/// Public storefront for both the merchant tab and standalone routes.
class StoreProfileScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback? onBack, onOpenSettings;
  const StoreProfileScreen(
      {super.key, required this.state, this.onBack, this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final user = state.user;
    final id = user?.storeId;
    if (user == null || id == null || id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('بروفايل المتجر')),
        body: const Center(child: Text('أكمل تسجيل المتجر أولاً')),
      );
    }
    Store? store;
    for (final item in state.stores) {
      if (item.id == id) store = item;
    }
    store ??= Store(
        id: id,
        name: user.name,
        city: state.selectedCity,
        rating: 0,
        emoji: '🏪',
        minOrder: 0,
        deliveryMinutes: 0);
    return StoreDetailsScreen(
        store: store,
        state: state,
        onBack: onBack,
        onOpenSettings: onOpenSettings);
  }
}
