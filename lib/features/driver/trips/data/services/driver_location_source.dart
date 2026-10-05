import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kids_transport/features/driver/trips/data/services/mock_route_provider.dart';

/// المصدر الوحيد لموقع السائق بالرحلة الحية.
///
/// الوضع الافتراضي: GPS الحقيقي عبر Geolocator بنفس الإعدادات السابقة تماماً.
/// وضع المحاكاة: يقرأ من [MockRouteProvider] — لا يمكن تفعيله إلا في نسخة
/// التطوير (kDebugMode)، ونسخة الإصدار دائماً على GPS الحقيقي.
class DriverLocationSource {
  DriverLocationSource._();

  static final DriverLocationSource instance = DriverLocationSource._();

  static const LocationSettings _settings = LocationSettings(accuracy: LocationAccuracy.high);
  static const LocationSettings _streamSettings =
      LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

  final ValueNotifier<bool> mockEnabled = ValueNotifier(false);
  final MockRouteProvider mockRoute = MockRouteProvider();

  bool get isMock => kDebugMode && mockEnabled.value;

  /// يفعّل/يلغي المحاكاة. الإلغاء يرجّع المسار لأوله.
  Future<void> setMockEnabled(bool enabled) async {
    if (!kDebugMode) return;
    if (enabled) {
      await mockRoute.load();
      mockRoute.reset();
      mockEnabled.value = true;
      mockRoute.start();
    } else {
      mockRoute.reset();
      mockEnabled.value = false;
    }
  }

  /// يرجّع true لو صلاحية الموقع متاحة (دائماً true في المحاكاة)
  Future<bool> ensurePermission() async {
    if (isMock) return true;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied && permission != LocationPermission.deniedForever;
  }

  Future<Position> getCurrentPosition() async {
    if (isMock) {
      final position = mockRoute.currentPosition;
      if (position == null) throw StateError('مسار المحاكاة غير محمّل');
      return position;
    }
    return Geolocator.getCurrentPosition(locationSettings: _settings);
  }

  Stream<Position> positionStream() {
    if (isMock) return mockRoute.positions;
    return Geolocator.getPositionStream(locationSettings: _streamSettings);
  }
}
