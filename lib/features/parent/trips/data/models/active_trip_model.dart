class DriverInfo {
  final int id;
  final String name;
  final String phone;
  final String? photo;
  final double lat;
  final double lng;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.photo,
    this.lat = 0.0,
    this.lng = 0.0,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? json['driver_name']?.toString() ?? '',
      phone:
          json['phone']?.toString() ?? json['driver_phone']?.toString() ?? '',
      photo: json['photo']?.toString() ?? json['driver_photo']?.toString(),
      lat: _parseDouble(json['lat'] ?? json['latitude'] ?? json['current_lat'] ?? json['driver_lat']),
      lng: _parseDouble(json['lng'] ?? json['longitude'] ?? json['current_lng'] ?? json['driver_lng']),
    );
  }
}

class VehicleInfoModel {
  final String info;
  final String? plateNumber;
  final int? capacity;

  const VehicleInfoModel({required this.info, this.plateNumber, this.capacity});

  factory VehicleInfoModel.fromJson(dynamic json) {
    if (json is String) {
      return VehicleInfoModel(info: json);
    } else if (json is Map<String, dynamic>) {
      return VehicleInfoModel(
        info: json['info']?.toString() ?? json['model']?.toString() ?? '',
        plateNumber:
            json['plate_number']?.toString() ?? json['plate']?.toString(),
        capacity: (json['capacity'] as num?)?.toInt(),
      );
    }
    return const VehicleInfoModel(info: '');
  }
}

class BusOccupancyModel {
  final int currentOnboardCount;
  final int totalTripChildren;

  const BusOccupancyModel({
    required this.currentOnboardCount,
    required this.totalTripChildren,
  });

  factory BusOccupancyModel.fromJson(Map<String, dynamic> json) {
    return BusOccupancyModel(
      currentOnboardCount:
          (json['current_onboard_count'] as num?)?.toInt() ?? 0,
      totalTripChildren: (json['total_trip_children'] as num?)?.toInt() ?? 0,
    );
  }

  String get displayOccupancy => '$currentOnboardCount / $totalTripChildren';
}

double _parseDouble(dynamic val) {
  if (val is double) return val;
  if (val is num) return val.toDouble();
  if (val != null) return double.tryParse(val.toString()) ?? 0.0;
  return 0.0;
}

class ChildAddressModel {
  final String title;
  final String? street;
  final double lat;
  final double lng;

  const ChildAddressModel({
    required this.title,
    this.street,
    required this.lat,
    required this.lng,
  });

  factory ChildAddressModel.fromJson(Map<String, dynamic> json) {
    return ChildAddressModel(
      title: json['title']?.toString() ?? json['address']?.toString() ?? '',
      street: json['street']?.toString() ?? json['address']?.toString(),
      lat: _parseDouble(json['lat'] ?? json['latitude']),
      lng: _parseDouble(json['lng'] ?? json['longitude']),
    );
  }
}

class ChildSchoolModel {
  final int id;
  final String name;
  final String? branch;
  final String? address;
  final double lat;
  final double lng;

  const ChildSchoolModel({
    required this.id,
    required this.name,
    this.branch,
    this.address,
    required this.lat,
    required this.lng,
  });

  factory ChildSchoolModel.fromJson(Map<String, dynamic> json) {
    return ChildSchoolModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      branch: json['branch']?.toString(),
      address: json['address']?.toString(),
      lat: _parseDouble(json['lat'] ?? json['latitude']),
      lng: _parseDouble(json['lng'] ?? json['longitude']),
    );
  }
}

class TripChildInfo {
  final int childId;
  final String childName;
  final String? childPhoto;
  final String childStatus;
  final String? pickupTime;
  final String? dropoffTime;
  final String? direction;
  final ChildAddressModel? homeAddress;
  final ChildSchoolModel? school;

  const TripChildInfo({
    required this.childId,
    required this.childName,
    this.childPhoto,
    required this.childStatus,
    this.pickupTime,
    this.dropoffTime,
    this.direction,
    this.homeAddress,
    this.school,
  });

  factory TripChildInfo.fromJson(Map<String, dynamic> json) {
    ChildAddressModel? home;
    if (json['home_address'] is Map<String, dynamic>) {
      home = ChildAddressModel.fromJson(
        json['home_address'] as Map<String, dynamic>,
      );
    }

    ChildSchoolModel? schoolObj;
    if (json['school'] is Map<String, dynamic>) {
      schoolObj = ChildSchoolModel.fromJson(
        json['school'] as Map<String, dynamic>,
      );
    } else if (json['school_name'] != null) {
      // رحلة البديل ترجّع المدرسة كنص بدون إحداثيات — الاسم للعرض بس،
      // وموقعها على الخريطة يجي من /track
      schoolObj = ChildSchoolModel(
        id: 0,
        name: json['school_name'].toString(),
        address: json['school_address']?.toString(),
        lat: 0.0,
        lng: 0.0,
      );
    }

    return TripChildInfo(
      childId: json['child_id'] as int? ?? json['id'] as int? ?? 0,
      childName:
          json['child_name']?.toString() ?? json['name']?.toString() ?? '',
      childPhoto: json['child_photo']?.toString() ?? json['photo']?.toString() ?? json['photo_url']?.toString() ?? json['image']?.toString(),
      childStatus:
          json['child_status']?.toString() ?? json['status']?.toString() ?? '',
      pickupTime:
          json['pickup_time']?.toString() ?? json['onboard_time']?.toString(),
      dropoffTime:
          json['dropoff_time']?.toString() ?? json['arrival_time']?.toString(),
      direction: json['direction']?.toString(),
      homeAddress: home,
      school: schoolObj,
    );
  }
}

