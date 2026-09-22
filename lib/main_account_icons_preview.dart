import 'package:flutter/material.dart';
import 'core/color_direction.dart';

void main() => runApp(const AccountIconsPreview());

const accountIconStyles = [
  ('01 · ناعم — قريب من الحالي', 'رسم خطي وخلفية هادئة'),
  ('02 · خطي بلا خلفية', 'رمز واضح وخفيف'),
  ('03 · ممتلئ بلا خلفية', 'رسم مصمت أكثر بروزًا'),
  ('04 · دائرة ناعمة', 'خلفية دائرية بلون خفيف'),
  ('05 · مربع بزوايا خفيفة', 'شكل منتظم بحواف صغيرة'),
  ('06 · دائرة بإطار', 'محيط رفيع دون تعبئة'),
  ('07 · مربع مستدير بإطار', 'إطار فيروزي وحواف لينة'),
  ('08 · ممتلئ بلون قوي', 'رمز أبيض على الفيروزي'),
  ('09 · تدرّج فيروزي ونعناع', 'انتقال لوني داخل الخلفية'),
  ('10 · بطاقة مرتفعة قليلًا', 'خلفية بيضاء وظل خفيف'),
  ('11 · شكل سداسي', 'خلفية هندسية من ستة أضلاع'),
  ('12 · شكل مُعيّن', 'خلفية ماسية والرمز مستقيم'),
];

class AccountIconsPreview extends StatelessWidget {
  const AccountIconsPreview({super.key});
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
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text('أشكال أيقونات حسابي',
                style: ColorDirection.turquoise
                    .theme(Brightness.light)
                    .textTheme
                    .headlineMedium),
            const Text(
                'الحجم ثابت للمقارنة • نفس ألوان فيروزي ونعناع • يمكن دمج رسم وخلفية من نموذجين'),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 950
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              return Wrap(spacing: 18, runSpacing: 18, children: [
                for (var i = 0; i < accountIconStyles.length; i++)
                  SizedBox(
                      width:
                          (constraints.maxWidth - (columns - 1) * 18) / columns,
                      child: _StyleCard(index: i)),
              ]);
            }),
          ]),
        )))),
      );
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Text(accountIconStyles[index].$1,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              Text(accountIconStyles[index].$2,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (var i = 0; i < 3; i++)
                  Column(children: [
                    AccountIconSample(style: index, symbol: i),
                    const SizedBox(height: 10),
                    Text(['العضوية', 'الكوبونات', 'المحفظة'][i],
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
              ]),
            ])),
      );
}

class AccountIconSample extends StatelessWidget {
  const AccountIconSample(
      {super.key, required this.style, required this.symbol});
  final int style, symbol;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final outline = [
      Icons.workspace_premium_outlined,
      Icons.confirmation_number_outlined,
      Icons.account_balance_wallet_outlined
    ];
    final solid = [
      Icons.workspace_premium,
      Icons.confirmation_number,
      Icons.account_balance_wallet
    ];
    final circular = style == 3 || style == 5;
    final framed = style == 5 || style == 6;
    final strong = style == 7 || style == 8;
    final bare = style == 1 || style == 2;
    final decoration = BoxDecoration(
      color: bare || framed
          ? Colors.transparent
          : style == 0
              ? c.surfaceContainerLow
              : style == 7
                  ? c.primary
                  : style == 9
                      ? c.surface
                      : c.primaryContainer.withValues(alpha: .65),
      gradient: style == 8
          ? LinearGradient(
              colors: [c.primary, c.secondary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft)
          : null,
      borderRadius: BorderRadius.circular(circular
          ? 40
          : style == 4
              ? 5
              : 16),
      border: framed ? Border.all(color: c.primary, width: 1.4) : null,
      boxShadow: style == 9
          ? [
              BoxShadow(
                  color: c.primary.withValues(alpha: .16),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]
          : null,
    );
    final icon = Icon(style == 2 ? solid[symbol] : outline[symbol],
        size: 26, color: strong ? c.onPrimary : c.primary);
    if (style == 10 || style == 11) {
      return ClipPath(
          clipper: _Polygon(diamond: style == 11),
          child: Container(
              width: 56, height: 56, color: c.primaryContainer, child: icon));
    }
    return Container(
        width: 56, height: 56, decoration: decoration, child: icon);
  }
}

class _Polygon extends CustomClipper<Path> {
  const _Polygon({required this.diamond});
  final bool diamond;
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    if (diamond)
      return Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close();
    return Path()
      ..moveTo(w * .25, 0)
      ..lineTo(w * .75, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w * .75, h)
      ..lineTo(w * .25, h)
      ..lineTo(0, h / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant _Polygon oldClipper) =>
      oldClipper.diamond != diamond;
}
