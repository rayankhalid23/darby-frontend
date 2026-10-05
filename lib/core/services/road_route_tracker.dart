import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:kids_transport/core/services/osrm_routing_service.dart';

/// يحافظ على مسار شوارع ثابت من موقع السائق لوجهاته أثناء التتبع الحي.
///
/// بدل طلب مسار جديد مع كل تحديث لموقع السائق (وعرض خط مستقيم لين يوصل
/// الرد)، نجيب مسار الشوارع مرة وحدة، ومع كل تحديث نقصّ الجزء اللي فاته
/// السائق. نعيد الطلب فقط لو تغيّرت الوجهات أو بعد السائق عن المسار.
/// الخط ما يرجعش مستقيم أبداً: لو مازال ما فيش مسار شوارع ما يترسمش شي.
class RoadRouteTracker {
  RoadRouteTracker({this.onUpdated});

  /// يُستدعى لما يوصل مسار شوارع جديد (لإعادة رسم الخريطة)
  final void Function()? onUpdated;

  /// أبعد مسافة عن المسار قبل ما نعتبر السائق خرج عنه ونعيد الطلب
  static const double _offRouteMeters = 50;

  /// مدى البحث قدّام آخر نقطة وصلها السائق (يمنع القفز لجزء لاحق من المسار
  /// يمر قريب من نفس المكان)
  static const double _lookAheadMeters = 1500;

  /// أقل مدة بين محاولتين لنفس الوجهات (لو OSRM فشل أو السائق خارج المسار)
  static const Duration _retryDelay = Duration(seconds: 10);

  static const Distance _distance = Distance();

  RouteResult? _route;
  double _routeLength = 0;
  int _progressIndex = 0;
  String _targetsKey = '';
  bool _stale = true;
  bool _fetching = false;
  DateTime? _lastAttempt;
  RouteResult? _remaining;

  /// الجزء المتبقي من المسار مع المسافة والوقت المتبقيين (null لو مازال ما فيش)
  RouteResult? get remaining => _remaining;

  /// النقاط اللي تنرسم من موقع السائق الحالي للوجهات بالترتيب
  List<LatLng> update(LatLng driver, List<LatLng> targets) {
    final key = targets
        .map((t) => '${t.latitude.toStringAsFixed(5)},${t.longitude.toStringAsFixed(5)}')
        .join(';');
    if (key != _targetsKey) {
      // نخلي المسار القديم معروض لين يوصل الجديد بدل ما يختفي الخط
      _targetsKey = key;
      _stale = true;
      _lastAttempt = null;
    }

    if (_route == null || _stale) _fetch(driver, targets, key);

    final route = _route;
    if (route == null) return const [];

    final match = _match(route.points, driver);
    if (match == null) {
      _fetch(driver, targets, key);
      return _remaining?.points ?? const [];
    }

    _progressIndex = match.segmentIndex;
    final points = <LatLng>[match.point, ...route.points.sublist(match.segmentIndex + 1)];
    final remainingMeters = _length(points);
    final ratio = _routeLength > 0 ? (remainingMeters / _routeLength).clamp(0.0, 1.0) : 0.0;
    _remaining = RouteResult(
      points: points,
      distanceMeters: route.distanceMeters * ratio,
      durationSeconds: route.durationSeconds * ratio,
      isRoad: true,
    );
    return points;
  }

  void _fetch(LatLng driver, List<LatLng> targets, String key) {
    if (_fetching || targets.isEmpty) return;
    final now = DateTime.now();
    if (_lastAttempt != null && now.difference(_lastAttempt!) < _retryDelay) return;
    _fetching = true;
    _lastAttempt = now;

    OsrmRoutingService.fetchRoute([driver, ...targets]).then((result) {
      _fetching = false;
      // خط مستقيم (فشل/بدون إنترنت) ما ينرسمش — نعيد المحاولة بالتحديث الجاي
      if (key != _targetsKey || !result.isRoad || result.points.length < 2) return;
      _route = result;
      _routeLength = _length(result.points);
      _progressIndex = 0;
      _stale = false;
      onUpdated?.call();
    });
  }

  /// أقرب نقطة على المسار لموقع السائق، بداية من آخر جزء وصله
  _RouteMatch? _match(List<LatLng> points, LatLng driver) {
    if (_progressIndex >= points.length - 1) _progressIndex = 0;

    _RouteMatch? best;
    double ahead = 0;
    for (var i = _progressIndex; i < points.length - 1; i++) {
      final candidate = _project(driver, points[i], points[i + 1], i);
      if (best == null || candidate.distanceMeters < best.distanceMeters) best = candidate;
      ahead += _distance.distance(points[i], points[i + 1]);
      if (ahead > _lookAheadMeters) break;
    }
    if (best == null || best.distanceMeters > _offRouteMeters) return null;
    return best;
  }

  /// إسقاط موقع السائق على جزء المسار [a]→[b] (تقريب مستوٍ محلي بالأمتار)
  static _RouteMatch _project(LatLng p, LatLng a, LatLng b, int index) {
    final cosLat = math.cos(p.latitude * math.pi / 180);
    const metersPerDegLat = 110540.0;
    final metersPerDegLng = 111320.0 * cosLat;

    final ax = (a.longitude - p.longitude) * metersPerDegLng;
    final ay = (a.latitude - p.latitude) * metersPerDegLat;
    final bx = (b.longitude - p.longitude) * metersPerDegLng;
    final by = (b.latitude - p.latitude) * metersPerDegLat;

    final dx = bx - ax;
    final dy = by - ay;
    final lengthSq = dx * dx + dy * dy;
    final t = lengthSq == 0 ? 0.0 : (-(ax * dx + ay * dy) / lengthSq).clamp(0.0, 1.0);

    final px = ax + t * dx;
    final py = ay + t * dy;
    final point = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
    return _RouteMatch(index, point, math.sqrt(px * px + py * py));
  }

  static double _length(List<LatLng> points) {
    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _distance.distance(points[i], points[i + 1]);
    }
    return total;
  }
}

class _RouteMatch {
  final int segmentIndex;
  final LatLng point;
  final double distanceMeters;

  const _RouteMatch(this.segmentIndex, this.point, this.distanceMeters);
}
