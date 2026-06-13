import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                    // Gönderen dışındaki katılımcılar (teslim/okundu hesabı için).
                    final others = (thread?.participants ?? const <String>[])
                        .where((u) => u != myUid)
                        .toList();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scroll.hasClients) {
                        _scroll.jumpTo(_scroll.position.maxScrollExtent);
                      }
                      // Ekran açık → karşı tarafın mesajlarını "görüldü" yap.
                      if (myUid != null && messages.isNotEmpty) {
                        chat.service.markRead(
                          chatId: widget.chatId,
                          uid: myUid,
                          messages: messages,
                        );
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
                        others: others,
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
/// Altında gönderim saati/tarihi; kendi mesajlarında ayrıca teslim/okundu
/// göstergesi (✓ gönderildi, ✓✓ iletildi, mavi ✓✓ görüldü) bulunur.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showSender,
    required this.others,
  });

  final ChatMessage message;
  final bool mine;
  final bool showSender;

  /// Gönderen dışındaki katılımcı uid'leri (teslim/okundu durumu için).
  final List<String> others;

  /// Mesaj zaman damgasını biçimlendirir: bugünse yalnızca saat, başka günse
  /// tarih + saat (cihaz diline göre).
  String _stamp(BuildContext context) {
    final dt = message.createdAt;
    if (dt == null) return '';
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale).format(dt);
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return time;
    return '${DateFormat.MMMd(locale).format(dt)} $time';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onBubble = mine ? scheme.onPrimary : scheme.onSurface;
    final metaColor = onBubble.withValues(alpha: 0.7);
    final stamp = _stamp(context);

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
              style: TextStyle(color: onBubble, fontSize: 15),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (stamp.isNotEmpty)
                  Text(
                    stamp,
                    style: TextStyle(fontSize: 10.5, color: metaColor),
                  ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  _ReceiptTick(
                    message: message,
                    others: others,
                    baseColor: metaColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kendi mesajların için teslim/okundu göstergesi:
/// tek ✓ = gönderildi, çift ✓✓ = iletildi, mavi çift ✓✓ = görüldü.
class _ReceiptTick extends StatelessWidget {
  const _ReceiptTick({
    required this.message,
    required this.others,
    required this.baseColor,
  });

  final ChatMessage message;
  final List<String> others;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    // Henüz sunucuya yazılmadıysa (zaman damgası yok) saat ikonu göster.
    if (message.createdAt == null) {
      return Icon(Icons.access_time, size: 13, color: baseColor);
    }
    final read = message.readByAll(others);
    final delivered = message.deliveredToAll(others);
    if (read) {
      return Icon(Icons.done_all, size: 15,
          color: const Color(0xFF53BDEB)); // okundu → mavi
    }
    return Icon(
      delivered ? Icons.done_all : Icons.check,
      size: 15,
      color: baseColor,
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
