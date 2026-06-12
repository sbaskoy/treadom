import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/chat_thread.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'nearby_screen.dart';

/// Kullanıcının sohbetlerini listeleyen ekran. Sağ alttaki "yeni sohbet"
/// butonu yakındaki oyuncular ekranını açar.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = context.watch<ChatProvider>();
    final myUid = chat.uid ?? '';
    final threads = chat.threads;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NearbyScreen()),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l10n.chatNearbyTitle),
      ),
      body: threads.isEmpty
          ? _Empty(l10n: l10n)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) =>
                  _ThreadTile(thread: threads[i], myUid: myUid),
            ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.myUid});

  final ChatThread thread;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = thread.title(myUid);
    final time = thread.lastMessageAt != null
        ? DateFormat.Hm().format(thread.lastMessageAt!)
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            thread.isEnded ? scheme.surfaceContainerHighest : scheme.primary,
        child: Icon(
          thread.isGroup ? Icons.group_rounded : Icons.person_rounded,
          color: thread.isEnded ? scheme.onSurfaceVariant : scheme.onPrimary,
        ),
      ),
      title: Text(
        title.isEmpty ? '—' : title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        thread.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        time,
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: thread.id, title: title),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_rounded,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              l10n.chatEmptyTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.chatEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
