import 'package:flutter/material.dart';
import 'home_content.dart';

class HomeCollectionTile extends StatelessWidget {
  final HomeCollection collection;
  final VoidCallback onTap;

  const HomeCollectionTile({
    super.key,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
            builder: (context, constraints) => Ink.image(
                  image: ResizeImage(AssetImage(collection.image),
                      width: ((constraints.hasBoundedWidth
                                  ? constraints.maxWidth
                                  : 384) *
                              MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(64, 8192)),
                  fit: BoxFit.cover,
                  child: InkWell(
                    onTap: onTap,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: .95),
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: .85)
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4038252A),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          collection.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
      );
}
