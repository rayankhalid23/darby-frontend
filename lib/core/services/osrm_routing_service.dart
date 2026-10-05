import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// كائن نتيجة الخدمة: النقاط الشوارعية، المسافة بالكيلومتر، والوقت التقديري بالدقائق
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  /// true فقط لو النقاط مسار شوارع فعلي من OSRM؛ false = نقاط المحطات
  /// موصولة مباشرة (فشل/بدون إنترنت) ولا يجب رسمها كمسار
  final bool isRoad;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isRoad = false,
  });

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60.0).round();

  String get formattedDistance =>
      distanceKm < 1 ? '${distanceMeters.round()} م' : '${distanceKm.toStringAsFixed(1)} كم';

  String get formattedDuration =>
      durationMinutes < 1 ? 'أقل من دقيقة' : '$durationMinutes دقيقة';
}

/// خدمة توجيه الشوارع باستخدام OSRM (Open Source Routing Machine)
class OsrmRoutingService {
  static final Dio _dio = Dio();
  static final Map<String, RouteResult> _routeCache = {};
  static final Set<String> _pendingRequests = {};

  /// جلب مسار الشوارع الحقيقي لعدة محطات بالترتيب
  static Future<RouteResult> fetchRoute(List<LatLng> waypoints) async {
    final validWaypoints = waypoints
        .where((w) => w.latitude != 0.0 && w.longitude != 0.0)
        .toList();

    if (validWaypoints.length < 2) {
      return RouteResult(
        points: validWaypoints,
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }

    final key = validWaypoints
        .map((w) =>
            '${w.latitude.toStringAsFixed(4)},${w.longitude.toStringAsFixed(4)}')
        .join(';');

    if (_routeCache.containsKey(key)) {
      return _routeCache[key]!;
    }

    if (_pendingRequests.contains(key)) {
      return RouteResult(
        points: validWaypoints,
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }

    _pendingRequests.add(key);

    try {
      final coordsParam = validWaypoints
          .map((w) => '${w.longitude},${w.latitude}')
          .join(';');
      final url =
          'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson';

      final response =
          await _dio.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        if (data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distance =
              (route['distance'] as num?)?.toDouble() ?? 0.0;
          final double duration =
              (route['duration'] as num?)?.toDouble() ?? 0.0;

          final geometry = route['geometry'];
          if (geometry is Map && geometry['coordinates'] is List) {
            final List coords = geometry['coordinates'] as List;
            final path = coords.map<LatLng>((c) {
              final pair = c as List;
              return LatLng(
                  (pair[1] as num).toDouble(), (pair[0] as num).toDouble());
            }).toList();

            if (path.isNotEmpty) {
              final result = RouteResult(
                points: path,
                distanceMeters: distance,
                durationSeconds: duration,
                isRoad: true,
              );
              _routeCache[key] = result;
              return result;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [OSRM ROUTE FALLBACK] Failed to fetch road route: $e');
    } finally {
      _pendingRequests.remove(key);
    }

    // Fallback if offline/failed: connect points directly — بدون تخزين بالكاش
    // حتى المحاولة الجاية تجيب مسار الشوارع بدل ما يثبت الخط المستقيم
    return RouteResult(
      points: validWaypoints,
      distanceMeters: 0,
      durationSeconds: 0,
    );
  }
}
