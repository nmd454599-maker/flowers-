import 'package:flutter/material.dart';
import 'core/color_direction.dart';
import 'data/demo_repository.dart';
import 'screens/customer/customer_shell.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(repository: DemoRepository());
  await state.loadCatalog();
  runApp(ColorPreviewApp(state: state));
}

class ColorPreviewApp extends StatefulWidget {
  const ColorPreviewApp(
      {super.key,
      required this.state,
      this.initialDirection = ColorDirection.turquoise});
  final AppState state;
  final ColorDirection initialDirection;
  @override
  State<ColorPreviewApp> createState() => _ColorPreviewAppState();
}

class _ColorPreviewAppState extends State<ColorPreviewApp> {
  late ColorDirection selected = widget.initialDirection;
  bool dark = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: selected.theme(dark ? Brightness.dark : Brightness.light),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
            body: Column(children: [
          SafeArea(
              bottom: false,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                        child: DropdownButton<ColorDirection>(
                            isExpanded: true,
                            value: selected,
                            items: [
                              for (final palette in ColorDirection.values)
                                DropdownMenuItem(
                                    value: palette,
                                    child: Text(
                                        '${palette.number} · ${palette.label}'))
                            ],
                            onChanged: (palette) =>
                                setState(() => selected = palette!))),
                    IconButton(
                        tooltip: 'الفاتح والداكن',
                        onPressed: () => setState(() => dark = !dark),
                        icon: Icon(dark ? Icons.light_mode : Icons.dark_mode)),
                  ]))),
          Expanded(child: CustomerShell(state: widget.state)),
        ])),
      );
}
