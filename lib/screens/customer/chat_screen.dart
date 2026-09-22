import '../../data/firebase_repository.dart';
import '../shared/live_conversations_screen.dart';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class ChatScreen extends StatefulWidget {
  final AppState state;
  const ChatScreen({super.key, required this.state});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final message = TextEditingController();
  @override
  Widget build(BuildContext context) => widget.state.repository
          is FirebaseRepository
      ? LiveConversationsScreen(state: widget.state)
      : AnimatedBuilder(
          animation: widget.state,
          builder: (_, __) => Scaffold(
            appBar: AppBar(title: const Text('ورود الجوري'), actions: const [
              Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.store_outlined))
            ]),
            body: Column(children: [
              Expanded(
                  child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.state.messages.length,
                itemBuilder: (_, i) {
                  final m = widget.state.messages[i];
                  return Align(
                    alignment:
                        m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: m.fromMe
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(m.text),
                    ),
                  );
                },
              )),
              SafeArea(
                  top: false,
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        Expanded(
                            child: TextField(
                                controller: message,
                                decoration: const InputDecoration(
                                    hintText: 'اكتب رسالتك...'))),
                        const SizedBox(width: 8),
                        IconButton.filled(
                            onPressed: () {
                              widget.state.sendMessage(message.text);
                              message.clear();
                            },
                            icon: const Icon(Icons.send_rounded)),
                      ]))),
            ]),
          ),
        );
}
