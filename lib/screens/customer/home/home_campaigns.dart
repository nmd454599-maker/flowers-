import 'package:flutter/material.dart';
import 'dart:async';
import 'home_content.dart';

class HomeCampaigns extends StatefulWidget {
  final ValueChanged<String> onSearch;
  const HomeCampaigns({super.key, required this.onSearch});

  @override
  State<HomeCampaigns> createState() => _HomeCampaignsState();
}

class _HomeCampaignsState extends State<HomeCampaigns> {
  static const _itemExtent = 320.0;
  final _scroll = ScrollController();
  late final Timer _timer;
  final Set<int> _pointers = {};
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _advance());
  }

  void _advance() {
    if (!mounted ||
        !TickerMode.valuesOf(context).enabled ||
        ModalRoute.of(context)?.isCurrent == false ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        !_scroll.hasClients ||
        _pointers.isNotEmpty ||
        _hovered ||
        _scroll.position.isScrollingNotifier.value) {
      return;
    }
    final cycle = homeCategories.length * _itemExtent;
    if (_scroll.offset >= cycle) _scroll.jumpTo(_scroll.offset % cycle);
    final next = ((_scroll.offset / _itemExtent).floor() + 1) * _itemExtent;
    _scroll.animateTo(next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _timer.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return SizedBox(
      height: 104 + (scale - 1) * 40,
      child: MouseRegion(
        onEnter: (_) => _hovered = true,
        onExit: (_) => _hovered = false,
        child: Listener(
          onPointerDown: (event) => _pointers.add(event.pointer),
          onPointerUp: (event) => _pointers.remove(event.pointer),
          onPointerCancel: (event) => _pointers.remove(event.pointer),
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemExtent: _itemExtent,
            // Repeated items make the reset to the first cycle seamless.
            itemBuilder: (context, index) {
              final item = homeCategories[index % homeCategories.length];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Material(
                  color: Color.lerp(
                      theme.colorScheme.surface,
                      item.labelColors.last,
                      theme.brightness == Brightness.dark ? .18 : .28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onSearch(item.query),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: foreground,
                                        fontSize: 15,
                                        height: 1.3,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Flexible(
                                    child: Text('اكتشف الآن',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                            fontSize: 11)),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 16),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        Image.asset(item.image,
                            width: 130,
                            height: double.infinity,
                            filterQuality: FilterQuality.high,
                            fit: BoxFit.cover),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
