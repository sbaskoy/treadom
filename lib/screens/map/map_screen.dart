import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../settings/settings_screen.dart';

/// Aşama 2 ana ekranı: kullanıcının canlı konumunu OpenStreetMap üzerinde
/// gösteren harita.
///
/// İzin/servis durumlarını [LocationProvider] üzerinden izler; konum hazır
/// olduğunda haritayı kullanıcının üzerine ortalar ve hareketini takip eder.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  /// Harita ilk geçerli konuma bir kez otomatik ortalandı mı? Sürekli
  /// ortalamak kullanıcının haritayı elle gezmesini engellerdi.
  bool _didInitialCenter = false;

  /// Türkiye'nin merkezine yakın bir varsayılan görünüm (konum gelene kadar).
  static const LatLng _fallbackCenter = LatLng(39.925, 32.866);

  @override
  void initState() {
    super.initState();
    // İlk kare çizildikten sonra izin/konum akışını başlat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().initLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Haritayı kullanıcının son bilinen konumuna ortalar.
  void _recenter() {
    final pos = context.read<LocationProvider>().position;
    if (pos == null) return;
    _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final location = context.watch<LocationProvider>();
    final pos = location.position;

    // Konum geldiğinde ilk seferde haritayı otomatik ortala.
    if (pos != null && !_didInitialCenter) {
      _didInitialCenter = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOutButton,
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: _buildBody(context, l10n, location),
      floatingActionButton: location.status == LocationStatus.ready
          ? FloatingActionButton(
              tooltip: l10n.recenterTooltip,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    LocationProvider location,
  ) {
    switch (location.status) {
      case LocationStatus.initial:
      case LocationStatus.loading:
        // Konum henüz gelmediyse yükleniyor; gelmişse (yeniden ortalama gibi)
        // haritayı göster.
        if (location.position == null) {
          return _LoadingState(message: l10n.locationLoading);
        }
        return _buildMap(location);

      case LocationStatus.ready:
        return _buildMap(location);

      case LocationStatus.serviceDisabled:
        return _LocationError(
          icon: Icons.location_off_outlined,
          title: l10n.locationServiceDisabledTitle,
          message: l10n.locationServiceDisabledMessage,
          primaryLabel: l10n.openSettingsButton,
          onPrimary: () =>
              context.read<LocationProvider>().openLocationSettings(),
          secondaryLabel: l10n.retryButton,
          onSecondary: () =>
              context.read<LocationProvider>().initLocation(),
        );

      case LocationStatus.permissionDenied:
        return _LocationError(
          icon: Icons.location_disabled_outlined,
          title: l10n.locationPermissionDeniedTitle,
          message: l10n.locationPermissionDeniedMessage,
          primaryLabel: l10n.retryButton,
          onPrimary: () => context.read<LocationProvider>().initLocation(),
        );

      case LocationStatus.permissionDeniedForever:
        return _LocationError(
          icon: Icons.location_disabled_outlined,
          title: l10n.locationPermissionDeniedTitle,
          message: l10n.locationPermissionDeniedForeverMessage,
          primaryLabel: l10n.openSettingsButton,
          onPrimary: () => context.read<LocationProvider>().openAppSettings(),
          secondaryLabel: l10n.retryButton,
          onSecondary: () =>
              context.read<LocationProvider>().initLocation(),
        );
    }
  }

  Widget _buildMap(LocationProvider location) {
    final pos = location.position;
    final center = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : _fallbackCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM kullanım politikası gereği gerçek bir paket adı belirtilir.
          userAgentPackageName: 'app.treadom',
          maxZoom: 19,
        ),
        if (pos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(pos.latitude, pos.longitude),
                width: 28,
                height: 28,
                child: const _UserLocationDot(),
              ),
            ],
          ),
      ],
    );
  }
}

/// Kullanıcının konumunu temsil eden mavi nokta (beyaz halka içinde).
class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// Konum alınırken gösterilen yükleniyor durumu.
class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Konum servisi/izni ile ilgili hata durumlarını gösteren bilgilendirme
/// görünümü. Birincil ve isteğe bağlı ikincil bir aksiyon sunar.
class _LocationError extends StatelessWidget {
  const _LocationError({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onPrimary,
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
