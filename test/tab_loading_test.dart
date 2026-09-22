import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azharna_pro/widgets/glass_panel.dart';

class TabProbe extends StatefulWidget {
  const TabProbe({super.key, required this.onInitialize});
  final VoidCallback onInitialize;
  @override
  State<TabProbe> createState() => _TabProbeState();
}

class _TabProbeState extends State<TabProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInitialize();
  }

  @override
  Widget build(BuildContext context) => const TextField();
}

void main() {
  testWidgets('tabs initialize only on first visit and preserve their draft',
      (tester) async {
    final initialized = [0, 0, 0];
    var selected = 0;
    late StateSetter select;
    await tester
        .pumpWidget(MaterialApp(home: StatefulBuilder(builder: (_, setState) {
      select = setState;
      return Scaffold(
          body: AnimatedTabBody(index: selected, children: [
        for (var i = 0; i < 3; i++)
          TabProbe(onInitialize: () => initialized[i]++),
      ]));
    })));
    expect(initialized, [1, 0, 0]);
    await tester.enterText(find.byType(TextField), 'مسودة محفوظة');
    select(() => selected = 1);
    await tester.pump();
    expect(initialized, [1, 1, 0]);
    select(() => selected = 0);
    await tester.pump();
    expect(initialized, [1, 1, 0]);
    expect(find.text('مسودة محفوظة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
