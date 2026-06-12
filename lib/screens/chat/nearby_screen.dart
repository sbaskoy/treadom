import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

/// Belli mesafedeki (varsayılan 2 km) oyuncuları listeler; birine dokununca
/// onunla 1:1 sohbet açılır.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  late Future<List<NearbyUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ChatProvider>().nearby();
  }

  void _refresh() {
    setState(() => _future = context.read<ChatProvider>().nearby());
  }

  Future<void> _openChat(NearbyUser u) async {
    final chat = context.read<ChatProvider>();
    final id = await chat.openDirect(u.uid, u.username);
    if (id == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: id, title: u.username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasLocation = context.read<ChatProvider>().hasLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatNearbyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: !hasLocation
          ? _Centered(icon: Icons.my_location_rounded, text: l10n.chatNoLocation)
          : FutureBuilder<List<NearbyUser>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snap.data ?? const [];
                if (users.isEmpty) {
                  return _Centered(
                    icon: Icons.person_search_rounded,
                    text: l10n.chatNearbyEmpty,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (u.username.isNotEmpty ? u.username[0] : '?')
                              .toUpperCase(),
                        ),
                      ),
                      title: Text(u.username),
                      subtitle: Text(l10n.chatAway(_dist(u.distanceM))),
                      trailing: const Icon(Icons.chat_bubble_outline_rounded),
                      onTap: () => _openChat(u),
                    );
                  },
                );
              },
            ),
    );
  }

  static String _dist(double m) =>
      m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
