import 'package:flutter/animation.dart';
import 'package:latlong2/latlong.dart';

/// يحرّك نقطة على الخريطة (أيقونة الحافلة) بسلاسة بين موقعين بدل ما تقفز.
///
/// مدة الحركة = الوقت بين آخر تحديثين للموقع (محصورة بين [minDuration] و[maxDuration])،
/// فالحافلة تقعد ماشية بشكل متواصل لين يوصل الموقع الجاي.
/// المقابل: الحافلة تبان متأخرة على موقعها الحقيقي بحد أقصى تحديث واحد.
class SmoothMarkerMotion {
  SmoothMarkerMotion({
    required TickerProvider vsync,
    this.minDuration = const Duration(milliseconds: 800),
    this.maxDuration = const Duration(seconds: 12),
    this.snapDistanceMeters = 2000,
  }) : controller = AnimationController(vsync: vsync);

  /// يُستعمل كـ Listenable لإعادة رسم الأيقونة مع كل فريم
  final AnimationController controller;
  final Duration minDuration;
  final Duration maxDuration;

  /// قفزة أكبر من هذا (تبديل رحلة، أو موقع قديم) ترسم مباشرة بدون حركة
  final double snapDistanceMeters;

  static const Distance _distance = Distance();

  LatLng? _from;
  LatLng? _to;
  DateTime? _lastUpdateAt;

  /// الموقع المعروض حالياً (بين القديم والجديد حسب تقدّم الحركة)
  LatLng? get position {
    final to = _to;
    if (to == null) return null;
    final from = _from;
    if (from == null) return to;
    final t = controller.value;
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  /// مدة الحركة الحالية — تُستعمل لتحريك الكاميرا بنفس السرعة
  Duration get currentDuration => controller.duration ?? Duration.zero;

  /// يرجّع true لو بدأت حركة جديدة نحو [target]
  bool moveTo(LatLng target) {
    if (_to == target) return false;
    final now = DateTime.now();
    final current = position;
    final last = _lastUpdateAt;
    _lastUpdateAt = now;

    // أول موقع، أو قفزة كبيرة: نرسم مباشرة
    if (current == null ||
        last == null ||
        _distance.as(LengthUnit.Meter, current, target) > snapDistanceMeters) {
      _from = null;
      _to = target;
      controller.value = 1.0;
      return false;
    }

    var duration = now.difference(last);
    if (duration < minDuration) duration = minDuration;
    if (duration > maxDuration) duration = maxDuration;

    _from = current;
    _to = target;
    controller.duration = duration;
    controller.forward(from: 0.0);
    return true;
  }

  void dispose() => controller.dispose();
}
