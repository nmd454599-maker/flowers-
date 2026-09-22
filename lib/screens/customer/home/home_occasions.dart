import 'package:flutter/material.dart';
import 'home_collection_tile.dart';
import 'home_content.dart';

class HomeOccasions extends StatelessWidget {
  final ValueChanged<String> onSearch;
  const HomeOccasions({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 112,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: homeOccasions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => SizedBox(
            width: 98,
            child: HomeCollectionTile(
              collection: homeOccasions[i],
              onTap: () => onSearch(homeOccasions[i].query),
            ),
          ),
        ),
      );
}
