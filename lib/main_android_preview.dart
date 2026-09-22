import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/color_direction.dart';
import 'domain/accounts/account_identity.dart';
import 'data/sqlite_repository.dart';
import 'models/models.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/store/store_shell.dart';
import 'state/app_state.dart';

/// Local-only test entry point, never used by the production build.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalPreviewApp());
}

class LocalPreviewApp extends StatefulWidget {
  const LocalPreviewApp({super.key});
  @override
  State<LocalPreviewApp> createState() => _LocalPreviewAppState();
}

class _LocalPreviewAppState extends State<LocalPreviewApp> {
  final state = AppState(repository: SqliteRepository());
  int revision = 0;
  bool busy = true;
  String? error;
  static const phones = {
    UserRole.customer: '07701234567',
    UserRole.store: '07811234567',
    UserRole.superAdmin: '07501234567',
  };
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      await state.repository.initialize();
      await AppTheme.restoreMode();
      for (final role in [
        UserRole.store,
        UserRole.superAdmin,
        UserRole.customer
      ]) {
        await login(role);
      }
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> login(UserRole role) async {
    await state.logout();
    final originalPhone = phones[role]!;
    final accounts = await state.repository.fetchAdminUsers();
    final id = 'local-${accountPhone(originalPhone).substring(1)}';
    final phone =
        accounts.where((u) => u.id == id).firstOrNull?.phone ?? originalPhone;
    await state.requestOtp(phone);
    await state.verifyOtp(phone, '1234', role);
    if (state.user?.role == UserRole.superAdmin) await state.loadAdminData();
  }

  Future<void> switchAccount(UserRole role) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await login(role);
    } catch (e) {
      error = '$e';
    }
    if (mounted)
      setState(() {
        busy = false;
        revision++;
      });
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([state, AppTheme.mode, AppTheme.font]),
        builder: (_, child) => MaterialApp(
          key: ValueKey(revision),
          debugShowCheckedModeBanner: false,
          title: 'أزهارنا — فحص محلي',
          theme: ColorDirection.turquoise.theme(Brightness.light),
          darkTheme: ColorDirection.turquoise.theme(Brightness.dark),
          themeMode: AppTheme.mode.value,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: Column(children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: SafeArea(
                    bottom: false,
                    child: Column(children: [
                      const Text('فحص محلي • البيانات محفوظة على هذا الهاتف',
                          style: TextStyle(fontSize: 11)),
                      Row(children: [
                        for (final entry in const {
                          UserRole.customer: 'المستخدم',
                          UserRole.store: 'المتجر',
                          UserRole.superAdmin: 'سوبر أدمن'
                        }.entries)
                          Expanded(
                              child: TextButton(
                            onPressed:
                                busy ? null : () => switchAccount(entry.key),
                            child: Text(
                                '${state.user?.role == entry.key ? '● ' : ''}${entry.value}'),
                          )),
                      ]),
                    ])),
              ),
              Expanded(
                  child: busy
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                          ? Material(
                              child: Center(
                                  child: Text(error!,
                                      textAlign: TextAlign.center)))
                          : child ?? const SizedBox.shrink()),
            ]),
          ),
          home: switch (state.user?.role) {
            UserRole.superAdmin => AdminShell(state: state),
            UserRole.store => StoreShell(state: state),
            _ => CustomerShell(state: state),
          },
        ),
      );
}
