class DriverSearchResponseModel {
  final bool status;
  final String? message;
  final SearchContextModel? searchContext;
  final SearchMetaModel? meta;
  final List<DriverSearchModel> drivers;

  DriverSearchResponseModel({
    required this.status,
    this.message,
    this.searchContext,
    this.meta,
    required this.drivers,
  });

  factory DriverSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final searchContextData = json['search_context'] is Map
        ? SearchContextModel.fromJson(
            Map<String, dynamic>.from(json['search_context'] as Map))
        : null;

    final metaData = json['meta'] is Map
        ? SearchMetaModel.fromJson(
            Map<String, dynamic>.from(json['meta'] as Map))
        : null;

    final rawList = json['data'] is List
        ? (json['data'] as List)
        : json['drivers'] is List
            ? (json['drivers'] as List)
            : [];

    final driversList = rawList
        .map((e) => DriverSearchModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final isSuccess = json['status'] == true || json['success'] == true;

    return DriverSearchResponseModel(
      status: isSuccess,
      message: json['message']?.toString(),
      searchContext: searchContextData,
      meta: metaData,
      drivers: driversList,
    );
  }
}

class SearchContextModel {
  final String subscriptionType;
  final String startDate;
  final String endDate;
  final String tripDirection;
  final List<int> childIds;

  SearchContextModel({
    required this.subscriptionType,
    required this.startDate,
    required this.endDate,
    required this.tripDirection,
    required this.childIds,
  });

