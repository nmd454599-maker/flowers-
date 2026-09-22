import 'package:flutter/material.dart';

class IraqGovernorate {
  final String name;
  final Offset point;
  const IraqGovernorate(this.name, this.point);
}

const iraqGovernorates = <IraqGovernorate>[
  IraqGovernorate('دهوك', Offset(.40, .11)),
  IraqGovernorate('أربيل', Offset(.56, .18)),
  IraqGovernorate('السليمانية', Offset(.72, .25)),
  IraqGovernorate('نينوى', Offset(.34, .24)),
  IraqGovernorate('كركوك', Offset(.55, .32)),
  IraqGovernorate('صلاح الدين', Offset(.46, .40)),
  IraqGovernorate('ديالى', Offset(.67, .44)),
  IraqGovernorate('الأنبار', Offset(.22, .48)),
  IraqGovernorate('بغداد', Offset(.54, .51)),
  IraqGovernorate('بابل', Offset(.50, .59)),
  IraqGovernorate('كربلاء', Offset(.42, .57)),
  IraqGovernorate('النجف', Offset(.43, .67)),
  IraqGovernorate('واسط', Offset(.65, .61)),
  IraqGovernorate('القادسية', Offset(.54, .69)),
  IraqGovernorate('ميسان', Offset(.74, .72)),
  IraqGovernorate('المثنى', Offset(.55, .80)),
  IraqGovernorate('ذي قار', Offset(.65, .79)),
  IraqGovernorate('البصرة', Offset(.76, .88)),
];

class IraqMapPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final bool showGovernorateList;

  const IraqMapPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.showGovernorateList = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.08,
          child: LayoutBuilder(
            builder: (context, size) => Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _IraqPainter(
                      primary: colors.primary,
                      selected: selected,
                    ),
                  ),
                ),
                ...iraqGovernorates.map((governorate) {
                  final active = governorate.name == selected;
                  return Positioned(
                    left: governorate.point.dx * size.maxWidth - 13,
                    top: governorate.point.dy * size.maxHeight - 13,
                    child: Semantics(
                      button: true,
                      label: governorate.name,
                      child: GestureDetector(
                        onTap: () => onSelected(governorate.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: active ? 28 : 22,
                          height: active ? 28 : 22,
                          decoration: BoxDecoration(
                            color: active
                                ? colors.secondary
                                : Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active ? Colors.white : colors.primary,
                              width: active ? 3 : 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33000000), blurRadius: 7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Positioned(
                  right: 14,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      selected.isEmpty ? 'اختر محافظة' : selected,
                      style: TextStyle(
                          color: colors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showGovernorateList) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: iraqGovernorates.map((governorate) {
              final active = governorate.name == selected;
              return ChoiceChip(
                label: Text(governorate.name),
                selected: active,
                onSelected: (_) => onSelected(governorate.name),
                showCheckmark: false,
                avatar: active
                    ? const Icon(Icons.location_on_rounded, size: 17)
                    : null,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _IraqPainter extends CustomPainter {
  final Color primary;
  final String selected;
  const _IraqPainter({required this.primary, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    final outline = Path()
      ..moveTo(size.width * .37, size.height * .05)
      ..lineTo(size.width * .57, size.height * .09)
      ..lineTo(size.width * .68, size.height * .17)
      ..lineTo(size.width * .83, size.height * .25)
      ..lineTo(size.width * .76, size.height * .39)
      ..lineTo(size.width * .82, size.height * .53)
      ..lineTo(size.width * .76, size.height * .65)
      ..lineTo(size.width * .84, size.height * .88)
      ..lineTo(size.width * .72, size.height * .96)
      ..lineTo(size.width * .59, size.height * .87)
      ..lineTo(size.width * .45, size.height * .83)
      ..lineTo(size.width * .32, size.height * .69)
      ..lineTo(size.width * .12, size.height * .58)
      ..lineTo(size.width * .08, size.height * .42)
      ..lineTo(size.width * .21, size.height * .31)
      ..lineTo(size.width * .28, size.height * .16)
      ..close();

    canvas.drawShadow(outline, primary.withValues(alpha: .24), 18, true);
    canvas.drawPath(
      outline,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            primary.withValues(alpha: .18),
            primary.withValues(alpha: .06)
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = primary.withValues(alpha: .55),
    );

    final river = Paint()
      ..color = const Color(0xFF43A6C6).withValues(alpha: .55)
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tigris = Path()
      ..moveTo(size.width * .58, size.height * .17)
      ..cubicTo(size.width * .56, size.height * .36, size.width * .67,
          size.height * .59, size.width * .73, size.height * .88);
    final euphrates = Path()
      ..moveTo(size.width * .27, size.height * .31)
      ..cubicTo(size.width * .34, size.height * .46, size.width * .44,
          size.height * .57, size.width * .70, size.height * .87);
    canvas.drawPath(tigris, river);
    canvas.drawPath(euphrates, river);

    final compass = Paint()
      ..color = primary.withValues(alpha: .55)
      ..strokeWidth = 1.5;
    canvas.drawLine(p(.91, .12), p(.91, .24), compass);
    final arrow = Path()
      ..moveTo(size.width * .91, size.height * .08)
      ..lineTo(size.width * .885, size.height * .14)
      ..lineTo(size.width * .935, size.height * .14)
      ..close();
    canvas.drawPath(arrow, compass);
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
            color: primary, fontWeight: FontWeight.w800, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, p(.895, .245));
  }

  @override
  bool shouldRepaint(covariant _IraqPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.selected != selected;
}
