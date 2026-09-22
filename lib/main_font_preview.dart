import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'data/demo_repository.dart';
import 'screens/customer/customer_shell.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(repository: DemoRepository());
  await state.loadCatalog();
  runApp(FontPreviewApp(state: state));
}

class FontPreviewApp extends StatelessWidget {
  const FontPreviewApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([AppTheme.font, AppTheme.mode]),
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'أزهارنا — مقارنة الخطوط',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: AppTheme.mode.value,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: CustomerShell(state: state, compareFonts: true),
        ),
      );
}
