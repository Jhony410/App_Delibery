import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/chat_message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

/// Customer-side chat with the assigned courier for an active order.
/// Receives the orderId via `Navigator.pushNamed(context, '/chat',
/// arguments: orderId)`.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _orderId;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id != null && id != _orderId) {
      _orderId = id;
      // Mark the courier's messages as read as soon as the screen opens.
      ChatService.markReadFromOthers(id, 'user');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final id = _orderId;
    final uid = AuthService.currentUid;
    final text = _controller.text.trim();
    if (id == null || uid == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    await ChatService.sendMessage(
      orderId: id,
      senderId: uid,
      senderRole: 'user',
      text: text,
    );
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = _orderId;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD0B0),
              ),
              child: Icon(Icons.motorcycle, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tu repartidor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'En línea',
                  style: TextStyle(fontSize: 11, color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: id == null
          ? Center(child: Text('Chat no disponible'))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.streamMessages(id),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      final messages = snap.data ?? const <ChatMessage>[];
                      if (messages.isEmpty) {
                        return const _EmptyChat();
                      }
                      _scrollToBottom();
                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, i) =>
                            _Bubble(message: messages[i], mineIsUser: true),
                      );
                    },
                  ),
                ),
                _Composer(
                  controller: _controller,
                  sending: _sending,
                  onSend: _send,
                ),
              ],
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mineIsUser; // on this app, "mine" == messages from the user
  const _Bubble({required this.message, required this.mineIsUser});

  @override
  Widget build(BuildContext context) {
    final mine = message.isUser == mineIsUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: mine
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 3),
            Text(
              _time(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? Colors.white.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 10),
          Text(
            'Escríbele a tu repartidor',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: sending
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
