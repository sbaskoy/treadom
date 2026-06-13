import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/territory.dart';
import '../../providers/auth_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/run_provider.dart';
import '../../providers/territory_provider.dart';
import '../../providers/weight_provider.dart';
import '../../services/geo.dart';
import '../../services/push_service.dart';
import '../../services/run_math.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/leaderboard_sheet.dart';
import '../chat/chats_screen.dart';
import '../profile/profile_screen.dart';
import 'run_controls.dart';
import 'run_summary_sheet.dart';
import 'territory_detail_sheet.dart';

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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  /// Türkiye'nin merkezine yakın bir varsayılan görünüm (konum gelene kadar).
  static const LatLng _fallbackCenter = LatLng(39.925, 32.866);

  /// Takip modunda haritayı ortalarken kullanılan yakınlaştırma.
  static const double _followZoom = 17;

  // --- Yumuşak (smooth) konum animasyonu ---
  // GPS noktaları seyrek gelir (ör. her birkaç metrede bir). Avatarı ve
  // takip eden kamerayı noktadan noktaya zıplatmak yerine aradaki yolu
  // [_moveController] ile interpolasyon yaparak akıcı şekilde kat ediyoruz.
  late final AnimationController _moveController;
  LatLng? _displayedPos; // ekranda gösterilen (animasyonlu) konum
  LatLng? _animFrom;
  LatLng? _animTo;
  LatLng? _lastTarget; // en son hedeflediğimiz ham GPS noktası

  /// Harita kullanıcının konumunu otomatik takip ediyor mu? Kullanıcı haritayı
  /// elle gezdirince kapanır, "konumuma dön"e basınca yeniden açılır.
  bool _follow = true;
  bool _didFirstFix = false;

  /// Bir turun bitişinde alan sahiplenme akışını yalnızca bir kez tetiklemek
  /// için bayrak. Tur "idle"a dönünce sıfırlanır.
  bool _claimHandled = false;

  /// Sıralamadan bir kullanıcıya dokununca odaklanılan kullanıcının kimliği;
  /// onun alanları haritada daha kalın kenarlıkla vurgulanır.
  String? _focusedUid;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_onMoveTick);

    // İlk kare çizildikten sonra izin/konum akışını ve alan akışını başlat.
    // (Onboarding artık girişten ÖNCE, kök ekranda gösterilir.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().initLocation();
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<TerritoryProvider>().bind(uid);
        context.read<ChatProvider>().bind(uid);
        // Push bildirim izni iste ve FCM token'ını kullanıcıya bağla.
        PushService.instance.registerForUser(uid);
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Animasyonun her karesinde ara konumu hesaplar; takip açıksa kamerayı da
  /// bu ara konuma yumuşakça kaydırır.
  void _onMoveTick() {
    final from = _animFrom;
    final to = _animTo;
    if (from == null || to == null) return;

    final t = Curves.easeInOut.transform(_moveController.value);
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    final point = LatLng(lat, lng);

    setState(() => _displayedPos = point);
    if (_follow) {
      _mapController.move(point, _mapController.camera.zoom);
    }
  }

  /// Yeni bir GPS noktası geldiğinde gösterilen konumdan oraya animasyon başlatır.
  void _animateTo(LatLng target) {
    _animFrom = _displayedPos ?? target;
    _animTo = target;
    _moveController.forward(from: 0);
  }

  /// Konum sağlayıcısından gelen yeni konumu işler (build sırasında çağrılır).
  void _handlePosition(LatLng target) {
    if (_lastTarget == target) return;
    _lastTarget = target;

    if (!_didFirstFix) {
      // İlk konumda animasyon olmadan doğrudan oraya otur ve ortala.
      _didFirstFix = true;
      _displayedPos = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(target, _followZoom);
      });
    } else {
      _animateTo(target);
    }
  }

  /// Harita her hareket ettiğinde tetiklenir. Hareket kullanıcı el hareketinden
  /// kaynaklanıyorsa takip modunu kapatırız (kullanıcı serbestçe gezsin).
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && _follow) {
      setState(() => _follow = false);
    }
    // Görünür alanı sağlayıcıya bildir → alanlar yalnızca bu kutu için sorgulanır
    // (tüm koleksiyon indirilmez). Sağlayıcı debounce/eşik uygular.
    final b = camera.visibleBounds;
    context.read<TerritoryProvider>().setViewport(
          minLat: b.south,
          maxLat: b.north,
          minLng: b.west,
          maxLng: b.east,
        );
  }

  /// Tur durumunu izler; "finished"a geçişte alan sahiplenme akışını bir kez
  /// başlatır, "idle"a dönünce bayrağı sıfırlar (yeni tura hazır).
  void _maybeHandleFinish(RunProvider run) {
    if (run.status == RunStatus.idle) {
      _claimHandled = false;
      return;
    }
    if (run.status == RunStatus.finished && !_claimHandled) {
      _claimHandled = true;
      // build sırasında diyalog/snackbar açamayız; bir sonraki kareye bırak.
      final route = run.route;
      final areaM2 = run.areaM2;
      final distanceM = run.distanceM;
      final elapsed = run.elapsed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishRun(
          route: route,
          areaM2: areaM2,
          distanceM: distanceM,
          elapsed: elapsed,
        );
      });
    }
  }

  /// Biten turu işler: döngü kapandıysa isim diyaloğunu gösterip alanı
  /// sahiplenir ve çakışan rakip alanları fetheder; her durumda turu geçmişe
  /// kaydeder ve sonucu bir bildirimle özetler.
  Future<void> _finishRun({
    required List<LatLng> route,
    required double areaM2,
    required double distanceM,
    required Duration elapsed,
  }) async {
    final territory = context.read<TerritoryProvider>();
    final weightKg = context.read<WeightProvider>().weightKg;

    // Yalnızca kapanmış bir halka alan oluşturur. Kapanmadıysa neden olduğunu
    // (çok kısa / halka kapanmadı) özet ekranında kullanıcıya bildiririz.
    final loop = territory.checkLoop(route);
    final canClaim = loop.valid;

    // Artık isim sorulmaz: kullanıcının tek alan adı (landName) kullanılır.
    final outcome = await territory.claim(
      route: route,
      areaM2: areaM2,
      distanceM: distanceM,
      elapsed: elapsed,
    );
    if (!mounted) return;

    // Snackbar yerine zengin koşu özeti göster.
    await showRunSummary(
      context,
      route: route,
      distanceM: distanceM,
      areaM2: areaM2,
      elapsed: elapsed,
      pace: pacePerKm(elapsed, distanceM),
      calories: estimateCalories(weightKg: weightKg, distanceKm: distanceM / 1000),
      claimed: canClaim,
      loopFailReason: loop.reason,
      claimedName: territory.landName,
      conqueredFrom: outcome?.conqueredFrom ?? const [],
      onNewRun: () {
        if (mounted) context.read<RunProvider>().reset();
      },
    );
  }

  /// Haritayı kullanıcının konumuna ortalar ve takip modunu yeniden açar.
  void _recenter() {
    final pos = _displayedPos ??
        () {
          final p = context.read<LocationProvider>().position;
          return p == null ? null : LatLng(p.latitude, p.longitude);
        }();
    if (pos == null) return;
    setState(() => _follow = true);
    _mapController.move(pos, _followZoom);
  }

  /// Haritada bir alana dokunulunca o alanın detay panelini açar. Çakışan
  /// alanlarda en küçük (en spesifik) olanı seçilir.
  void _onMapTap(LatLng latlng) {
    final tp = context.read<TerritoryProvider>();
    Territory? hit;
    for (final t in tp.territories) {
      if (t.points.length < 3) continue;
      if (pointInShape(latlng, t.points, t.holes)) {
        if (hit == null || t.areaM2 < hit.areaM2) hit = t;
      }
    }
    if (hit == null) return;
    showTerritoryDetail(context, territory: hit, mine: tp.isMine(hit));
  }

  /// Sıralama panelini açar; bir kullanıcıya dokununca haritayı onun
  /// topraklarına odaklar.
  void _openLeaderboard() {
    showLeaderboardSheet(context, onTapUser: _focusUser);
  }

  /// Haritayı belirtilen kullanıcının tüm alanlarını kapsayacak şekilde
  /// kaydırır/yakınlaştırır ve o alanları vurgular.
  Future<void> _focusUser(String uid, String username) async {
    final territory = context.read<TerritoryProvider>();
    // O kullanıcının alanları viewport dışında olabileceğinden tek seferlik
    // sorguyla getir.
    final points = await territory.pointsOf(uid);
    if (!mounted) return;
    if (points.isEmpty) {
      // Aranan/seçilen kişinin henüz alanı yoksa kullanıcıyı bilgilendir.
      showAppSnackBar(
        context,
        AppLocalizations.of(context).searchNoTerritory(username),
        type: AppSnackBarType.info,
      );
      return;
    }
    setState(() {
      _follow = false;
      _focusedUid = uid;
    });
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(64),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final location = context.watch<LocationProvider>();
    final pos = location.position;

    // Yeni konum geldiğinde animasyon/takip mantığını çalıştır.
    if (pos != null) {
      _handlePosition(LatLng(pos.latitude, pos.longitude));
      // Yakındakiler özelliği için konumu paylaş (sağlayıcı kısar/throttle).
      context.read<ChatProvider>().updateMyLocation(
            pos.latitude,
            pos.longitude,
          );
    }

    // Tur bittiğinde (bir kez) alan sahiplenme/fetih akışını tetikle.
    _maybeHandleFinish(context.watch<RunProvider>());

    return Scaffold(
      // Harita ekranı kenardan kenara çizilir; üst çubuk haritanın üzerinde
      // yüzer (modern, sürükleyici his). StackFit.expand ile gövde (harita)
      // tüm ekranı kaplar; üst çubuk yalnızca üstte konumlandırılır.
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(context, l10n, location),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MapTopBar(
              title: l10n.appTitle,
              profileTooltip: l10n.profileTooltip,
              leaderboardTooltip: l10n.leaderboardTooltip,
              chatTooltip: l10n.chatTooltip,
              onProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              onLeaderboard: _openLeaderboard,
              onChat: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatsScreen()),
                );
              },
            ),
          ),

          // Alt koşu kontrolleri yalnızca konum hazırken anlamlıdır.
          if (location.status == LocationStatus.ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RunControls(
                recenterTooltip: l10n.recenterTooltip,
                onRecenter: location.position != null ? _recenter : null,
              ),
            ),
        ],
      ),
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
    // Ekranda gösterilen (animasyonlu) konum; yoksa ham GPS ya da varsayılan.
    final pos = location.position;
    final avatarPoint = _displayedPos ??
        (pos != null ? LatLng(pos.latitude, pos.longitude) : null);
    final center = avatarPoint ?? _fallbackCenter;

    // Koşu turunun rotasını/alanını harita üzerine çizmek için izliyoruz.
    final run = context.watch<RunProvider>();
    final route = run.route;
    final avatar = context.watch<AvatarProvider>().avatar;
    final scheme = Theme.of(context).colorScheme;
    final darkMap = Theme.of(context).brightness == Brightness.dark;

    // Kayıtlı tüm alanları (kendi + rakip) izle. Kendi alanların tema rengiyle,
    // rakip alanlar uyarı (kırmızı) rengiyle çizilir; merkezde isim etiketi.
    final territoryProvider = context.watch<TerritoryProvider>();
    final territories = territoryProvider.territories;
    Color ownerColor(Territory t) =>
        territoryProvider.isMine(t) ? scheme.primary : scheme.error;

    // Koşarken alanı HEMEN doldurmayız: yalnızca iz gerçekten kapalı bir halka
    // oluşturduğunda (başlangıca ya da kendi alanına dönülünce) dolu gösterilir.
    // Böylece kullanıcı halkayı kapatınca anında görsel geri bildirim alır.
    final liveLoopClosed =
        route.length >= 4 && territoryProvider.checkLoop(route).valid;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _followZoom,
        minZoom: 3,
        maxZoom: 19,
        onPositionChanged: _onPositionChanged,
        onTap: (_, latlng) => _onMapTap(latlng),
      ),
      children: [
        TileLayer(
          // Markayla uyumlu, sade harita stili: koyu modda CartoDB Dark Matter
          // (alanlar patlar), açık modda CartoDB Positron (temiz, tasarımlı).
          urlTemplate: darkMap
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'app.treadom',
          maxZoom: 20,
        ),

        // Kayıtlı alanlar (aktif turun altında, zemin gibi çizilir).
        if (territories.isNotEmpty) ...[
          PolygonLayer(
            polygons: [
              for (final t in territories)
                if (t.points.length >= 3)
                  () {
                    final mine = territoryProvider.isMine(t);
                    final focused = t.ownerUid == _focusedUid;
                    // Kendi alanların ve sıralamadan seçilen kullanıcının
                    // alanları belirgin (kalın kenar + yoğun dolgu); diğerleri
                    // soluk kalır.
                    final emphasize = mine || focused;
                    return Polygon(
                      points: t.points,
                      holePointsList: t.holes.isEmpty ? null : t.holes,
                      color: ownerColor(t).withValues(
                        alpha: emphasize ? 0.38 : 0.12,
                      ),
                      borderColor: ownerColor(t),
                      borderStrokeWidth: emphasize ? 5 : 1.5,
                    );
                  }(),
            ],
          ),
          MarkerLayer(
            markers: [
              for (final t in territories)
                if (t.points.length >= 3)
                  Marker(
                    point: polygonCentroid(t.points),
                    width: 160,
                    height: 40,
                    alignment: Alignment.center,
                    child: _TerritoryLabel(
                      name: t.displayName,
                      color: ownerColor(t),
                      mine: territoryProvider.isMine(t),
                    ),
                  ),
            ],
          ),
        ],

        // Çevrelenen alan yalnızca halka KAPANINCA dolu gösterilir; aksi halde
        // (sadece iz varken) doldurulmaz — koşu hemen alana dönüşmez.
        if (liveLoopClosed)
          PolygonLayer(
            polygons: [
              Polygon(
                points: route,
                color: scheme.primary.withValues(alpha: 0.25),
                borderColor: scheme.primary,
                borderStrokeWidth: 3,
              ),
            ],
          ),

        // Geçilen rota (polyline).
        if (route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                color: scheme.primary,
                strokeWidth: 4,
              ),
            ],
          ),

        // Başlangıç noktası işareti (turun kapanışını görmek için).
        if (route.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: route.first,
                width: 18,
                height: 18,
                child: _RouteEndpoint(color: scheme.primary),
              ),
            ],
          ),

        if (avatarPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: avatarPoint,
                width: 64,
                height: 72,
                alignment: Alignment.center,
                child: _AvatarMarker(
                  emoji: avatar.emoji,
                  running: run.isRunning,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Haritanın üzerinde yüzen, modern "cam" görünümlü üst çubuk.
///
/// Solda marka hapı (uygulama adı + simge), sağda dairesel ayarlar ve çıkış
/// aksiyonları bulunur. Tümü yarı saydam yüzeyler ve yumuşak gölgelerle
/// haritanın üzerinde okunaklı durur.
class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.title,
    required this.profileTooltip,
    required this.leaderboardTooltip,
    required this.chatTooltip,
    required this.onProfile,
    required this.onLeaderboard,
    required this.onChat,
  });

  final String title;
  final String profileTooltip;
  final String leaderboardTooltip;
  final String chatTooltip;
  final VoidCallback onProfile;
  final VoidCallback onLeaderboard;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            // Marka hapı (doğal genişlik; üst çubukta 2 ikon olduğundan yer bol).
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: _surfaceDecoration(scheme, radius: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_rounded, size: 22, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _CircleAction(
              icon: Icons.emoji_events_rounded,
              tooltip: leaderboardTooltip,
              onTap: onLeaderboard,
            ),
            const SizedBox(width: 8),
            _CircleAction(
              icon: Icons.chat_bubble_rounded,
              tooltip: chatTooltip,
              onTap: onChat,
            ),
            const SizedBox(width: 8),
            _CircleAction(
              icon: Icons.person_rounded,
              tooltip: profileTooltip,
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

/// Üst çubuktaki dairesel aksiyon butonu (ayarlar/çıkış).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: _surfaceDecoration(scheme, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        color: scheme.onSurface,
        onPressed: onTap,
      ),
    );
  }
}

