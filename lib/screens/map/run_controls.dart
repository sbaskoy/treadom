import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/run_provider.dart';
import '../../providers/weight_provider.dart';
import '../../services/foreground_service.dart';
import '../../services/run_math.dart';

/// Haritanın altında yüzen koşu kontrol paneli.
///
/// Tur durumuna göre değişir:
/// - boştayken: "Koşmaya Başla" butonu
/// - koşarken: canlı süre/mesafe/tempo/kalori + "Turu Bitir"
/// - bittiğinde: sonuç istatistikleri + "Yeni Tur"
class RunControls extends StatelessWidget {
  const RunControls({super.key, required this.recenterTooltip, this.onRecenter});

  /// "Konumuma dön" butonunun ipucu metni.
  final String recenterTooltip;

  /// Haritayı kullanıcının konumuna ortalayan geri çağrı. null ise (konum
  /// henüz hazır değilse) recenter butonu gizlenir.
  final VoidCallback? onRecenter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final run = context.watch<RunProvider>();
    final weightKg = context.watch<WeightProvider>().weightKg;

    // "Koşmaya Başla" arka plan servisi için yerelleştirilmiş metinleri ve
    // kullanıcı kilosunu toplayıp sağlayıcıya verir.
    void startRun() {
      final params = RunNotificationParams(
        title: l10n.runOngoingTitle,
        initialText: _notificationPreview(l10n),
        channelName: l10n.notificationChannelName,
        unitKm: l10n.unitKilometers,
        unitM: l10n.unitMeters,
        unitKcal: l10n.unitKcal,
        paceSuffix: l10n.paceSuffix,
        weightKg: weightKg,
      );
      run.start(notification: params);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Recenter butonu, alt kümenin sağ üstünde durur (ana butonla
            // çakışmaması için ayrı bir satırda).
            if (onRecenter != null) ...[
              _RecenterButton(tooltip: recenterTooltip, onTap: onRecenter!),
              const SizedBox(height: 12),
            ],
            // İstatistik kartı yalnızca tur başladıysa görünür.
            if (run.status != RunStatus.idle) ...[
              _StatsCard(
                elapsed: run.elapsed,
                distanceM: run.distanceM,
                pace: run.pace,
                calories: estimateCalories(
                  weightKg: weightKg,
                  distanceKm: run.distanceM / 1000,
                ),
                finished: run.status == RunStatus.finished,
              ),
              const SizedBox(height: 12),
            ],
            _ActionButton(run: run, l10n: l10n, onStart: startRun),
          ],
        ),
      ),
    );
  }

  /// Servis ilk başlarken bildirimde görünecek sıfır değerli önizleme metni.
  static String _notificationPreview(AppLocalizations l10n) {
    return '${formatElapsed(Duration.zero)} · ${l10n.distanceMeters('0')} · '
        '--${l10n.paceSuffix} · ${l10n.caloriesValue('0')}';
  }
}

/// Haritayı kullanıcının konumuna ortalayan dairesel "cam" buton.
class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location_rounded),
        tooltip: tooltip,
        color: scheme.primary,
        onPressed: onTap,
      ),
    );
  }
}

/// Duruma göre değişen ana eylem butonu (Başla / Bitir / Yeni Tur).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.run,
    required this.l10n,
    required this.onStart,
  });

  final RunProvider run;
  final AppLocalizations l10n;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final String label;
    final IconData icon;
    final VoidCallback onPressed;
    final Color background;
    final Color foreground;

    switch (run.status) {
      case RunStatus.idle:
        label = l10n.startRunButton;
        icon = Icons.directions_run_rounded;
        onPressed = onStart;
        background = scheme.primary;
        foreground = scheme.onPrimary;
      case RunStatus.running:
        label = l10n.stopRunButton;
        icon = Icons.stop_rounded;
        onPressed = run.stop;
        background = scheme.error;
        foreground = scheme.onError;
      case RunStatus.finished:
        label = l10n.newRunButton;
        icon = Icons.refresh_rounded;
        onPressed = run.reset;
        background = scheme.primary;
        foreground = scheme.onPrimary;
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

/// Canlı süre/mesafe/tempo/kaloriyi 2×2 ızgarada gösteren yarı saydam kart.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.elapsed,
    required this.distanceM,
    required this.pace,
    required this.calories,
    required this.finished,
  });

  final Duration elapsed;
  final double distanceM;
  final Duration? pace;
  final double calories;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final paceStr = pace != null
        ? '${formatPace(pace!)}${l10n.paceSuffix}'
        : '--${l10n.paceSuffix}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (finished) ...[
            Text(
              l10n.runFinishedTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.timer_outlined,
                  label: l10n.runElapsedLabel,
                  value: formatElapsed(elapsed),
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.straighten_rounded,
                  label: l10n.runDistanceLabel,
                  value: _formatDistance(l10n, distanceM),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.speed_rounded,
                  label: l10n.runPaceLabel,
                  value: paceStr,
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.local_fire_department_outlined,
                  label: l10n.runCaloriesLabel,
                  value: l10n.caloriesValue(calories.round().toString()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mesafeyi 1 km altında metre, üstünde kilometre olarak biçimlendirir.
  static String _formatDistance(AppLocalizations l10n, double meters) {
    if (meters < 1000) {
      return l10n.distanceMeters(meters.round().toString());
    }
    return l10n.distanceKilometers((meters / 1000).toStringAsFixed(2));
  }
}

/// Tek bir istatistik öğesi (ikon + etiket + değer).
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
