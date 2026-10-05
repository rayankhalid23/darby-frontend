import 'package:equatable/equatable.dart';

/// تفاصيل رحلة كاملة (GET /driver/trips/{tripId})
class DriverTripDetailsModel extends Equatable {
  final int tripId;
  final String tripType;
  final String routeName;
  final String status;
  final String? suspensionReason;
  final String tripDate;
  final String? recommendedDeparture;
  final int estimatedDuration;
  final TripVehicleModel vehicle;
  final TripStatisticsModel statistics;
  final List<TripSchoolModel> schools;
  final List<TripDetailsChildModel> children;

  const DriverTripDetailsModel({
    required this.tripId,
    required this.tripType,
    required this.routeName,
    required this.status,
    this.suspensionReason,
    required this.tripDate,
    required this.recommendedDeparture,
    required this.estimatedDuration,
    required this.vehicle,
    required this.statistics,
    required this.schools,
    required this.children,
  });

  factory DriverTripDetailsModel.fromJson(Map<String, dynamic> json) {
    return DriverTripDetailsModel(
      tripId: _parseInt(json['trip_id']),
      tripType: json['trip_type']?.toString() ?? '',
      routeName: json['route_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      suspensionReason: json['suspension_reason']?.toString(),
      tripDate: json['trip_date']?.toString() ?? '',
      recommendedDeparture: json['recommended_departure']?.toString(),
      estimatedDuration: _parseInt(json['estimated_duration']),
      vehicle: json['vehicle'] is Map
          ? TripVehicleModel.fromJson(Map<String, dynamic>.from(json['vehicle'] as Map))
          : TripVehicleModel.empty(),
      statistics: json['statistics'] is Map
          ? TripStatisticsModel.fromJson(Map<String, dynamic>.from(json['statistics'] as Map))
          : TripStatisticsModel.empty(),
      schools: json['schools'] is List
          ? (json['schools'] as List)
              .whereType<Map>()
              .map((e) => TripSchoolModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      children: json['children'] is List
          ? (json['children'] as List)
              .whereType<Map>()
              .map((e) => TripDetailsChildModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isSuspended => status == 'suspended_breakdown';

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic val) {
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  @override
  List<Object?> get props => [
        tripId,
        tripType,
        routeName,
        status,
        suspensionReason,
        tripDate,
        recommendedDeparture,
        estimatedDuration,
        vehicle,
        statistics,
        schools,
        children,
      ];
}

class TripVehicleModel extends Equatable {
  final String plate;
  final int capacity;

  const TripVehicleModel({required this.plate, required this.capacity});

  factory TripVehicleModel.fromJson(Map<String, dynamic> json) {
    return TripVehicleModel(
      plate: json['plate']?.toString() ?? '',
      capacity: DriverTripDetailsModel._parseInt(json['capacity']),
    );
  }

  factory TripVehicleModel.empty() => const TripVehicleModel(plate: '', capacity: 0);

  @override
  List<Object?> get props => [plate, capacity];
}

class TripStatisticsModel extends Equatable {
  final int children;
  final int schools;

  const TripStatisticsModel({required this.children, required this.schools});

  factory TripStatisticsModel.fromJson(Map<String, dynamic> json) {
    return TripStatisticsModel(
      children: DriverTripDetailsModel._parseInt(json['children']),
      schools: DriverTripDetailsModel._parseInt(json['schools']),
    );
  }

  factory TripStatisticsModel.empty() => const TripStatisticsModel(children: 0, schools: 0);

  @override
  List<Object?> get props => [children, schools];
}

class TripSchoolModel extends Equatable {
  final int schoolId;
  final String name;
  final int childrenCount;

  const TripSchoolModel({
    required this.schoolId,
    required this.name,
    required this.childrenCount,
  });

  factory TripSchoolModel.fromJson(Map<String, dynamic> json) {
    return TripSchoolModel(
      schoolId: DriverTripDetailsModel._parseInt(json['school_id']),
      name: json['name']?.toString() ?? '',
      childrenCount: DriverTripDetailsModel._parseInt(json['children_count']),
    );
  }

  @override
  List<Object?> get props => [schoolId, name, childrenCount];
}

class ChildHomeLocationModel extends Equatable {
  final String? title;
  final String? address;
  final double? lat;
  final double? lng;

  const ChildHomeLocationModel({
    this.title,
    this.address,
    this.lat,
    this.lng,
  });

  factory ChildHomeLocationModel.fromJson(Map<String, dynamic> json) {
    return ChildHomeLocationModel(
      title: json['title']?.toString(),
      address: json['address']?.toString(),
      lat: DriverTripDetailsModel._parseDouble(json['lat']),
      lng: DriverTripDetailsModel._parseDouble(json['lng']),
    );
  }

  @override
  List<Object?> get props => [title, address, lat, lng];
}

class ChildSchoolLocationModel extends Equatable {
  final int? id;
  final String? name;
  final String? address;
  final double? lat;
  final double? lng;

  const ChildSchoolLocationModel({
    this.id,
    this.name,
    this.address,
    this.lat,
    this.lng,
  });

  factory ChildSchoolLocationModel.fromJson(Map<String, dynamic> json) {
    return ChildSchoolLocationModel(
      id: json['id'] == null ? null : DriverTripDetailsModel._parseInt(json['id']),
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      lat: DriverTripDetailsModel._parseDouble(json['lat']),
      lng: DriverTripDetailsModel._parseDouble(json['lng']),
    );
  }

  @override
  List<Object?> get props => [id, name, address, lat, lng];
}

/// حالة طفل ضمن تفاصيل الرحلة
class TripDetailsChildModel extends Equatable {
  final int tripChildId;
  final int childId;
  final String name;
  final String? photo;
  final String school;
  final String? schoolName;
  final String pickupAddress;
  final String dropoffAddress;
  final String status;
  final String pickupStatus;
  final String dropoffStatus;
  final String? eta;
  final int sequenceOrder;
  final ChildHomeLocationModel? homeLocation;
  final ChildSchoolLocationModel? schoolLocation;

  const TripDetailsChildModel({
    required this.tripChildId,
    required this.childId,
    required this.name,
    this.photo,
    required this.school,
    this.schoolName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    required this.pickupStatus,
    required this.dropoffStatus,
    required this.eta,
    required this.sequenceOrder,
    this.homeLocation,
    this.schoolLocation,
  });

  factory TripDetailsChildModel.fromJson(Map<String, dynamic> json) {
    return TripDetailsChildModel(
      tripChildId: DriverTripDetailsModel._parseInt(json['trip_child_id']),
      childId: DriverTripDetailsModel._parseInt(json['child_id']),
      name: json['name']?.toString() ?? '',
      photo: json['photo']?.toString() ?? json['photo_url']?.toString() ?? json['image']?.toString(),
      school: json['school']?.toString() ?? json['school_name']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? json['school']?.toString(),
      pickupAddress: json['pickup_address']?.toString() ?? json['home_location']?['address']?.toString() ?? '',
      dropoffAddress: json['dropoff_address']?.toString() ?? json['school_location']?['address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      pickupStatus: json['pickup_status']?.toString() ?? 'pending',
      dropoffStatus: json['dropoff_status']?.toString() ?? 'pending',
      eta: json['eta']?.toString(),
      sequenceOrder: DriverTripDetailsModel._parseInt(json['sequence_order']),
      homeLocation: json['home_location'] is Map
          ? ChildHomeLocationModel.fromJson(Map<String, dynamic>.from(json['home_location'] as Map))
          : null,
      schoolLocation: json['school_location'] is Map
          ? ChildSchoolLocationModel.fromJson(Map<String, dynamic>.from(json['school_location'] as Map))
          : null,
    );
  }

  @override
  List<Object?> get props => [
        tripChildId,
        childId,
        name,
        photo,
        school,
        schoolName,
        pickupAddress,
        dropoffAddress,
        status,
        pickupStatus,
        dropoffStatus,
        eta,
        sequenceOrder,
        homeLocation,
        schoolLocation,
      ];
}
