import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'core/market_theme.dart';
import 'core/color_direction.dart';

import 'data/app_repository.dart';
import 'data/demo_repository.dart';
import 'data/firebase_repository.dart';
import 'data/sqlite_repository.dart';
import 'state/app_state.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();
  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  AppRepository? repository;
  Object? startupError;
  bool ready = false;
  bool onboarding = false;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      AppConfig.validate();
      repository =
          AppConfig.useFirebase ? FirebaseRepository() : SqliteRepository();
      await repository!.initialize();
      try {
        await AppTheme.restoreMode();
        onboarding =
            !(await SharedPreferencesAsync().getBool('onboarding_complete') ??
                false);
      } catch (_) {
        onboarding = false;
      }
    } catch (error) {
      startupError = error;
    }
    if (mounted) setState(() => ready = true);
  }

  @override
  Widget build(BuildContext context) => ready
      ? AzharnaApp(
          repository: repository,
          startupError: startupError,
          showOnboarding: onboarding)
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MarketTheme.apply(
              ColorDirection.turquoise.theme(Brightness.light)),
          darkTheme: MarketTheme.apply(
              ColorDirection.turquoise.theme(Brightness.dark)),
          themeMode: AppTheme.mode.value,
          home: const Directionality(
              textDirection: TextDirection.rtl, child: SplashPage()));
}

class AzharnaApp extends StatefulWidget {
  final AppRepository? repository;
  final Object? startupError;
  final bool showOnboarding;

  const AzharnaApp(
      {super.key,
      this.repository,
      this.startupError,
      this.showOnboarding = false});

  @override
  State<AzharnaApp> createState() => _AzharnaAppState();
}

class _AzharnaAppState extends State<AzharnaApp> {
  late bool onboarding = widget.showOnboarding;
  late final AppState state = AppState(
    repository: widget.repository ?? DemoRepository(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.startupError == null) {
      unawaited(state.loadCatalog().catchError((_) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: Listenable.merge([AppTheme.mode, AppTheme.font]),
        builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'أزهارنا',
              locale: const Locale('ar'),
              theme: MarketTheme.apply(
                  ColorDirection.turquoise.theme(Brightness.light)),
              darkTheme: MarketTheme.apply(
                  ColorDirection.turquoise.theme(Brightness.dark)),
              themeMode: AppTheme.mode.value,
              builder: (context, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth.clamp(0.0, 1200.0);
                  return Center(
                      child: SizedBox(
                          width: width,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                                size: Size(width, constraints.maxHeight)),
                            child: child ?? const SizedBox.shrink(),
                          )));
                }),
              ),
              home: widget.startupError == null
                  ? onboarding
                      ? OnboardingScreen(onComplete: () async {
                          try {
                            await SharedPreferencesAsync()
                                .setBool('onboarding_complete', true);
                          } catch (_) {
                            /* Continue even if preferences are unavailable. */
                          }
                          if (mounted) setState(() => onboarding = false);
                        })
                      : WelcomeScreen(state: state)
                  : _StartupErrorScreen(error: widget.startupError!),
            ));
  }
}

class _StartupErrorScreen extends StatelessWidget {
  final Object error;

  const _StartupErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64),
              const SizedBox(height: 16),
              const Text('تعذر الاتصال بخدمة التطبيق'),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
