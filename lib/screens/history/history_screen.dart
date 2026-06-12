import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/run_record.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/run_math.dart';
import '../../widgets/route_preview.dart';

/// Kullanıcının tamamladığı turları (yürüme geçmişi) listeleyen ekran.
///
/// Her kart bir turu özetler: tarih, mesafe, süre ve —varsa— sahiplenilen
/// alan ile o turda gerçekleşen fetih sayısı.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = context.read<AuthProvider>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: uid == null
          ? _Empty(l10n: l10n)
          : StreamBuilder<List<RunRecord>>(
              stream: FirestoreService().userRunsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final runs = snapshot.data ?? const [];
                if (runs.isEmpty) return _Empty(l10n: l10n);

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: runs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _RunCard(run: runs[i], l10n: l10n),
                );
              },
            ),
    );
  }
}

/// Tek bir turu özetleyen kart.
class _RunCard extends StatelessWidget {
  const _RunCard({required this.run, required this.l10n});

  final RunRecord run;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final dateStr = run.createdAt != null
        ? DateFormat.yMMMMd(locale).add_Hm().format(run.createdAt!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_run_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Koşulan güzergah, çizgi (rota) olarak gösterilir.
          if (run.route.length >= 2) ...[
            RoutePreview(route: run.route, color: scheme.primary),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _Metric(
                icon: Icons.straighten_rounded,
                value: _formatDistance(l10n, run.distanceM),
                label: l10n.runDistanceLabel,
              ),
              _Metric(
                icon: Icons.timer_outlined,
                value: formatElapsed(run.duration),
                label: l10n.runElapsedLabel,
              ),
              _Metric(
                icon: Icons.crop_square_rounded,
                value: _formatArea(l10n, run.areaM2),
                label: l10n.runAreaLabel,
              ),
            ],
          ),
          if (run.claimedTerritory || run.conqueredCount > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (run.claimedTerritory)
                  _Badge(
                    icon: Icons.flag_rounded,
                    text: run.territoryName?.isNotEmpty == true
                        ? run.territoryName!
                        : l10n.historyClaimedBadge,
                    color: scheme.primary,
                  ),
                if (run.conqueredCount > 0)
                  _Badge(
                    icon: Icons.military_tech_rounded,
                    text: l10n.historyConqueredBadge(run.conqueredCount),
                    color: scheme.error,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDistance(AppLocalizations l10n, double meters) {
    if (meters < 1000) return l10n.distanceMeters(meters.round().toString());
    return l10n.distanceKilometers((meters / 1000).toStringAsFixed(2));
  }

  static String _formatArea(AppLocalizations l10n, double m2) {
    if (m2 < 1000000) return l10n.areaSquareMeters(m2.round().toString());
    return l10n.areaSquareKilometers((m2 / 1000000).toStringAsFixed(2));
  }
}

/// Kart içindeki tek bir ölçü (ikon + değer + etiket).
class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
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

/// Sahiplenme/fetih rozeti.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Geçmiş boşken gösterilen durum.
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
            Icon(Icons.history_rounded,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              l10n.historyEmptyTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.historyEmptyMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

