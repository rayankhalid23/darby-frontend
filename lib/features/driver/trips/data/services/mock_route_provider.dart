import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// نقطة واحدة من ملف مسار المحاكاة
class MockRoutePoint {
  final double latitude;
  final double longitude;

  /// السرعة بالملف بوحدة كم/ساعة
  final double speedKmh;
  final double heading;
  final bool isStop;
  final String currentLeg;
  final String? stopName;

  const MockRoutePoint({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.heading,
    required this.isStop,
    required this.currentLeg,
    this.stopName,
  });

  factory MockRoutePoint.fromJson(Map<String, dynamic> json) {
    final stopInfo = json['stop_info'];
    return MockRoutePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: (json['speed'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      isStop: json['is_stop'] == true,
      currentLeg: json['current_leg']?.toString() ?? '',
      stopName: stopInfo is Map ? stopInfo['stop_name']?.toString() : null,
    );
  }

  Position toPosition() => Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: heading,
        headingAccuracy: 0,
        // Geolocator يعطي السرعة بـ م/ث، فنحوّل من كم/ساعة لنفس الوحدة
        speed: speedKmh / 3.6,
        speedAccuracy: 0,
        isMocked: true,
      );
}

/// حالة المحاكاة لعرضها في لوحة الاختبار
class MockRouteStatus {
  final int step;
  final int total;
  final bool isRunning;
  final bool isWaitingAtStop;
  final bool isFinished;
  final String currentLeg;
  final String? stopName;

  const MockRouteStatus({
    this.step = 0,
    this.total = 0,
    this.isRunning = false,
    this.isWaitingAtStop = false,
    this.isFinished = false,
    this.currentLeg = '',
    this.stopName,
  });
}

/// يقرأ مسار رحلة وهمي من ملف JSON ويبث نقطة كل [tickInterval] كأنه GPS.
/// عند أي نقطة is_stop يتوقف لين يُستدعى [continueFromStop].
/// للاختبار فقط — لا يُستخدم إلا عبر DriverLocationSource في وضع التطوير.
class MockRouteProvider {
  static const String assetPath = 'assets/mock_routes/morning_trip_5children_route.json';

  final Duration tickInterval;
  final ValueNotifier<MockRouteStatus> status = ValueNotifier(const MockRouteStatus());
  final StreamController<Position> _controller = StreamController<Position>.broadcast();

  List<MockRoutePoint> _points = const [];
  int _index = 0;
  bool _waitingAtStop = false;
  Timer? _timer;

  MockRouteProvider({this.tickInterval = const Duration(seconds: 2)});

  Stream<Position> get positions => _controller.stream;

  bool get isLoaded => _points.isNotEmpty;

  Position? get currentPosition => isLoaded ? _points[_index].toPosition() : null;

  Future<void> load() async {
    if (isLoaded) return;
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _points = (json['points'] as List)
        .map((p) => MockRoutePoint.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
    _updateStatus();
  }

  void start() {
    if (!isLoaded || _timer != null || _waitingAtStop || _isAtEnd) return;
    _timer = Timer.periodic(tickInterval, (_) => _tick());
    _updateStatus();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _updateStatus();
  }

  void continueFromStop() {
    if (!_waitingAtStop) return;
    _waitingAtStop = false;
    start();
    _updateStatus();
  }

  void reset() {
    pause();
    _index = 0;
    _waitingAtStop = false;
    _emitCurrent();
    _updateStatus();
  }

  bool get _isAtEnd => isLoaded && _index >= _points.length - 1;

  void _tick() {
    if (_isAtEnd) {
      pause();
      return;
    }
    _index++;
    _emitCurrent();
    // آخر نقطة = نهاية المسار، ما فيش بعدها شي نكمّل له
    if (_isAtEnd) {
      pause();
      return;
    }
    if (_points[_index].isStop) {
      _waitingAtStop = true;
      pause();
      return;
    }
    _updateStatus();
  }

  void _emitCurrent() {
    final position = currentPosition;
    if (position != null && !_controller.isClosed) _controller.add(position);
  }

  void _updateStatus() {
    if (!isLoaded) {
      status.value = const MockRouteStatus();
      return;
    }
    final point = _points[_index];
    status.value = MockRouteStatus(
      step: _index + 1,
      total: _points.length,
      isRunning: _timer != null,
      isWaitingAtStop: _waitingAtStop,
      isFinished: _isAtEnd,
      currentLeg: point.currentLeg,
      stopName: point.stopName,
    );
  }
}
