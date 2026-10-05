import 'package:equatable/equatable.dart';

/// تنبيه اقتراب/وصول يُرجعه الـ Backend ضمن استجابة POST /driver/trips/{id}/location
/// داخل proximity.alerts
class ProximityAlertModel extends Equatable {
  static const String approachingHome = 'approaching_home';
  static const String arrivedHome = 'arrived_home';
  static const String arrivedSchool = 'arrived_school';

  final String type;
  final int? tripChildId;
  final String? childName;
  final String? message;
  final double? distanceMeters;

  const ProximityAlertModel({
    required this.type,
    this.tripChildId,
    this.childName,
    this.message,
    this.distanceMeters,
  });

  bool get isArrival => type == arrivedHome || type == arrivedSchool;

  /// مدة الانتظار عند المحطة (عداد تنازلي) — null للتنبيهات بلا عداد
  Duration? get waitDuration {
    switch (type) {
      case arrivedHome:
        return const Duration(minutes: 10);
      case arrivedSchool:
        return const Duration(minutes: 15);
      default:
        return null;
    }
  }

  /// مفتاح لتمييز التنبيه — الـ Backend قد يكرر نفس التنبيه مع كل نبضة GPS
  String get key => '$type|${tripChildId ?? ''}|${childName ?? ''}';

  factory ProximityAlertModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] ?? json['alert'] ?? json['event'] ?? '';
    final rawDistance = json['distance'] ?? json['distance_m'] ?? json['distance_meters'];
    return ProximityAlertModel(
      type: rawType.toString(),
      tripChildId: int.tryParse('${json['trip_child_id'] ?? ''}'),
      childName: (json['child_name'] ?? json['name'])?.toString(),
      message: json['message']?.toString(),
      distanceMeters: rawDistance is num ? rawDistance.toDouble() : double.tryParse('${rawDistance ?? ''}'),
    );
  }

  /// يستخرج proximity.alerts من استجابة /location سواء كانت بالجذر أو داخل data
  static List<ProximityAlertModel> listFromLocationResponse(Map<String, dynamic> map) {
    dynamic proximity = map['proximity'];
    final data = map['data'];
    if (proximity == null && data is Map) proximity = data['proximity'];
    if (proximity is! Map) return const [];

    final alerts = proximity['alerts'];
    final rawList = alerts is List ? alerts : (alerts is Map ? [alerts] : const []);
    return rawList
        .map<ProximityAlertModel?>((a) {
          if (a is Map) return ProximityAlertModel.fromJson(Map<String, dynamic>.from(a));
          if (a is String) return ProximityAlertModel(type: a);
          return null;
        })
        .whereType<ProximityAlertModel>()
        .where((a) => a.type.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [type, tripChildId, childName, message, distanceMeters];
}
