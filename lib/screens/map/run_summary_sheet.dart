import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../l10n/app_localizations.dart';
import '../../services/geo.dart' show LoopFailReason;
import '../../services/run_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/route_preview.dart';

/// Tur bittiğinde gösterilen zengin özet: rota çizimi, istatistikler ve
/// sahiplenme/fetih sonucu. "Yeni Tur" ile kapanıp turu sıfırlar.
Future<void> showRunSummary(
  BuildContext context, {
  required List<LatLng> route,
  required double distanceM,
  required double areaM2,
  required Duration elapsed,
  required Duration? pace,
  required double calories,
  required bool claimed,
  LoopFailReason loopFailReason = LoopFailReason.none,
  required String claimedName,
  required List<String> conqueredFrom,
  required VoidCallback onNewRun,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final celebrate = claimed || conqueredFrom.isNotEmpty;

      return Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_circle_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.runFinishedTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (route.length >= 2) ...[
                RoutePreview(route: route, color: scheme.primary, height: 160),
                const SizedBox(height: 16),
              ],

              // 2×2 istatistik ızgarası.
              Row(
                children: [
                  _SummaryStat(
                    icon: Icons.straighten_rounded,
                    label: l10n.runDistanceLabel,
                    value: _distance(l10n, distanceM),
                  ),
                  _SummaryStat(
                    icon: Icons.timer_outlined,
                    label: l10n.runElapsedLabel,
                    value: formatElapsed(elapsed),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SummaryStat(
                    icon: Icons.crop_square_rounded,
                    label: l10n.runAreaLabel,
                    value: _area(l10n, areaM2),
                  ),
                  _SummaryStat(
                    icon: Icons.local_fire_department_outlined,
                    label: l10n.runCaloriesLabel,
                    value: l10n.caloriesValue(calories.round().toString()),
                  ),
                ],
              ),

              // Sahiplenme + fetih sonucu.
              if (claimed) ...[
                const SizedBox(height: 16),
                _ResultChip(
                  icon: Icons.flag_rounded,
                  text: l10n.claimedSnack(claimedName),
                  color: scheme.primary,
                ),
              ],
              // Halka kapanmadıysa neden alan alınmadığını açıkla.
              if (!claimed) ...[
                const SizedBox(height: 16),
                _ResultChip(
                  icon: loopFailReason == LoopFailReason.tooFast
                      ? Icons.directions_car_outlined
                      : Icons.info_outline_rounded,
                  text: switch (loopFailReason) {
                    LoopFailReason.tooShort => l10n.loopTooShortHint,
                    LoopFailReason.tooFast => l10n.loopTooFastHint,
                    _ => l10n.loopNotClosedHint,
                  },
                  color: scheme.onSurfaceVariant,
                ),
              ],
              if (conqueredFrom.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ResultChip(
                  icon: Icons.military_tech_rounded,
                  text: '${l10n.landsConquered(conqueredFrom.length)}'
                      ' (${conqueredFrom.where((e) => e.isNotEmpty).join(", ")})',
                  color: scheme.error,
                ),
              ],

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onNewRun();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.newRunButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
          ),
          if (celebrate) const _CelebrationOverlay(),
        ],
      );
    },
  );
}

String _distance(AppLocalizations l10n, double m) => m < 1000
    ? l10n.distanceMeters(m.round().toString())
    : l10n.distanceKilometers((m / 1000).toStringAsFixed(2));

String _area(AppLocalizations l10n, double m2) => m2 < 1000000
    ? l10n.areaSquareMeters(m2.round().toString())
    : l10n.areaSquareKilometers((m2 / 1000000).toStringAsFixed(2));

/// Özet ızgarasındaki tek istatistik kutusu.
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sahiplenme/fetih sonucunu gösteren satır.
class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sahiplenme/fetih olduğunda özet panelin üstünden aşağı saçılan konfeti.
class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay();

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 1));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConfettiWidget(
      confettiController: _controller,
      blastDirection: math.pi / 2, // aşağı doğru
      emissionFrequency: 0.05,
      numberOfParticles: 14,
      maxBlastForce: 18,
      minBlastForce: 8,
      gravity: 0.25,
      shouldLoop: false,
      colors: [
        scheme.primary,
        AppTheme.rewardColor,
        scheme.error,
        Colors.white,
      ],
    );
  }
}
