import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/chat_image.dart';
import '../../data/firebase_repository.dart';
import 'live_conversations_screen.dart';
import '../../models/models.dart';
import '../../services/local_store_chat.dart';
import '../../state/app_state.dart';

class StoreChatScreen extends StatefulWidget {
  const StoreChatScreen(
      {super.key,
      required this.state,
      required this.conversation,
      this.initialText = '',
      this.initialImage});
  final AppState state;
  final Map<String, Object?> conversation;
  final String initialText;
  final String? initialImage;
  @override
  State<StoreChatScreen> createState() => _StoreChatScreenState();
}

class _StoreChatScreenState extends State<StoreChatScreen> {
  final input = TextEditingController();
  List<AdminRecord> records = [];
  bool loading = true, sending = false;
  String? error;
  String? attachedImage;
  bool picking = false;
  late final service = LocalStoreChat(widget.state.repository);
  StreamSubscription<List<AdminRecord>>? updates;

  @override
  void initState() {
    super.initState();
    input.text = widget.initialText;
    attachedImage = widget.initialImage;
    load();
    final user = widget.state.user;
    if (user != null) {
      updates = service.watch(user).listen((all) {
        if (!mounted) return;
        final id = LocalStoreChat.threadId(
            widget.conversation['storeId'] as String,
            widget.conversation['customerId'] as String);
        setState(() {
          records = all
              .where((r) => r.data['threadId'] == id)
              .toList()
              .reversed
              .toList();
          loading = false;
          error = null;
        });
      }, onError: (_) {
        if (mounted) {
          setState(() => error = 'تعذر تحميل الرسائل. أعد المحاولة.');
        }
      });
    }
  }

  @override
  void dispose() {
    input.dispose();
    updates?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final user = widget.state.user;
      if (user == null) throw StateError('يجب تسجيل الدخول');
      final all = await service.messages(user);
      final id = LocalStoreChat.threadId(
          widget.conversation['storeId'] as String,
          widget.conversation['customerId'] as String);
      if (mounted) {
        setState(() {
          records = all
              .where((r) => r.data['threadId'] == id)
              .toList()
              .reversed
              .toList();
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'تعذر تحميل الرسائل. أعد المحاولة.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final user = widget.state.user;
    if (sending ||
        picking ||
        user == null ||
        (input.text.trim().isEmpty && attachedImage == null)) {
      return;
    }
    setState(() => sending = true);
    try {
      await service.send(
          user: user,
          conversation: widget.conversation,
          text: input.text,
          image: attachedImage);
      if (!mounted) return;
      input.clear();
      setState(() => attachedImage = null);
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم تُرسل الرسالة. أعد المحاولة.')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> attach() async {
    if (sending || picking) return;
    setState(() => picking = true);
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 60);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 500 * 1024) {
        throw StateError('اختر صورة أصغر من 500 كيلوبايت');
      }
      final png = bytes.length > 3 && bytes[0] == 137 && bytes[1] == 80;
      final jpeg = bytes.length > 2 && bytes[0] == 255 && bytes[1] == 216;
      if (!png && !jpeg) throw StateError('اختر صورة PNG أو JPEG');
      if (mounted) {
        setState(() => attachedImage =
            'data:image/${png ? 'png' : 'jpeg'};base64,${base64Encode(bytes)}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is StateError
                ? error.message.toString()
                : 'تعذر اختيار الصورة')));
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || sending || data?.text == null) return;
    final selection = input.selection;
    final start = selection.isValid ? selection.start : input.text.length;
    final end = selection.isValid ? selection.end : input.text.length;
    final value = input.text.replaceRange(start, end, data!.text!);
    if (value.length > 4000) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الحد الأقصى 4000 حرف')));
      return;
    }
    input.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: start + data.text!.length));
  }

  Widget messageContent(Map<String, Object?> data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data['image'] is String)
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('الصورة')),
                            body: Center(
                                child: InteractiveViewer(
                                    child: ChatImage(
                                        source: data['image'] as String)))))),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ChatImage(source: data['image'] as String)),
              ),
            Text('${data['text']}'),
          ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                '${widget.state.user?.id == widget.conversation['customerId'] ? widget.conversation['storeName'] : widget.conversation['customerName']}'),
            actions: [
              if (widget.state.repository is FirebaseRepository)
                IconButton(
                    tooltip: 'محادثات الطلبات',
                    icon: const Icon(Icons.receipt_long_outlined),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                LiveConversationsScreen(state: widget.state)))),
              IconButton(
                  tooltip: 'تحديث الرسائل',
                  onPressed: load,
                  icon: const Icon(Icons.refresh_rounded))
            ]),
        body: Column(children: [
          Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : records.isEmpty
                          ? const Center(child: Text('ابدأ الدردشة مع المتجر'))
                          : ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: records.length,
                              itemBuilder: (_, index) {
                                final data = records[index].data;
                                final mine =
                                    data['senderId'] == widget.state.user?.id;
                                return Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        constraints:
                                            const BoxConstraints(maxWidth: 310),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            color: mine
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerLow),
                                        child: messageContent(data)));
                              })),
          if (attachedImage != null)
            SizedBox(
                height: 100,
                child: Row(children: [
                  Expanded(child: ChatImage(source: attachedImage!)),
                  IconButton(
                      tooltip: 'إزالة الصورة',
                      onPressed: sending
                          ? null
                          : () => setState(() => attachedImage = null),
                      icon: const Icon(Icons.close)),
                ])),
          if (picking) const LinearProgressIndicator(),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    IconButton(
                        tooltip: 'إرفاق صورة',
                        onPressed: sending || picking ? null : attach,
                        icon: const Icon(Icons.add_photo_alternate_outlined)),
                    IconButton(
                        tooltip: 'لصق',
                        onPressed: sending ? null : paste,
                        icon: const Icon(Icons.content_paste)),
                    Expanded(
                        child: TextField(
                            controller: input,
                            readOnly: sending,
                            maxLength: 4000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText: 'اكتب رسالتك...', counterText: ''))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        tooltip: 'إرسال الرسالة',
                        onPressed: sending || picking ? null : send,
                        icon: sending
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded))
                  ]))),
        ]),
      );
}

