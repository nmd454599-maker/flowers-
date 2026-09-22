import '../../data/firebase/firestore_schema.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';

class LiveConversationsScreen extends StatefulWidget {
  final AppState state;
  const LiveConversationsScreen({super.key, required this.state});
  @override
  State<LiveConversationsScreen> createState() =>
      _LiveConversationsScreenState();
}

class _LiveConversationsScreenState extends State<LiveConversationsScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> orders = _orders();
  Stream<QuerySnapshot<Map<String, dynamic>>> _orders() {
    final user = widget.state.user;
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(FirestoreCollections.orders);
    if (user?.role == UserRole.customer) {
      query = query.where('customerId', isEqualTo: user!.id);
    } else if (user?.role == UserRole.store) {
      query = query.where('storeIds',
          arrayContains: user!.storeId ?? '__unassigned__');
    } else if (user?.role != UserRole.superAdmin) {
      return Stream.error(StateError('يجب تسجيل الدخول'));
    }
    return query.limit(100).snapshots();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('محادثات الطلبات')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text(
                      'تعذر تحميل المحادثات. تحقق من الاتصال والصلاحيات.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                  child: Text('تظهر المحادثات بعد إنشاء الطلبات'));
            }
            return ListView(
                children: docs
                    .map((doc) => ListTile(
                          leading: const Icon(Icons.forum_outlined),
                          title: Text('الطلب ${doc.id}'),
                          subtitle: const Text('العميل ومتاجر الطلب والدعم'),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      OrderChatScreen(orderId: doc.id))),
                        ))
                    .toList());
          },
        ),
      );
}

class OrderChatScreen extends StatefulWidget {
  final String orderId;
  const OrderChatScreen({super.key, required this.orderId});
  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final input = TextEditingController();
  bool sending = false;
  late final messages = FirebaseFirestore.instance
      .collection(FirestoreCollections.orders)
      .doc(widget.orderId)
      .collection(FirestoreCollections.messages);
  late final stream =
      messages.orderBy('createdAt', descending: true).limit(100).snapshots();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = input.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || uid == null || sending) return;
    setState(() => sending = true);
    try {
      await messages.add({
        'senderId': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp()
      });
      input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لم يتم إرسال الرسالة، أعد المحاولة')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('محادثة الطلب')),
        body: Column(children: [
          const Padding(
              padding: EdgeInsets.all(12),
              child: Text('هذه المحادثة مشتركة مع العميل ومتاجر الطلب والدعم')),
          Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('تعذر تحميل الرسائل'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final data = docs[index].data();
                    final mine = data['senderId'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(mine ? 'أنت' : 'مشارك في الطلب',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall),
                                      Text(data['text'] as String? ?? ''),
                                      if (docs[index].metadata.hasPendingWrites)
                                        const Text('جارٍ الإرسال…'),
                                    ]))));
                  });
            },
          )),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: input,
                            maxLength: 4000,
                            readOnly: sending,
                            decoration: const InputDecoration(
                                hintText: 'اكتب رسالتك'))),
                    IconButton(
                        onPressed: sending ? null : send,
                        icon: const Icon(Icons.send_rounded)),
                  ]))),
        ]),
      );
}
