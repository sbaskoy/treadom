import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/territory.dart';

/// Haritada bir alana dokunulduğunda açılan detay paneli: sahibi, büyüklüğü,
/// ne zaman alındığı ve —fethedildiyse— kimden alındığı.
Future<void> showTerritoryDetail(
  BuildContext context, {
  required Territory territory,
  required bool mine,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final color = mine ? scheme.primary : scheme.error;
      final locale = Localizations.localeOf(context).toString();

      final areaText = territory.areaM2 < 1000000
          ? l10n.areaSquareMeters(territory.areaM2.round().toString())
          : l10n.areaSquareKilometers(
              (territory.areaM2 / 1000000).toStringAsFixed(2));
      final dateText = territory.createdAt != null
          ? DateFormat.yMMMMd(locale).add_Hm().format(territory.createdAt!)
          : '—';

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    mine
                        ? Icons.flag_rounded
                        : Icons.local_fire_department_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      territory.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                mine
                    ? l10n.territoryYoursLabel
                    : l10n.territoryOwnerLabel(territory.ownerUsername),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.crop_square_rounded,
                label: l10n.runAreaLabel,
                value: areaText,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.event_outlined,
                label: l10n.territoryClaimedLabel,
                value: dateText,
              ),
              if (territory.previousOwnerUsername != null &&
                  territory.previousOwnerUsername!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.military_tech_rounded,
                          size: 20, color: scheme.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.territoryConqueredFromLabel(
                              territory.previousOwnerUsername!),
                          style: TextStyle(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Detay panelindeki tek satır (ikon + etiket + değer).
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
