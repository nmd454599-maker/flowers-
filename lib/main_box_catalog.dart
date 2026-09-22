import 'package:flutter/material.dart';
import 'core/app_theme.dart';

void main() => runApp(const BoxCatalogApp());

const boxChoices = <(String, double, double, int)>[
  ('01 · مربع بزوايا حادة', 2, 2, 0),
  ('02 · مربع بحواف خفيفة', 10, 8, 0),
  ('03 · مربع مستدير', 24, 16, 0),
  ('04 · مستدير جدًا', 44, 32, 0),
  ('05 · مستطيل عريض ومنخفض', 16, 8, 1),
  ('06 · نافذة صغيرة ومختصرة', 16, 10, 2),
  ('07 · بطاقة طويلة', 24, 14, 3),
  ('08 · حقل كبسولي', 28, 60, 0),
  ('09 · حقل بخط سفلي', 12, 0, 4),
  ('10 · حقل ممتلئ بلا إطار', 24, 16, 5),
  ('11 · لوحة سفلية', 28, 12, 6),
  ('12 · صفحة بعرض الشاشة', 0, 12, 7),
];

class BoxCatalogApp extends StatelessWidget {
  const BoxCatalogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
            body: SafeArea(
                child: SingleChildScrollView(
                    child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('اختر شكل النافذة أو مربع الكتابة',
                textAlign: TextAlign.center,
                style: AppTheme.light().textTheme.headlineMedium),
            const Text(
                'نفس خط نسخ العربي والألوان • خيارات قابلة للتعديل حسب الحجم الذي تريده',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, size) {
              final columns = size.maxWidth >= 1000
                  ? 3
                  : size.maxWidth >= 650
                      ? 2
                      : 1;
              return Wrap(spacing: 20, runSpacing: 20, children: [
                for (final option in boxChoices)
                  SizedBox(
                      width: (size.maxWidth - (columns - 1) * 20) / columns,
                      child: BoxChoice(option: option)),
              ]);
            }),
          ]),
        )))),
      );
}

class BoxChoice extends StatelessWidget {
  const BoxChoice({super.key, required this.option});
  final (String, double, double, int) option;
  @override
  Widget build(BuildContext context) {
    final (label, radius, fieldRadius, kind) = option;
    final colors = Theme.of(context).colorScheme;
    final sheet = kind == 6;
    final page = kind == 7;
    final width = kind == 2
        ? 230.0
        : kind == 3
            ? 240.0
            : double.infinity;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Container(
        height: 310,
        padding: EdgeInsets.all(page || sheet ? 0 : 14),
        decoration: BoxDecoration(
            color: colors.outlineVariant.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Align(
            alignment: sheet ? Alignment.bottomCenter : Alignment.center,
            child: Container(
              width: width,
              height: page
                  ? 310
                  : kind == 3
                      ? 280
                      : null,
              padding: EdgeInsets.all(kind == 2 || kind == 1 ? 16 : 24),
              decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: sheet
                      ? BorderRadius.vertical(top: Radius.circular(radius))
                      : BorderRadius.circular(radius)),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (sheet)
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              color: colors.outline)),
                    Text('نوع الحساب',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: kind == 1 ? 8 : 16),
                    Container(
                        height: kind == 3
                            ? 100
                            : kind == 1 || kind == 2
                                ? 44
                                : 58,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: AlignmentDirectional.centerStart,
                        decoration: BoxDecoration(
                            color:
                                colors.primaryContainer.withValues(alpha: .3),
                            borderRadius: kind == 4
                                ? null
                                : BorderRadius.circular(fieldRadius),
                            border: kind == 5
                                ? null
                                : kind == 4
                                    ? Border(
                                        bottom: BorderSide(
                                            color: colors.primary, width: 2))
                                    : Border.all(color: colors.primary)),
                        child: const Text('عميل ذهبي',
                            style: TextStyle(fontSize: 18))),
                    if (page)
                      const Spacer()
                    else
                      SizedBox(height: kind == 1 ? 12 : 20),
                    Row(children: [
                      Expanded(
                          child: Container(
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(24)),
                              child: Text('حفظ',
                                  style: TextStyle(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w700)))),
                      const SizedBox(width: 20),
                      Expanded(
                          child: Text('إلغاء',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.primary))),
                    ]),
                  ]),
            )),
      ),
    ]);
  }
}
