import '../../state/operation_runner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../admin/admin_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  final AppState state;
  const AdminLoginScreen({super.key, required this.state});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  MultiFactorResolver? resolver;
  TotpSecret? secret;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    try {
      await widget.state.runAuthentication(_submit);
    } catch (_) {
      if (mounted) setState(() => error = 'انتهت محاولة الدخول. حاول مجدداً.');
    }
  }

  Future<void> _submit(OperationToken token) async {
    setState(() {
      busy = true;
      error = null;
    });
    final auth = FirebaseAuth.instance;
    try {
      if (resolver != null) {
        final factors =
            resolver!.hints.where((hint) => hint.factorId == 'totp');
        if (factors.isEmpty) {
          throw StateError('لا يوجد عامل TOTP مسجل لهذا الحساب');
        }
        final assertion = await token.wait(
            TotpMultiFactorGenerator.getAssertionForSignIn(
                factors.first.uid, code.text.trim()));
        await token.wait(resolver!.resolveSignIn(assertion));
        await token.wait(enter(token));
      } else if (secret != null) {
        final assertion = await token.wait(
            TotpMultiFactorGenerator.getAssertionForEnrollment(
                secret!, code.text.trim()));
        await token.wait(auth.currentUser!.multiFactor
            .enroll(assertion, displayName: 'Azharna Admin'));
        await token.wait(auth.signOut());
        secret = null;
        code.clear();
        error = 'تم تفعيل العامل الثاني. سجّل الدخول مجددًا.';
      } else {
        await token.wait(auth.signInWithEmailAndPassword(
            email: email.text.trim(), password: password.text));
        final user = auth.currentUser!;
        final authToken = await token.wait(user.getIdTokenResult(true));
        if (!['admin', 'superAdmin'].contains(authToken.claims?['role'])) {
          await token.wait(auth.signOut());
          throw StateError('الحساب غير مخول للإدارة');
        }
        if (!user.emailVerified) {
          await token.wait(auth.signOut());
          throw StateError('يجب تأكيد البريد الإلكتروني أولًا');
        }
        final factors = await token.wait(user.multiFactor.getEnrolledFactors());
        if (factors.isNotEmpty) {
          await token.wait(auth.signOut());
          throw StateError('أعد تسجيل الدخول للتحقق من العامل الثاني');
        }
        secret = await token.wait(TotpMultiFactorGenerator.generateSecret(
            await user.multiFactor.getSession()));
      }
    } on FirebaseAuthMultiFactorException catch (exception) {
      token.check();
      if (!mounted) return;
      resolver = exception.resolver;
      code.clear();
    } catch (exception) {
      token.check();
      if (!mounted) return;
      error = exception is FirebaseAuthException
          ? 'تعذر التحقق (${exception.code})'
          : exception.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> enter(OperationToken operation) async {
    final user = FirebaseAuth.instance.currentUser!;
    final authToken = await operation.wait(user.getIdTokenResult(true));
    final firebase = authToken.claims?['firebase'];
    if (!['admin', 'superAdmin'].contains(authToken.claims?['role']) ||
        firebase is! Map ||
        firebase['sign_in_second_factor'] == null) {
      await operation.wait(FirebaseAuth.instance.signOut());
      throw StateError('مطلوب حساب إدارة مع تحقق ثنائي');
    }
    final doc = await operation.wait(
        FirebaseFirestore.instance.collection('users').doc(user.uid).get());
    final data = doc.data();
    if (data?['active'] != true || data?['role'] != authToken.claims?['role']) {
      await operation.wait(FirebaseAuth.instance.signOut());
      throw StateError('الحساب موقوف أو صلاحياته غير متطابقة');
    }
    operation.check();
    if (!mounted) return;
    widget.state.user = AppUser(
        id: user.uid,
        name: data?['name'] as String? ?? 'الإدارة',
        phone: user.phoneNumber ?? '',
        role: UserRole.superAdmin);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AdminShell(state: widget.state)),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('دخول الإدارة الآمن')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          if (secret == null && resolver == null) ...[
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'البريد الإلكتروني')),
            TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور')),
          ],
          if (secret != null) ...[
            const Text(
                'أضف هذا المفتاح في تطبيق المصادقة ثم أدخل الرمز. احتفظ به بشكل آمن.'),
            SelectableText(secret!.secretKey, textDirection: TextDirection.ltr),
          ],
          if (secret != null || resolver != null)
            TextField(
                controller: code,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'رمز تطبيق المصادقة')),
          if (error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
          FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy ? 'جارٍ التحقق…' : 'متابعة')),
        ]),
      );
}
