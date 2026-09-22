import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/firebase_repository.dart';
import '../../data/sqlite_repository.dart';
import '../../domain/accounts/account_identity.dart';
import '../../state/app_state.dart';

class ChangePhoneScreen extends StatefulWidget {
  final AppState state;
  const ChangePhoneScreen({super.key, required this.state});
  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final phone = TextEditingController(), code = TextEditingController();
  String? verificationId, requestedPhone, error;
  bool busy = false, done = false;
  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> update(PhoneAuthCredential credential) async {
    final repo = widget.state.repository as FirebaseRepository;
    final current = repo.auth.currentUser;
    if (current == null || current.uid != widget.state.user?.id) {
      throw StateError('سجّل الدخول مجددًا');
    }
    await current.updatePhoneNumber(credential);
    await current.reload();
    final number = repo.auth.currentUser!.phoneNumber!;
    final u = widget.state.user;
    if (u != null && u.id == current.uid) {
      widget.state.updateCustomerPhone(number);
    }
    try {
      await repo.firestore
          .collection('users')
          .doc(current.uid)
          .update({'phone': number});
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'تغيّر رقم الدخول، لكن تعذرت مزامنة الملف. سجّل الدخول بالرقم الجديد لإكمال المزامنة.');
      }
    }
    if (mounted) {
      setState(() {
        done = true;
        busy = false;
      });
    }
  }

  Future<void> send() async {
    final number = accountPhone(phone.text);
    if (!RegExp(r'^\+9647[0-9]{9}$').hasMatch(number)) {
      setState(() => error = 'أدخل رقم هاتف عراقي صحيح');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      requestedPhone = number;
    });
    try {
      if (widget.state.repository is SqliteRepository) {
        setState(() {
          verificationId = 'local';
          busy = false;
        });
        return;
      }
      final repo = widget.state.repository as FirebaseRepository;
      await repo.auth.verifyPhoneNumber(
          phoneNumber: number,
          verificationCompleted: (credential) async {
            try {
              await update(credential);
            } catch (_) {
              fail();
            }
          },
          verificationFailed: (_) => fail(),
          codeSent: (id, _) {
            if (mounted) {
              setState(() {
                verificationId = id;
                busy = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (id) {
            if (mounted && !done) {
              setState(() {
                verificationId = id;
                busy = false;
              });
            }
          });
    } catch (_) {
      fail();
    }
  }

  void fail() {
    if (mounted) {
      setState(() {
        busy = false;
        error =
            'تعذر تغيير الرقم. تحقق من الرمز؛ قد تحتاج تسجيل الدخول مجددًا أو أن الرقم مستخدم بحساب آخر.';
      });
    }
  }

  Future<void> confirm() async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code.text.trim())) {
      setState(() => error = 'أدخل الرمز المكوّن من 6 أرقام');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final repo = widget.state.repository;
      if (repo is SqliteRepository) {
        await repo.changeLocalPhone(requestedPhone!, code.text.trim());
        widget.state.updateCustomerPhone(requestedPhone!);
        if (mounted)
          setState(() {
            done = true;
            busy = false;
          });
        return;
      }
      await update(PhoneAuthProvider.credential(
          verificationId: verificationId!, smsCode: code.text.trim()));
    } catch (_) {
      fail();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('تغيير رقم الهاتف')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('الرقم الحالي: ${widget.state.user?.phone ?? ''}'),
        if (widget.state.repository is SqliteRepository)
          const Text('فحص محلي فقط: استخدم الرمز 123456. لا تُرسل رسالة SMS.'),
        if (done)
          Text(error ?? 'تم تغيير رقم الهاتف بنجاح')
        else ...[
          TextField(
              controller: phone,
              enabled: !busy && verificationId == null,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'الرقم الجديد')),
          if (verificationId != null) ...[
            Text(widget.state.repository is SqliteRepository
                ? 'رمز الفحص: 123456'
                : 'أُرسل الرمز إلى $requestedPhone'),
            TextField(
                controller: code,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رمز التحقق'))
          ],
          if (error != null) Text(error!),
          FilledButton(
              onPressed: busy
                  ? null
                  : verificationId == null
                      ? send
                      : confirm,
              child: Text(busy
                  ? 'جارٍ التحقق…'
                  : verificationId == null
                      ? 'إرسال رمز التحقق'
                      : 'تأكيد تغيير الرقم')),
          if (verificationId != null)
            TextButton(
                onPressed: busy ? null : send,
                child: const Text('إعادة إرسال الرمز')),
        ]
      ]));
}
