import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  const GlassPanel({super.key, required this.child, this.radius = 28});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: .5)),
          ),
          child: child,
        ),
      );
}

/// The same fixed navigation style for store and administrator accounts.
class FloatingNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;
  const FloatingNavigation(
      {super.key,
      required this.selectedIndex,
      required this.onSelected,
      required this.destinations});
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: .5))),
        child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: destinations),
      );
}

/// Loads tabs on their first visit and preserves forms, scroll, and map position.
class AnimatedTabBody extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const AnimatedTabBody(
      {super.key, required this.index, required this.children});
  @override
  State<AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<AnimatedTabBody> {
  late final visited = <int>{widget.index};
  @override
  void didUpdateWidget(covariant AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) =>
      IndexedStack(index: widget.index, children: [
        for (var i = 0; i < widget.children.length; i++)
          TickerMode(
              enabled: i == widget.index,
              child: RepaintBoundary(
                  child: visited.contains(i)
                      ? widget.children[i]
                      : const SizedBox.shrink())),
      ]);
}
