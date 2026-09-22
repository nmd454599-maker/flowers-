import 'package:flutter/material.dart';

import 'core/color_direction.dart';
import 'data/demo_repository.dart';
import 'screens/customer/customer_shell.dart';
import 'state/app_state.dart';

/// Visual preview using the real customer screens and local sample data.
/// Run independently of the production Firebase application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(repository: DemoRepository());
  await state.loadCatalog();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'أزهارنا — معاينة الآيفون',
    theme: ColorDirection.turquoise
        .theme(Brightness.light)
        .copyWith(platform: TargetPlatform.iOS),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: const Color(0xFFE8ECEF),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: LayoutBuilder(
              builder: (context, constraints) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    ),
    home: CustomerShell(state: state),
  ));
}
