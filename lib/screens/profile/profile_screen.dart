import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/run_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/territory_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

/// Kullanıcının profili: avatar, alan adı, toplam alan, sıra, sahip olunan
/// alan sayısı ve yürüme geçmişinden türetilen toplamlar (mesafe, tur, fetih).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final territory = context.watch<TerritoryProvider>();
    final avatar = context.watch<AvatarProvider>().avatar;
    final uid = context.read<AuthProvider>().currentUser?.uid;

    final myEntry = territory.myEntry;
    final rank = territory.myRank;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Başlık: avatar + ad ---
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 3),
                  ),
                  child: Text(avatar.emoji,
                      style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 14),
                Text(
                  territory.landName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${territory.username}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // --- İstatistikler ---
          StreamBuilder<List<RunRecord>>(
            stream: uid == null
                ? const Stream.empty()
                : FirestoreService().userRunsStream(uid),
            builder: (context, snapshot) {
              final runs = snapshot.data ?? const <RunRecord>[];
              final totalDistance =
                  runs.fold<double>(0, (a, r) => a + r.distanceM);
              final conquests =
                  runs.fold<int>(0, (a, r) => a + r.conqueredCount);

              final valueStyle = theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold);
              final isFirst = rank == 1;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    icon: Icons.crop_square_rounded,
                    value: _AnimatedNumber(
                      value: myEntry?.areaM2 ?? 0,
                      format: (v) => _area(l10n, v),
                      style: valueStyle,
                    ),
                    label: l10n.runAreaLabel,
                    color: scheme.primary,
                  ),
                  _StatCard(
                    icon: Icons.emoji_events_rounded,
                    value: rank != null
                        ? _AnimatedNumber(
                            value: rank.toDouble(),
                            format: (v) => '#${v.round()}',
                            style: valueStyle?.copyWith(
                              color: isFirst ? AppTheme.rewardColor : null,
                            ),
                          )
                        : Text(l10n.profileUnranked, style: valueStyle),
                    label: l10n.profileRankLabel,
                    color: isFirst ? AppTheme.rewardColor : scheme.primary,
                  ),
                  _StatCard(
                    icon: Icons.flag_rounded,
                    value: _AnimatedNumber(
                      value: (myEntry?.territoryCount ?? 0).toDouble(),
                      format: (v) => '${v.round()}',
                      style: valueStyle,
                    ),
                    label: l10n.profileLandsLabel,
                    color: scheme.primary,
                  ),
                  _StatCard(
                    icon: Icons.straighten_rounded,
                    value: _AnimatedNumber(
                      value: totalDistance,
                      format: (v) => _distance(l10n, v),
                      style: valueStyle,
                    ),
                    label: l10n.runDistanceLabel,
                    color: scheme.secondary,
                  ),
                  _StatCard(
                    icon: Icons.directions_run_rounded,
                    value: _AnimatedNumber(
                      value: runs.length.toDouble(),
                      format: (v) => '${v.round()}',
                      style: valueStyle,
                    ),
                    label: l10n.profileRunsLabel,
                    color: scheme.secondary,
                  ),
                  _StatCard(
                    icon: Icons.military_tech_rounded,
                    value: _AnimatedNumber(
                      value: conquests.toDouble(),
                      format: (v) => '${v.round()}',
                      style: valueStyle,
                    ),
                    label: l10n.profileConquestsLabel,
                    color: scheme.error,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // --- Kısayollar: geçmiş, ayarlar, çıkış ---
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text(l10n.historyTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.settingsTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: scheme.error),
                  title: Text(
                    l10n.signOutButton,
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    context.read<AuthProvider>().signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _area(AppLocalizations l10n, double m2) => m2 < 1000000
      ? l10n.areaSquareMeters(m2.round().toString())
      : l10n.areaSquareKilometers((m2 / 1000000).toStringAsFixed(2));

  static String _distance(AppLocalizations l10n, double m) => m < 1000
      ? l10n.distanceMeters(m.round().toString())
      : l10n.distanceKilometers((m / 1000).toStringAsFixed(2));
}

/// Profil istatistik kartı (ikon + değer + etiket). İki sütuna sığacak genişlik.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final Widget value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = (MediaQuery.of(context).size.width - 40 - 12) / 2;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Açılışta 0'dan hedef değere yumuşakça sayan animasyonlu sayı.
class _AnimatedNumber extends StatelessWidget {
  const _AnimatedNumber({
    required this.value,
    required this.format,
    this.style,
  });

  final double value;
  final String Function(double) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        format(v),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
