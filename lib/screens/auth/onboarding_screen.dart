import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.local_florist_rounded,
                  size: 52,
                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
          const SizedBox(height: 24),
          Text('أزهارنا', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('ورد، هدايا، ولحظات تستحق.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          const SizedBox.square(
              dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      )));
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final Future<void> Function() onComplete;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  bool finishing = false;
  static const content = [
    (
      Icons.local_florist_outlined,
      'اختر أجمل الزهور',
      'باقات وهدايا لكل مناسبة، من متاجر قريبة منك.'
    ),
    (
      Icons.add_location_alt_outlined,
      'هدية تصل إلى من تحب',
      'حدّد عنوان المستلم وأضف رسالة إهداء تعبّر عن مشاعرك.'
    ),
    (
      Icons.local_shipping_outlined,
      'تابع الفرحة حتى الوصول',
      'تابع مراحل تجهيز طلبك وتوصيله من مكان واحد.'
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (finishing) return;
    setState(() => finishing = true);
    try {
      await widget.onComplete();
    } finally {
      if (mounted) setState(() => finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('أزهارنا'), actions: [
          TextButton(
              onPressed: finishing ? null : finish, child: const Text('تخطي'))
        ]),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: PageView.builder(
                  controller: controller,
                  itemCount: content.length,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (context, index) {
                    final item = content[index];
                    return Center(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(48)),
                                      child: Icon(item.$1,
                                          size: 88,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer)),
                                  const SizedBox(height: 40),
                                  Text(item.$2,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                  const SizedBox(height: 16),
                                  Text(item.$3,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge),
                                ])));
                  })),
          Semantics(
              label: 'الصفحة ${page + 1} من 3',
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3,
                      (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: page == i ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: page == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                              borderRadius: BorderRadius.circular(8)))))),
          Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: finishing
                          ? null
                          : page == 2
                              ? finish
                              : () => controller.nextPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut),
                      child: Text(page == 2 ? 'ابدأ الآن' : 'التالي')))),
        ])),
      );
}
