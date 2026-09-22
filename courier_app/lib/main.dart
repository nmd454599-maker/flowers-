import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'login_input.dart';

String _loginError(Object exception) {
  if (exception is FormatException) return exception.message;
  if (exception is StateError) return exception.message;
  if (exception is FirebaseException) {
    final message = switch (exception.code) {
      'invalid-phone-number' => 'رقم الهاتف غير صحيح.',
      'invalid-verification-code' => 'رمز التحقق غير صحيح. حاول مجددًا.',
      'session-expired' ||
      'code-expired' => 'انتهت صلاحية الرمز. ارجع وأرسل رمزًا جديدًا.',
      'too-many-requests' => 'محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.',
      'network-request-failed' ||
      'unavailable' => 'تعذر الاتصال بالخدمة. تحقق من الإنترنت.',
      'user-disabled' => 'الحساب موقوف. تواصل مع إدارة أزهارنا.',
      'operation-not-allowed' =>
        'تسجيل الدخول بالهاتف غير مفعّل في الخدمة. تواصل مع الإدارة.',
      'permission-denied' =>
        'تعذر قراءة اعتماد المندوب. يلزم مراجعة صلاحيات الخدمة لدى الإدارة.',
      'app-not-authorized' ||
      'invalid-app-credential' ||
      'missing-client-identifier' => 'تعذر التحقق من نسخة التطبيق. تواصل مع الإدارة لمراجعة إعدادات Firebase.',
      'quota-exceeded' =>
        'تم بلوغ حد إرسال الرسائل لدى الخدمة. تواصل مع الإدارة.',
      _ => 'تعذر إكمال تسجيل الدخول.',
    };
    return '$message (${exception.code})';
  }
  return 'تعذر إكمال تسجيل الدخول. حاول مجددًا.';
}

ThemeData _courierTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final paper = dark ? const Color(0xFF101010) : Colors.white;
  final ink = dark ? Colors.white : const Color(0xFF191919);
  final primary = dark ? const Color(0xFF65D6DF) : const Color(0xFF007A83);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    surface: paper,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'IBMPlexSansArabic',
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: paper,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleDeviceCheckProvider(),
    );
    runApp(const CourierApp());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: _courierTheme(),
        darkTheme: _courierTheme(Brightness.dark),
        home: const Scaffold(
          body: Center(child: Text('تعذر تهيئة خدمة المندوب')),
        ),
      ),
    );
  }
}

class CourierApp extends StatelessWidget {
  const CourierApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'أزهارنا للمندوب',
    debugShowCheckedModeBanner: false,
    theme: _courierTheme(),
    darkTheme: _courierTheme(Brightness.dark),
    builder: (_, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const CourierLogin(),
  );
}

class CourierLogin extends StatefulWidget {
  const CourierLogin({super.key});
  @override
  State<CourierLogin> createState() => _CourierLoginState();
}

class _CourierLoginState extends State<CourierLogin> {
  final phone = TextEditingController();
  final code = TextEditingController();
  String? verificationId;
  String? error;
  bool busy = false;
  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> enter() async {
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdTokenResult(true);
    final data =
        (await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get())
            .data();
    if (token.claims?['role'] != 'courier' ||
        data?['role'] != 'courier' ||
        data?['active'] != true) {
      await FirebaseAuth.instance.signOut();
      throw StateError('الحساب غير معتمد كمندوب');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CourierOrders(uid: user.uid)),
    );
  }

  Future<void> submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (verificationId != null) {
        await FirebaseAuth.instance.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: verificationId!,
            smsCode: courierSmsCode(code.text),
          ),
        );
        await enter();
      } else {
        final normalized = courierPhone(phone.text);
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: normalized,
          verificationCompleted: (credential) async {
            try {
              await FirebaseAuth.instance.signInWithCredential(credential);
              await enter();
            } catch (exception) {
              if (mounted) {
                setState(() {
                  error = _loginError(exception);
                  busy = false;
                });
              }
            }
          },
          verificationFailed: (exception) {
            if (mounted) {
              setState(() {
                error = _loginError(exception);
                busy = false;
              });
            }
          },
          codeSent: (id, _) {
            if (mounted) {
              setState(() {
                verificationId = id;
                busy = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (id) {
            if (mounted) {
              setState(() {
                verificationId = id;
                busy = false;
              });
            }
          },
        );
        return;
      }
    } catch (exception) {
      if (mounted) setState(() => error = _loginError(exception));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('أزهارنا للمندوب')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          enabled: !busy,
          controller: verificationId == null ? phone : code,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: verificationId == null ? 'رقم الهاتف' : 'رمز التحقق',
          ),
        ),
        const SizedBox(height: 16),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: const Text('متابعة'),
        ),
        if (verificationId != null)
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    verificationId = null;
                    code.clear();
                    error = null;
                  }),
            child: const Text('تعديل الرقم أو طلب رمز جديد'),
          ),
      ],
    ),
  );
}

class CourierOrders extends StatefulWidget {
  final String uid;
  const CourierOrders({super.key, required this.uid});
  @override
  State<CourierOrders> createState() => _CourierOrdersState();
}

class _CourierOrdersState extends State<CourierOrders> {
  late final orders = FirebaseFirestore.instance
      .collection('orders')
      .where('assignedCourierId', isEqualTo: widget.uid)
      .limit(100)
      .snapshots();
  final pending = <String>{};
  Future<void> advance(
    DocumentSnapshot<Map<String, dynamic>> order,
    String status,
  ) async {
    setState(() => pending.add(order.id));
    try {
      await order.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر تحديث الطلب')));
      }
    } finally {
      if (mounted) setState(() => pending.remove(order.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('طلباتي المسندة'),
      actions: [
        IconButton(
          tooltip: 'تسجيل الخروج',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CourierLogin()),
            );
          },
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: orders,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تحميل الطلبات'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد طلبات مسندة إليك'));
        }
        return ListView(
          children: snapshot.data!.docs.map((order) {
            final data = order.data();
            final next = data['status'] == 'preparing'
                ? 'delivering'
                : data['status'] == 'delivering'
                ? 'delivered'
                : null;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب ${order.id}'),
                    Text(data['address'] as String? ?? ''),
                    Text(
                      'المطلوب نقدًا: ${data['cashDue'] ?? data['total'] ?? 0} د.ع',
                    ),
                    if (next != null)
                      FilledButton(
                        onPressed: pending.contains(order.id)
                            ? null
                            : () => advance(order, next),
                        child: Text(
                          next == 'delivering'
                              ? 'استلمت الطلب وبدأت التوصيل'
                              : 'تم التسليم',
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}
