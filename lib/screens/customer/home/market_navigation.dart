import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MarketNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const MarketNavigation(
      {super.key, required this.selectedIndex, required this.onSelected});

  static const labels = [
    'الرئيسية',
    'المحفوظات',
    'الخريطة',
    'الرسائل',
    'حسابي'
  ];
  static const icons = [
    CupertinoIcons.house,
    CupertinoIcons.heart,
    CupertinoIcons.building_2_fill,
    CupertinoIcons.chat_bubble_2,
    CupertinoIcons.person
  ];
  static const selectedIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.heart_fill,
    CupertinoIcons.building_2_fill,
    CupertinoIcons.chat_bubble_2_fill,
    CupertinoIcons.person_fill
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: colors.surface,
          border:
              Border(top: BorderSide(color: colors.outlineVariant, width: .5))),
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
              child: Row(children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                      child: Semantics(
                    selected: selectedIndex == i,
                    button: true,
                    label: labels[i],
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => onSelected(i),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      selectedIndex == i
                                          ? selectedIcons[i]
                                          : icons[i],
                                      size: 24,
                                      color: selectedIndex == i
                                          ? colors.primary
                                          : colors.onSurfaceVariant),
                                  const SizedBox(height: 4),
                                  Text(labels[i],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 10,
                                          height: 1.1,
                                          fontWeight: selectedIndex == i
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: selectedIndex == i
                                              ? colors.primary
                                              : colors.onSurfaceVariant)),
                                ])),
                      ),
                    ),
                  )),
              ]))),
    );
  }
}
