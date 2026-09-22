import 'package:flutter/material.dart';
import '../../../core/home_design.dart';

class DesignNavigation extends StatelessWidget {
  const DesignNavigation(
      {super.key,
      required this.design,
      required this.selectedIndex,
      required this.onSelected,
      required this.destinations});
  final HomeDesign design;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bar = NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelBehavior: design == HomeDesign.c
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      destinations: destinations,
    );
    if (design == HomeDesign.b || design == HomeDesign.d) {
      return DecoratedBox(
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant))),
        child: bar,
      );
    }
    return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: ClipRRect(
            borderRadius:
                BorderRadius.circular(design == HomeDesign.a ? 32 : 20),
            child: bar));
  }
}