/// Üst çubuk öğeleri için ortak yarı saydam yüzey + ince kenarlık + gölge.
/// [shape] daire ise [radius] yok sayılır.
BoxDecoration _surfaceDecoration(
  ColorScheme scheme, {
  double radius = 16,
  BoxShape shape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    color: scheme.surface.withValues(alpha: 0.92),
    shape: shape,
    borderRadius:
        shape == BoxShape.circle ? null : BorderRadius.circular(radius),
    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Koşu rotasının başlangıç noktasını gösteren küçük halka.
class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
      ),
    );
  }
}

/// Bir alanın merkezinde yüzen, modern isim etiketi.
///
/// Yarı saydam koyu zemin üzerinde okunaklı beyaz metin; solda sahibi belli
/// eden renkli bir nokta (kendi alanların tema rengi, rakipler kırmızı), kendi
/// alanların için ayrıca bir bayrak simgesi. Haritanın üzerinde net durur.
class _TerritoryLabel extends StatelessWidget {
  const _TerritoryLabel({
    required this.name,
    required this.color,
    required this.mine,
  });

  final String name;
  final Color color;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mine ? Icons.flag_rounded : Icons.local_fire_department_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kullanıcının konumunu temsil eden avatar işaretçisi.
///
/// Seçili emoji, beyaz halka içinde dairesel bir rozette gösterilir. Koşu
/// sırasında hafifçe zıplar (bob) ve arkasında nabız gibi atan bir halka
/// belirir — gerçekten koşuyormuş hissi verir.
class _AvatarMarker extends StatefulWidget {
  const _AvatarMarker({required this.emoji, required this.running});

  final String emoji;
  final bool running;

  @override
  State<_AvatarMarker> createState() => _AvatarMarkerState();
}

class _AvatarMarkerState extends State<_AvatarMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.running) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AvatarMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Koşma durumu değişince animasyonu başlat/durdur.
    if (widget.running && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.running && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0..1 (reverse ile gidip gelir)
        // Koşarken yukarı-aşağı zıplama ve hafif büyüme.
        final bob = widget.running ? -6.0 * t : 0.0;
        final scale = widget.running ? 1.0 + 0.06 * t : 1.0;

        return SizedBox(
          width: 64,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Koşarken nabız gibi atan halka.
              if (widget.running)
                Opacity(
                  opacity: (1 - t) * 0.35,
                  child: Container(
                    width: 44 + 24 * t,
                    height: 44 + 24 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, bob),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      child: _AvatarBadge(emoji: widget.emoji, color: scheme.primary),
    );
  }
}

/// Avatar emojisini içeren dairesel rozet (beyaz zemin + renkli halka + gölge).
class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.emoji, required this.color});

  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