  factory SearchContextModel.fromJson(Map<String, dynamic> json) {
    final rawChildIds = json['child_ids'];
    final List<int> parsedChildIds = rawChildIds is List
        ? rawChildIds.map((e) => _readInt(e)).toList()
        : [];

    return SearchContextModel(
      subscriptionType: json['subscription_type']?.toString() ?? 'multi_day',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      tripDirection: json['trip_direction']?.toString() ?? 'go',
      childIds: parsedChildIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'subscription_type': subscriptionType,
        'start_date': startDate,
        'end_date': endDate,
        'trip_direction': tripDirection,
        'child_ids': childIds,
      };
}

class SearchMetaModel {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  SearchMetaModel({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory SearchMetaModel.fromJson(Map<String, dynamic> json) {
    return SearchMetaModel(
      currentPage: _readInt(json['current_page']),
      lastPage: _readInt(json['last_page']),
      perPage: _readInt(json['per_page']),
      total: _readInt(json['total']),
    );
  }
}

class DriverSearchModel {
  final DriverModelInfo driver;
  final VehicleModelInfo vehicle;
  final List<WorkingZoneModelInfo> workingZones;
  final PricingModelInfo pricing;
  final List<BreakdownModelInfo> breakdown;
  final int driverId;
  final int userId;
  final int availableSeats;
  final int? aiRank;
  final double? aiScore;
  final List<String> aiRankingReasons;

  DriverSearchModel({
    required this.driver,
    required this.vehicle,
    required this.workingZones,
    required this.pricing,
    required this.breakdown,
    required this.driverId,
    required this.userId,
    required this.availableSeats,
    this.aiRank,
    this.aiScore,
    this.aiRankingReasons = const [],
  });

  // Getters to maintain backward compatibility with existing UI
  String get id => driver.id.toString();
  String get fullName => driver.fullName;
  String? get photoUrl => driver.avatarUrl;
  String get gender => driver.gender;
  double get rating => driver.rating;
  int get reviewsCount => driver.completedTrips;
  double get price => pricing.totalPrice;
  String get vehicleType => '${vehicle.brand} ${vehicle.model}';
  int get totalSeats => vehicle.capacityManual;
  List<String> get serviceZones => workingZones.map((z) => z.name).toList();
  String get preferredTimeSlot => driver.shift;

  String? get phoneNumber => driver.phoneNumber;
  String? get alternativePhone => driver.alternativePhone;
  bool get isLicenseVerified => driver.status == 'active';
  bool get isCriminalRecordVerified => driver.status == 'active';
  bool get hasAc => vehicle.hasAc;
  int get completedTrips => driver.completedTrips;
  String? get plateNumber => vehicle.plateNumber;
  int? get vehicleYear => vehicle.year;
  String? get vehicleColor => vehicle.color;
  String? get status => driver.status;

  double get subtotalPrice =>
      breakdown.isEmpty ? price : breakdown.fold(0.0, (sum, b) => sum + b.subtotal);

  bool get hasSiblingDiscount =>
      breakdown.length > 1 && breakdown.any((b) => b.hasSiblingDiscount);

  factory DriverSearchModel.fromJson(Map<String, dynamic> json) {
    final pricingData = json['pricing'] is Map
        ? Map<String, dynamic>.from(json['pricing'] as Map)
        : <String, dynamic>{};
    final breakdownList = pricingData['breakdown'] is List
        ? (pricingData['breakdown'] as List)
            .map((e) =>
                BreakdownModelInfo.fromJson(e as Map<String, dynamic>))
            .toList()
        : <BreakdownModelInfo>[];

    final rawReasons = json['ai_ranking_reasons'];
    final List<String> parsedReasons = rawReasons is List
        ? rawReasons
            .where((e) => e != null)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final rawRank = json['ai_rank'];
    final int? parsedRank = rawRank != null ? _readInt(rawRank) : null;

    final rawScore = json['ai_score'];
    final double? parsedScore = rawScore != null ? _readDouble(rawScore) : null;

    return DriverSearchModel(
      driver: DriverModelInfo.fromJson(json),
      vehicle: VehicleModelInfo.fromJson(
          json['vehicle'] is Map ? Map<String, dynamic>.from(json['vehicle'] as Map) : {}),
      workingZones: (json['working_zones'] as List<dynamic>?)
              ?.map((e) =>
                  WorkingZoneModelInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pricing: PricingModelInfo.fromJson(pricingData),
      breakdown: breakdownList,
      driverId: _readInt(json['driver_id']) != 0
          ? _readInt(json['driver_id'])
          : _readInt(json['id']),
      userId: _readInt(json['user_id']),
      availableSeats: _readInt(json['available_seats']),
      aiRank: parsedRank,
      aiScore: parsedScore,
      aiRankingReasons: parsedReasons,
    );
  }
}

class DriverModelInfo {
  final int id;
  final String fullName;
  final String? phoneNumber;
  final String? alternativePhone;
  final String? avatarUrl;
  final String gender;
  final String? acceptedGender;
  final String shift;
  final double rating;
  final int completedTrips;
  final String status;

  DriverModelInfo({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.alternativePhone,
    this.avatarUrl,
    required this.gender,
    this.acceptedGender,
    required this.shift,
    required this.rating,
    required this.completedTrips,
    required this.status,
  });

  factory DriverModelInfo.fromJson(Map<String, dynamic> json) {
    final rawShift = json['shift'];
    final shiftStr = rawShift is int
        ? rawShift.toString()
        : rawShift?.toString() ?? '0';

    return DriverModelInfo(
      id: _readInt(json['id']),
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      alternativePhone: json['alternative_phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      gender: json['gender']?.toString() ?? 'MALE',
      acceptedGender: json['accepted_gender']?.toString(),
      shift: shiftStr,
      rating: _readDouble(json['rating']),
      completedTrips: _readInt(json['completed_trips']),
      status: json['status']?.toString() ?? 'inactive',
    );
  }
}

class VehicleModelInfo {
  final String brand;
  final String model;
  final int year;
  final String color;
  final String type;
  final bool hasAc;
  final int capacityManual;
  final String plateNumber;

  VehicleModelInfo({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.type,
    required this.hasAc,
    required this.capacityManual,
    required this.plateNumber,
  });

  int get capacity => capacityManual;

  factory VehicleModelInfo.fromJson(Map<String, dynamic> json) {
    final rawCapacity = json['capacity'] ?? json['capacity_manual'];
    return VehicleModelInfo(
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: _readInt(json['year']),
      color: json['color']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      hasAc: _readBool(json['has_ac']),
      capacityManual: _readInt(rawCapacity),
      plateNumber: json['plate_number']?.toString() ?? '',
    );
  }
}

class WorkingZoneModelInfo {
  final int id;
  final String name;

  WorkingZoneModelInfo({
    required this.id,
    required this.name,
  });

  factory WorkingZoneModelInfo.fromJson(Map<String, dynamic> json) {
    return WorkingZoneModelInfo(
      id: _readInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }
}

class PricingModelInfo {
  final double? tripPrice;
  final String totalPriceFormatted;
  final double totalPrice;
  final double totalPriceRaw;
  final double? platformFee;
  final double? driverNetAmount;
  final int? workingDays;
  final double? distanceKm;
  final bool hasAc;
  final double pricePerKm;
  final int childrenCount;

  PricingModelInfo({
    this.tripPrice,
    this.totalPriceFormatted = '',
    required this.totalPrice,
    required this.totalPriceRaw,
    this.platformFee,
    this.driverNetAmount,
    this.workingDays,
    this.distanceKm,
    required this.hasAc,
    required this.pricePerKm,
    required this.childrenCount,
  });

  factory PricingModelInfo.fromJson(Map<String, dynamic> json) {
    final rawTotalPrice = json['total_price'];
    final formattedPrice = rawTotalPrice is String
        ? rawTotalPrice
        : rawTotalPrice != null
            ? '${_parsePriceString(rawTotalPrice).toStringAsFixed(2)} د.ل'
            : '';

    return PricingModelInfo(
      tripPrice:
          json['trip_price'] != null ? _readDouble(json['trip_price']) : null,
      totalPriceFormatted: formattedPrice,
      totalPrice: _parsePriceString(rawTotalPrice),
      totalPriceRaw: _readDouble(json['total_price_raw']),
      platformFee: json['platform_fee'] != null
          ? _readDouble(json['platform_fee'])
          : null,
      driverNetAmount: json['driver_net_amount'] != null
          ? _readDouble(json['driver_net_amount'])
          : null,
      workingDays:
          json['working_days'] != null ? _readInt(json['working_days']) : null,
      distanceKm:
          json['distance_km'] != null ? _readDouble(json['distance_km']) : null,
      hasAc: _readBool(json['has_ac']),
      pricePerKm: _readDouble(json['price_per_km']),
      childrenCount: _readInt(json['children_count']),
    );
  }
}

class BreakdownModelInfo {
  final int childId;
  final String childName;
  final String gender;
  final String schoolStage;
  final String schoolName;
  final String schoolAddress;
  final double schoolLat;
  final double schoolLng;
  final String homeLabel;
  final double homeLat;
  final double homeLng;
  final String preferredTimeSlot;
  final double distanceKm;
  final int workingDays;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double finalTotal;
  final double platformFee;
  final double driverNet;
  final String subscriptionTypeLabel;
  final String childPriceFormatted;
  final double childPriceRaw;
  final String? error;

  BreakdownModelInfo({
    required this.childId,
    required this.childName,
    this.gender = 'male',
    this.schoolStage = '',
    required this.schoolName,
    this.schoolAddress = '',
    this.schoolLat = 0.0,
    this.schoolLng = 0.0,
    this.homeLabel = '',
    this.homeLat = 0.0,
    this.homeLng = 0.0,
    this.preferredTimeSlot = 'morning',
    required this.distanceKm,
    required this.workingDays,
    required this.subtotal,
    this.discountPercent = 0,
    this.discountAmount = 0,
    required this.finalTotal,
    this.platformFee = 0.0,
    this.driverNet = 0.0,
    this.subscriptionTypeLabel = '',
    this.childPriceFormatted = '',
    required this.childPriceRaw,
    this.error,
  });

  double get childPrice => finalTotal;
  bool get hasSiblingDiscount => discountPercent > 0 && discountAmount > 0;

  factory BreakdownModelInfo.fromJson(Map<String, dynamic> json) {
    final parsedFinalTotal = json.containsKey('final_total')
        ? _parsePriceString(json['final_total'])
        : _parsePriceString(json['child_price']);

    final schoolLoc = json['school_location'] is Map
        ? Map<String, dynamic>.from(json['school_location'] as Map)
        : <String, dynamic>{};
    final homeLoc = json['home_location'] is Map
        ? Map<String, dynamic>.from(json['home_location'] as Map)
        : <String, dynamic>{};

    return BreakdownModelInfo(
      childId: _readInt(json['child_id']),
      childName: json['child_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'male',
      schoolStage: json['school_stage']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? '',
      schoolAddress: json['school_address']?.toString() ?? '',
      schoolLat: _readDouble(schoolLoc['lat']),
      schoolLng: _readDouble(schoolLoc['lng']),
      homeLabel: json['home_label']?.toString() ?? '',
      homeLat: _readDouble(homeLoc['lat']),
      homeLng: _readDouble(homeLoc['lng']),
      preferredTimeSlot: json['preferred_time_slot']?.toString() ?? 'morning',
      distanceKm: _readDouble(json['distance_km']),
      workingDays: _readInt(json['working_days']),
      subtotal: _readDouble(json['subtotal']) > 0
          ? _readDouble(json['subtotal'])
          : parsedFinalTotal,
      discountPercent: _readDouble(json['discount_percent']),
      discountAmount: _readDouble(json['discount_amount']),
      finalTotal: parsedFinalTotal,
      platformFee: _readDouble(json['platform_fee']),
      driverNet: _readDouble(json['driver_net']),
      subscriptionTypeLabel: json['subscription_type_label']?.toString() ?? '',
      childPriceFormatted: json['child_price']?.toString() ?? '',
      childPriceRaw: _readDouble(json['child_price_raw']) > 0
          ? _readDouble(json['child_price_raw'])
          : parsedFinalTotal,
      error: json['error']?.toString(),
    );
  }
}

double _parsePriceString(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(value.trim());
    if (match != null) return double.tryParse(match.group(0)!) ?? 0.0;
    return 0.0;
  }
  return 0.0;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}

