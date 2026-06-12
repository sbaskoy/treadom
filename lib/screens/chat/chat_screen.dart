import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/chat_thread.dart';
import '../../providers/chat_provider.dart';

/// İki kişi (ya da grup) arasındaki sohbet ekranı: canlı mesajlar + gönderme.
/// 1:1 sohbet "Sohbeti bitir" ile sonlandırılabilir; sonrasında kimse yazamaz.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId, required this.title});

  final String chatId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(ChatProvider chat) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await chat.service.sendMessage(
      chatId: widget.chatId,
      senderId: chat.uid ?? '',
      senderName: chat.username,
      text: text,
    );
  }

  Future<void> _confirmEnd(ChatProvider chat) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatEndConfirmTitle),
        content: Text(l10n.chatEndConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.chatEndChat),
          ),
        ],
      ),
    );
    if (ok == true) {
      await chat.service.endChat(chatId: widget.chatId, byUid: chat.uid ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = context.read<ChatProvider>();
    final myUid = chat.uid;

    return StreamBuilder<ChatThread?>(
      stream: chat.service.threadStream(widget.chatId),
      builder: (context, snap) {
        final thread = snap.data;
        final ended = thread?.isEnded ?? false;
        final isGroup = thread?.isGroup ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(thread?.title(myUid ?? '') ?? widget.title),
            actions: [
              if (!isGroup && !ended)
                IconButton(
                  tooltip: l10n.chatEndChat,
                  icon: const Icon(Icons.block_rounded),
                  onPressed: () => _confirmEnd(chat),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: chat.service.messagesStream(widget.chatId),
                  builder: (context, msgSnap) {
                    final messages = msgSnap.data ?? const <ChatMessage>[];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scroll.hasClients) {
                        _scroll.jumpTo(_scroll.position.maxScrollExtent);
                      }
                    });
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _Bubble(
                        message: messages[i],
                        mine: messages[i].senderId == myUid,
                        showSender: isGroup,
                      ),
                    );
                  },
                ),
              ),
              if (ended)
                _EndedBanner(text: l10n.chatEnded)
              else
                _InputBar(
                  controller: _controller,
                  hint: l10n.chatMessageHint,
                  onSend: () => _send(chat),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tek bir mesaj balonu (kendi mesajların sağda, diğerleri solda).
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showSender,
  });

  final ChatMessage message;
  final bool mine;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSender && !mine)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: mine ? scheme.onPrimary : scheme.onSurface,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sohbet bitince gösterilen, yazmayı engelleyen şerit.
class _EndedBanner extends StatelessWidget {
  const _EndedBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Alt mesaj yazma çubuğu.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hint,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration:
                  BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: scheme.onPrimary),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
