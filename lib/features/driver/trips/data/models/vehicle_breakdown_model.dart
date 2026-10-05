import 'package:equatable/equatable.dart';

/// كائن طلب طوارئ تعطل المركبة (POST /driver/trips/{tripId}/report-breakdown)
class VehicleBreakdownRequestModel extends Equatable {
  /// null لو تعذّر تحديد الموقع — الباك يستعمل آخر موقع معروف عنده
  /// بدل ما نبعتوا (0, 0) كموقع حقيقي
  final double? latitude;
  final double? longitude;
  final String reason;
  final double? accuracy;
  final double? speed;
  final String? address;

  const VehicleBreakdownRequestModel({
    required this.latitude,
    required this.longitude,
    required this.reason,
    this.accuracy,
    this.speed,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'reason': reason,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (address != null && address!.isNotEmpty) 'address': address,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude, reason, accuracy, speed, address];
}

/// موقع العطل المرجع في استجابة الباك إند
class BreakdownLocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final double? lat;
  final double? lng;
  final String? mapsUrl;

  const BreakdownLocationModel({
    required this.latitude,
    required this.longitude,
    this.lat,
    this.lng,
    this.mapsUrl,
  });

  factory BreakdownLocationModel.fromJson(Map<String, dynamic> json) {
    return BreakdownLocationModel(
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng']),
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      mapsUrl: json['maps_url']?.toString(),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [latitude, longitude, lat, lng, mapsUrl];
}

/// كائن استجابة طوارئ تعطل المركبة من الباك إند
class VehicleBreakdownResponseModel extends Equatable {
  final String status; // broadcasted | no_substitutes_available | success
  final String message;
  final int tripId;
  final int? dispatchId;
  final BreakdownLocationModel? breakdownLocation;
  final int strandedChildrenCount;
  final int candidatesCount;
  final List<int> candidateDriverIds;
  final double? tripFareAmount;
  final dynamic dispatch;

  const VehicleBreakdownResponseModel({
    required this.status,
    required this.message,
    required this.tripId,
    this.dispatchId,
    this.breakdownLocation,
    this.strandedChildrenCount = 0,
    this.candidatesCount = 0,
    this.candidateDriverIds = const [],
    this.tripFareAmount,
    this.dispatch,
  });

  factory VehicleBreakdownResponseModel.fromJson(Map<String, dynamic> json) {
    List<int> parseCandidateIds(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => _parseInt(e)).where((id) => id > 0).toList();
      }
      return [];
    }

    return VehicleBreakdownResponseModel(
      status: json['status']?.toString() ?? 'success',
      message: json['message']?.toString() ?? 'تم تسجيل بلاغ الطوارئ',
      tripId: _parseInt(json['trip_id']),
      dispatchId: json['dispatch_id'] != null ? _parseInt(json['dispatch_id']) : null,
      breakdownLocation: json['breakdown_location'] is Map
          ? BreakdownLocationModel.fromJson(Map<String, dynamic>.from(json['breakdown_location'] as Map))
          : null,
      strandedChildrenCount: _parseInt(json['stranded_children_count']),
      candidatesCount: _parseInt(json['candidates_count']),
      candidateDriverIds: parseCandidateIds(json['candidate_driver_ids']),
      tripFareAmount: json['trip_fare_amount'] != null ? _parseDouble(json['trip_fare_amount']) : null,
      dispatch: json['dispatch'],
    );
  }

  bool get isBroadcasted => status == 'broadcasted';
  bool get isNoSubstitutes => status == 'no_substitutes_available';
  bool get isSuccess => status == 'success';

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic val) {
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  List<Object?> get props => [
        status,
        message,
        tripId,
        dispatchId,
        breakdownLocation,
        strandedChildrenCount,
        candidatesCount,
        candidateDriverIds,
        tripFareAmount,
        dispatch,
      ];
}
