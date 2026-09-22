import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../customer/customer_shell.dart';
import '../store/store_shell.dart';
import '../admin/admin_shell.dart';

class OtpScreen extends StatefulWidget {
  final AppState state;
  final String phone;
  final UserRole role;
  const OtpScreen(
      {super.key,
      required this.state,
      required this.phone,
      required this.role});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final code = TextEditingController();
  String? error;

  Future<void> verify() async {
    setState(() => error = null);
    try {
      await widget.state.verifyOtp(widget.phone, code.text.trim(), widget.role);
    } catch (_) {
      if (!mounted) return;
      setState(
          () => error = widget.state.errorMessage ?? 'تعذر التحقق من الرمز');
      return;
    }
    if (!mounted) return;
    final actualRole = widget.state.user?.role ?? widget.role;
    if (actualRole == UserRole.courier) {
      await widget.state.logout();
      if (!mounted) return;
      setState(() => error = 'يرجى استخدام تطبيق المندوب لهذا الحساب');
      return;
    }
    if (actualRole == UserRole.customer) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CustomerShell(state: widget.state)),
          (_) => false);
    } else if (actualRole == UserRole.store) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => StoreShell(state: widget.state)),
          (_) => false);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AdminShell(state: widget.state)),
          (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من الرقم')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_read_outlined,
                  size: 46, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 22),
          Text('أدخل رمز التحقق',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('أرسلنا الرمز إلى ${widget.phone}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          TextField(
            controller: code,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: widget.state.isDemo ? 4 : 6,
            decoration:
                InputDecoration(labelText: 'رمز التحقق', errorText: error),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: widget.state,
            builder: (context, _) => FilledButton(
              onPressed: widget.state.busy ? null : verify,
              child: Text(widget.state.busy ? 'جارٍ التحقق...' : 'تأكيد'),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.state.isDemo)
            const Text('في النسخة التجريبية استخدم الرمز 1234',
                textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
