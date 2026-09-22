import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'data/demo_repository.dart';
import 'screens/customer/customer_shell.dart';
import 'state/app_state.dart';

/// Explicit local preview entry point; never initializes Firebase or SQLite.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(repository: DemoRepository());
  await state.loadCatalog();
  runApp(DesignPreviewApp(state: state));
}

class DesignPreviewApp extends StatelessWidget {
  const DesignPreviewApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: AppTheme.mode,
        builder: (context, mode, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'أزهارنا — مقارنة التصاميم',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          builder: (context, child) => Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: child))),
          home: CustomerShell(state: state, compareDesigns: true),
        ),
      );
}
