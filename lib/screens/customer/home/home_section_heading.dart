import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HomeSectionHeading extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const HomeSectionHeading(
      {super.key, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700))),
        IconButton(
            tooltip: 'عرض الكل: $title',
            onPressed: onTap,
            icon: const Icon(CupertinoIcons.arrow_left, size: 18))
      ]));
}
