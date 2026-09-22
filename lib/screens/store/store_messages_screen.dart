import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../shared/store_chat_screen.dart';

class StoreMessagesScreen extends StatelessWidget {
  final AppState state;
  const StoreMessagesScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) => StoreChatInboxScreen(state: state);
}
