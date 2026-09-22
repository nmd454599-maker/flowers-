import 'package:flutter/material.dart';

/// The large floral banner from the original storefront.
class ClassicHomeHero extends StatelessWidget {
  const ClassicHomeHero({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: const Color(0xFF005970),
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 236 + (scale - 1) * 140,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/premium_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  filterQuality: FilterQuality.high),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Color(0xFF005970),
                      Color(0xF0007890),
                      Color(0x00007890)
                    ],
                    stops: [0, .38, .85],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('من أزهارنا، بكل حب',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                    const Spacer(),
                    const Text('هدية صغيرة،\nأثر كبير.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        foregroundColor: const Color(0xFF005970),
                        backgroundColor: const Color(0xFFE5F5F8),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('اكتشف الورد'),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
