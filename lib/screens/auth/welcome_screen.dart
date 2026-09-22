import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/accounts/account_identity.dart';
import '../../data/firebase_repository.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'welcome_form.dart';
import 'admin_login_screen.dart';
import 'otp_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final AppState state;
  const WelcomeScreen({super.key, required this.state});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final phone = TextEditingController();
  UserRole role = UserRole.customer;

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (widget.state.repository is FirebaseRepository &&
        role == UserRole.superAdmin) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminLoginScreen(state: widget.state)));
      return;
    }
    if (!RegExp(r'^\+9647[0-9]{9}$').hasMatch(accountPhone(phone.text))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('أدخل رقم هاتف صحيح')));
      return;
    }
    try {
      await widget.state.requestOtp(accountPhone(phone.text));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.state.errorMessage ?? 'تعذر إرسال الرمز')));
      return;
    }
    if (!mounted) return;
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    final loginRole = widget.state.isDemo && digits.endsWith('7501234567')
        ? UserRole.superAdmin
        : role;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => OtpScreen(
                state: widget.state,
                phone: accountPhone(phone.text),
                role: loginRole)));
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: AnimatedBuilder(
            animation: widget.state,
            builder: (context, _) => WelcomeForm(
                  phone: phone,
                  role: role,
                  busy: widget.state.busy,
                  onRole: (value) => setState(() => role = value),
                  onSubmit: next,
                )),
      );
}
