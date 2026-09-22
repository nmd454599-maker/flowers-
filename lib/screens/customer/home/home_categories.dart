import 'package:flutter/material.dart';
import 'home_content.dart';

class HomeCategories extends StatelessWidget {
  final ValueChanged<String> onSearch;
  const HomeCategories({super.key, required this.onSearch});

  static const icons = [
    Icons.local_florist_outlined,
    Icons.card_giftcard_rounded,
    Icons.cake_outlined,
    Icons.spa_outlined,
    Icons.celebration_outlined,
    Icons.chair_outlined,
    Icons.watch_outlined,
    Icons.favorite_border_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return SizedBox(
      height: 120 + (scale - 1) * 32,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: homeCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 88,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onSearch(homeCategories[i].query),
            child: Column(children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 1.5),
                ),
                child: ClipOval(
                    child: Image.asset(homeCategories[i].image,
                        cacheWidth:
                            (76 * MediaQuery.devicePixelRatioOf(context))
                                .ceil(),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high)),
              ),
              const SizedBox(height: 10),
              Text(homeCategories[i].title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, height: 1.3, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }
}
