import 'package:flutter/material.dart';
import 'core/color_direction.dart';
import 'core/icon_scale.dart';
import 'screens/customer/home/home_categories.dart';
import 'screens/customer/home/home_search_header.dart';
import 'widgets/glass_panel.dart';

void main() => runApp(const IconPreviewApp());

class IconPreviewApp extends StatelessWidget {
  const IconPreviewApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ColorDirection.turquoise.theme(Brightness.light),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
            body: SafeArea(
                child: SingleChildScrollView(
                    child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text('أحجام الأيقونات — من الحالي إلى الأصغر',
                style: ColorDirection.turquoise
                    .theme(Brightness.light)
                    .textTheme
                    .headlineSmall),
            const Text(
                'نفس الألوان والخط • مساحة الضغط محفوظة • الأرقام للأيقونة والخلفية بوحدات Flutter'),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, space) {
              final count = space.maxWidth >= 1200
                  ? 3
                  : space.maxWidth >= 800
                      ? 2
                      : 1;
              return Wrap(spacing: 16, runSpacing: 16, children: [
                for (final option in IconScale.options)
                  SizedBox(
                      width: (space.maxWidth - (count - 1) * 16) / count,
                      child: _Sample(scale: option)),
              ]);
            }),
          ]),
        )))),
      );
}

class _Sample extends StatefulWidget {
  const _Sample({required this.scale});
  final IconScale scale;
  @override
  State<_Sample> createState() => _SampleState();
}

class _SampleState extends State<_Sample> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scale = widget.scale;
    return Theme(
        data: base.copyWith(
          extensions: [...base.extensions.values, scale],
          navigationBarTheme: base.navigationBarTheme.copyWith(
              iconTheme: WidgetStateProperty.resolveWith((states) =>
                  IconThemeData(
                      size: scale.navigation,
                      color: states.contains(WidgetState.selected)
                          ? base.colorScheme.onPrimaryContainer
                          : base.colorScheme.onSurfaceVariant))),
        ),
        child: Builder(
            builder: (context) => Card(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(children: [
                        Text(scale.label,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                            'الأقسام ${scale.category.toInt()} • الخلفية ${scale.tile.toInt()} • التنقل ${scale.navigation.toInt()}',
                            style: TextStyle(
                                color: base.colorScheme.onSurfaceVariant)),
                        SizedBox(
                            height: 88,
                            child: HomeSearchHeader(onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('معاينة حجم أيقونة البحث'))))
                                .build(context, 0, false)),
                        HomeCategories(onSearch: (query) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('معاينة قسم $query')))),
                        FloatingNavigation(
                            selectedIndex: index,
                            onSelected: (value) =>
                                setState(() => index = value),
                            destinations: const [
                              NavigationDestination(
                                  icon: Icon(Icons.home_outlined),
                                  selectedIcon: Icon(Icons.home),
                                  label: 'الرئيسية'),
                              NavigationDestination(
                                  icon: Icon(Icons.category_outlined),
                                  label: 'التصنيفات'),
                              NavigationDestination(
                                  icon: Icon(Icons.favorite_border),
                                  label: 'المفضلة'),
                              NavigationDestination(
                                  icon: Icon(Icons.receipt_long_outlined),
                                  label: 'الطلبات'),
                              NavigationDestination(
                                  icon: Icon(Icons.person_outline),
                                  label: 'حسابي'),
                            ]),
                      ])),
                )));
  }
}