class DestinationInfo {
  final String name;
  final String type;
  final double lat;
  final double lng;

  const DestinationInfo({
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });

  factory DestinationInfo.fromJson(Map<String, dynamic> json) {
    return DestinationInfo(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      lat: _parseDouble(json['lat'] ?? json['latitude']),
      lng: _parseDouble(json['lng'] ?? json['longitude']),
    );
  }
}

class ActiveTripModel {
  final int tripId;
  final String tripType;
  final String direction; // to_school or to_home
  final String status;
  final String startedAt;
  final DriverInfo driver;
  final VehicleInfoModel vehicle;
  final BusOccupancyModel? busOccupancy;
  final List<TripChildInfo> children;
  final DestinationInfo destination;
  final String? waitingTimer;

  /// رحلة سائق بديل استلم أطفال حافلة معطلة (original_trip_id)
  final bool isSubstitute;
  final int? originalTripId;
  final int? dispatchId;

  const ActiveTripModel({
    required this.tripId,
    required this.tripType,
    required this.direction,
    required this.status,
    required this.startedAt,
    required this.driver,
    required this.vehicle,
    this.busOccupancy,
    required this.children,
    required this.destination,
    this.waitingTimer,
    this.isSubstitute = false,
    this.originalTripId,
    this.dispatchId,
  });

  // Legacy compatibility getters
  String get driverName => driver.name;
  String get driverPhone => driver.phone;
  String get vehicleInfo => vehicle.info;
  int get childId => children.isNotEmpty ? children.first.childId : 0;
  String get childName => children.isNotEmpty ? children.first.childName : '';
  String get childStatus =>
      children.isNotEmpty ? children.first.childStatus : '';

  /// جلب المدارس الفريدة للأطفال في هذه الرحلة
  List<ChildSchoolModel> get uniqueSchools {
    final Map<String, ChildSchoolModel> map = {};
    for (final c in children) {
      // مدرسة بلا إحداثيات ما تنرسمش (وإلا تطلع علامتها في النقطة 0,0)
      if (c.school != null && c.school!.lat != 0.0 && c.school!.lng != 0.0) {
        final key = '${c.school!.id}_${c.school!.lat}_${c.school!.lng}';
        map[key] = c.school!;
      }
    }
    return map.values.toList();
  }

  /// جلب عناوين المنازل الفريدة للأطفال في هذه الرحلة
  List<ChildAddressModel> get uniqueHomeAddresses {
    final Map<String, ChildAddressModel> map = {};
    for (final c in children) {
      if (c.homeAddress != null && c.homeAddress!.lat != 0.0 && c.homeAddress!.lng != 0.0) {
        final key =
            '${c.homeAddress!.title}_${c.homeAddress!.lat}_${c.homeAddress!.lng}';
        map[key] = c.homeAddress!;
      }
    }
    return map.values.toList();
  }

  factory ActiveTripModel.fromJson(Map<String, dynamic> json) {
    DriverInfo driverObj;
    if (json['driver'] is Map<String, dynamic>) {
      driverObj = DriverInfo.fromJson(json['driver'] as Map<String, dynamic>);
    } else {
      driverObj = DriverInfo(
        id: json['driver_id'] as int? ?? 0,
        name: json['driver_name']?.toString() ?? '',
        phone: json['driver_phone']?.toString() ?? '',
        photo: json['driver_photo']?.toString(),
      );
    }

    VehicleInfoModel vehicleObj = VehicleInfoModel.fromJson(
      json['vehicle'] ?? json['vehicle_info'],
    );

    BusOccupancyModel? occupancy;
    if (json['bus_occupancy'] is Map<String, dynamic>) {
      occupancy = BusOccupancyModel.fromJson(
        json['bus_occupancy'] as Map<String, dynamic>,
      );
    }

    List<TripChildInfo> childrenList = [];
    if (json['children'] is List) {
      childrenList = (json['children'] as List)
          .map((e) => TripChildInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['child_id'] != null || json['child_name'] != null) {
      childrenList = [
        TripChildInfo(
          childId: json['child_id'] as int? ?? 0,
          childName: json['child_name']?.toString() ?? '',
          childPhoto: json['child_photo']?.toString(),
          childStatus: json['child_status']?.toString() ?? '',
        ),
      ];
    }

    DestinationInfo destObj;
    if (json['destination'] is Map<String, dynamic>) {
      destObj = DestinationInfo.fromJson(
        json['destination'] as Map<String, dynamic>,
      );
    } else {
      destObj = DestinationInfo(
        name: json['destination_name']?.toString() ?? '',
        type: json['destination_type']?.toString() ?? '',
        lat: _parseDouble(json['dest_lat']),
        lng: _parseDouble(json['dest_lng']),
      );
    }

    return ActiveTripModel(
      tripId: json['trip_id'] as int? ?? json['id'] as int? ?? 0,
      tripType: json['trip_type']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      driver: driverObj,
      vehicle: vehicleObj,
      busOccupancy: occupancy,
      children: childrenList,
      destination: destObj,
      waitingTimer: json['waiting_timer']?.toString(),
      isSubstitute: json['is_substitute'] == true || json['is_substitute'] == 1,
      originalTripId: int.tryParse(json['original_trip_id']?.toString() ?? ''),
      dispatchId: int.tryParse(json['dispatch_id']?.toString() ?? ''),
    );
  }
}
