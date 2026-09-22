import 'package:flutter/material.dart';
import 'core/color_direction.dart';
import 'data/demo_repository.dart';
import 'state/app_state.dart';
import 'screens/customer/customer_shell.dart';
import 'widgets/catalog_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(repository: DemoRepository());
  await state.loadCatalog();
  runApp(CatalogPreviewApp(state: state));
}

class CatalogPreviewApp extends StatefulWidget {
  const CatalogPreviewApp(
      {super.key,
      required this.state,
      this.initialLayout = CatalogLayout.balanced});
  final AppState state;
  final CatalogLayout initialLayout;
  @override
  State<CatalogPreviewApp> createState() => _CatalogPreviewAppState();
}

class _CatalogPreviewAppState extends State<CatalogPreviewApp> {
  late CatalogLayout layout = widget.initialLayout;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ColorDirection.turquoise.theme(Brightness.light),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
            body: Column(children: [
          SafeArea(
              bottom: false,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<CatalogLayout>(
                      isExpanded: true,
                      value: layout,
                      items: [
                        for (final value in CatalogLayout.values)
                          DropdownMenuItem(
                              value: value, child: Text(value.label))
                      ],
                      onChanged: (value) => setState(() => layout = value!)))),
          Expanded(
              child: CustomerShell(
                  state: widget.state, initialIndex: 1, catalogLayout: layout)),
        ])),
      );
}