class StoreChatInboxScreen extends StatefulWidget {
  const StoreChatInboxScreen(
      {super.key, required this.state, this.embedded = false});
  final AppState state;
  final bool embedded;
  @override
  State<StoreChatInboxScreen> createState() => _StoreChatInboxScreenState();
}

class _StoreChatInboxScreenState extends State<StoreChatInboxScreen> {
  late Stream<List<AdminRecord>> stream;
  @override
  void initState() {
    super.initState();
    stream = watch();
  }

  Stream<List<AdminRecord>> watch() {
    final user = widget.state.user;
    if (user == null) return Stream.value([]);
    return LocalStoreChat(widget.state.repository).watch(user);
  }

  void refresh() => setState(() => stream = watch());
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: !widget.embedded,
            title: Text(widget.state.user?.role == UserRole.store
                ? 'محادثات العملاء'
                : 'المحادثات'),
            actions: [
              if (widget.state.repository is FirebaseRepository)
                IconButton(
                    tooltip: 'محادثات الطلبات',
                    icon: const Icon(Icons.receipt_long_outlined),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                LiveConversationsScreen(state: widget.state)))),
              IconButton(
                  tooltip: 'تحديث المحادثات',
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded))
            ]),
        body: StreamBuilder<List<AdminRecord>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                    child: Text('تعذر تحميل المحادثات. أعد المحاولة.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final threads = <String, AdminRecord>{};
              for (final record in snapshot.data!) {
                threads['${record.data['threadId']}'] = record;
              }
              final list = threads.values.toList().reversed.toList();
              if (list.isEmpty) {
                return const Center(child: Text('لا توجد محادثات بعد'));
              }
              return ListView(
                  children: list.map((record) {
                final data = record.data;
                final title = widget.state.user?.id == data['customerId']
                    ? data['storeName']
                    : data['customerName'];
                return ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.chat_outlined)),
                    title: Text('$title'),
                    subtitle: Text('${data['text']}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StoreChatScreen(
                                  state: widget.state, conversation: data)));
                      if (mounted) refresh();
                    });
              }).toList());
            }),
      );
}
