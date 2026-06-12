import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Koşulan güzergahı (rotayı) çizgi olarak gösteren önizleme kutusu.
///
/// Harita karoları yüklemeden, rotanın kendi sınırlarına ölçeklenmiş hâlini
/// hafif bir [CustomPaint] ile çizer; başlangıç ve bitiş noktaları işaretlenir.
/// Hem yürüme geçmişi kartlarında hem koşu özet ekranında kullanılır.
class RoutePreview extends StatelessWidget {
  const RoutePreview({
    super.key,
    required this.route,
    required this.color,
    this.height = 130,
  });

  final List<LatLng> route;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _RoutePainter(route: route, color: color),
        size: Size.infinite,
      ),
    );
  }
}

/// Rota noktalarını kutuya sığacak şekilde ölçekleyip polyline çizer.
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.route, required this.color});

  final List<LatLng> route;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;

    var minLat = double.infinity, maxLat = -double.infinity;
    var minLng = double.infinity, maxLng = -double.infinity;
    for (final p in route) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs();
    // Boylamı enleme göre düzelt (rota gerçekçi oranda görünsün).
    final cosLat = math.cos((minLat + maxLat) / 2 * math.pi / 180).abs();
    final wLng = spanLng * (cosLat == 0 ? 1 : cosLat);

    const pad = 16.0;
    final availW = size.width - pad * 2;
    final availH = size.height - pad * 2;
    final scale = (wLng <= 0 && spanLat <= 0)
        ? 1.0
        : math.min(
            wLng <= 0 ? double.infinity : availW / wLng,
            spanLat <= 0 ? double.infinity : availH / spanLat,
          );
    final drawW = wLng * scale;
    final drawH = spanLat * scale;
    final offX = pad + (availW - drawW) / 2;
    final offY = pad + (availH - drawH) / 2;

    Offset project(LatLng p) {
      final x =
          offX + (p.longitude - minLng) * (cosLat == 0 ? 1 : cosLat) * scale;
      // Enlem yukarı arttığı için y'yi ters çeviriyoruz.
      final y = offY + drawH - (p.latitude - minLat) * scale;
      return Offset(x, y);
    }

    final first = project(route.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < route.length; i++) {
      final o = project(route[i]);
      path.lineTo(o.dx, o.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final end = project(route.last);
    canvas.drawCircle(first, 4.5, Paint()..color = color);
    canvas.drawCircle(end, 4.5, Paint()..color = color.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.route != route || oldDelegate.color != color;
}
