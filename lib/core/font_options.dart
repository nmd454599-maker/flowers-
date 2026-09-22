import 'package:flutter/material.dart';
import 'app_theme.dart';

const fontOptions = <String, String>{
  'Tajawal': 'A · تجوال',
  'Cairo': 'B · القاهرة',
  'IBMPlexSansArabic': 'C · IBM Plex',
  'NotoNaskhArabic': 'D · نسخ',
};

class FontOptions extends StatelessWidget {
  const FontOptions({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: AppTheme.font,
        builder: (context, selected, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final font in fontOptions.entries)
              Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                      label: Text(font.value,
                          style: TextStyle(fontFamily: font.key)),
                      selected: selected == font.key,
                      onSelected: (_) => AppTheme.font.value = font.key)),
          ]),
        ),
      );
}
