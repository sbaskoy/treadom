import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../providers/territory_provider.dart';
import '../services/firestore_service.dart';

/// Oyuncu panelini (arama + sıralama) modal alt sayfa olarak açar.
///
/// Arama kutusu boşken en çok alana sahip ilk 5 oyuncuyu ve —ilk 5 dışındaysa—
/// bağlı kullanıcının kendi sırasını gösterir. Kullanıcı bir ad yazınca
/// kullanıcı adına göre arama yapılır. Herhangi bir satıra dokununca panel
/// kapanır ve [onTapUser] ilgili kullanıcının kimliğiyle çağrılır.
Future<void> showLeaderboardSheet(
  BuildContext context, {
  required void Function(String uid, String username) onTapUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      // Klavye açılınca panel klavyenin üstünde kalsın.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _PlayersSheet(onTapUser: onTapUser),
    ),
  );
}

class _PlayersSheet extends StatefulWidget {
  const _PlayersSheet({required this.onTapUser});

  final void Function(String uid, String username) onTapUser;

  @override
  State<_PlayersSheet> createState() => _PlayersSheetState();
}

class _PlayersSheetState extends State<_PlayersSheet> {
  final _controller = TextEditingController();
  final _firestore = FirestoreService();

  String _query = '';
  bool _searching = false;
  List<AppUser> _results = const [];
  int _searchToken = 0; // yarış durumlarını (race) önlemek için

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String value) async {
    final q = value.trim();
    setState(() => _query = q);
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }

    final token = ++_searchToken;
    setState(() => _searching = true);
    final users = await _firestore.searchUsersByUsername(q);
    if (!mounted || token != _searchToken) return; // eski sonuçları yok say
    setState(() {
      _results = users;
      _searching = false;
    });
  }

  void _pick(String uid, String username) {
    Navigator.of(context).pop();
    widget.onTapUser(uid, username);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arama kutusu.
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // İçerik: arama yapılıyorsa sonuçlar, değilse sıralama.
            if (_query.isEmpty)
              _LeaderboardSection(onTap: _pick)
            else
              _SearchResults(
                searching: _searching,
                results: _results,
                onTap: _pick,
                l10n: l10n,
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

/// Arama kutusu boşken gösterilen sıralama bölümü (canlı).
class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({required this.onTap});

  final void Function(String uid, String username) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Consumer<TerritoryProvider>(
      builder: (context, territory, _) {
        final entries = territory.leaderboard;
        final top = entries.take(5).toList();
        final myRank = territory.myRank;
        final myEntry = territory.myEntry;
        final inTop = myRank != null && myRank <= 5;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.leaderboardTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.leaderboardEmpty,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < top.length; i++)
                _PlayerRow(
                  rank: i + 1,
                  name: top[i].uid == territory.uid
                      ? l10n.leaderboardYou
                      : top[i].username,
                  areaM2: top[i].areaM2,
                  count: top[i].territoryCount,
                  isMe: top[i].uid == territory.uid,
                  l10n: l10n,
                  onTap: () => onTap(top[i].uid, top[i].username),
                ),
            if (!inTop && myRank != null && myEntry != null) ...[
              const Divider(height: 24),
              _PlayerRow(
                rank: myRank,
                name: l10n.leaderboardYou,
                areaM2: myEntry.areaM2,
                count: myEntry.territoryCount,
                isMe: true,
                l10n: l10n,
                onTap: () => onTap(myEntry.uid, myEntry.username),
              ),
            ],
            if (myRank == null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.leaderboardNoRank,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Arama sonuçları bölümü.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.searching,
    required this.results,
    required this.onTap,
    required this.l10n,
    required this.theme,
  });

  final bool searching;
  final List<AppUser> results;
  final void Function(String uid, String username) onTap;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.searchNoResults,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Her sonucun alanını canlı (Consumer) okuyalım.
    return Consumer<TerritoryProvider>(
      builder: (context, territory, _) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, i) {
              final u = results[i];
              return _PlayerRow(
                rank: null,
                name: u.username,
                areaM2: territory.areaOf(u.uid),
                count: null,
                isMe: u.uid == territory.uid,
                l10n: l10n,
                onTap: () => onTap(u.uid, u.username),
              );
            },
          ),
        );
      },
    );
  }
}

/// Hem sıralamada hem aramada kullanılan tek oyuncu satırı.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.rank,
    required this.name,
    required this.areaM2,
    required this.count,
    required this.isMe,
    required this.l10n,
    required this.onTap,
  });

  /// Sıra (sıralamada dolu, aramada null → kişi simgesi gösterilir).
  final int? rank;
  final String name;
  final double areaM2;
  final int? count;
  final bool isMe;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: isMe
          ? scheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 36, child: _LeadingBadge(rank: rank)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    if (count != null)
                      Text(
                        l10n.leaderboardCount(count!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatArea(l10n, areaM2),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatArea(AppLocalizations l10n, double m2) {
    if (m2 < 1000000) return l10n.areaSquareMeters(m2.round().toString());
    return l10n.areaSquareKilometers((m2 / 1000000).toStringAsFixed(2));
  }
}

/// İlk üç için madalya, sonrası için "#n"; arama satırında kişi simgesi.
class _LeadingBadge extends StatelessWidget {
  const _LeadingBadge({required this.rank});
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (rank == null) {
      return Icon(Icons.person_rounded, color: scheme.onSurfaceVariant);
    }
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final medal = medals[rank];
    if (medal != null) {
      return Text(medal, style: const TextStyle(fontSize: 24));
    }
    return Text(
      '#$rank',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onSurfaceVariant,
          ),
    );
  }
}
