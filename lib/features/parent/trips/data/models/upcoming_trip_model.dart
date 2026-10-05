import 'active_trip_model.dart';
import 'package:kids_transport/core/utils/app_date_formatter.dart';

class UpcomingTripDriver {
  final String name;

  const UpcomingTripDriver({required this.name});

  factory UpcomingTripDriver.fromJson(Map<String, dynamic> json) {
    return UpcomingTripDriver(
      name: json['name']?.toString() ?? '',
    );
  }
}

class UpcomingTripDestination {
  final String type;
  final String name;

  const UpcomingTripDestination({
    required this.type,
    required this.name,
  });

  factory UpcomingTripDestination.fromJson(Map<String, dynamic> json) {
    return UpcomingTripDestination(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class UpcomingTripChild {
  final int childId;
  final String childName;
  final String schoolName;
  final String? childPhoto;
  final String? costPerChild;
  final ChildAddressModel? homeLocation;
  final ChildSchoolModel? schoolLocation;

  const UpcomingTripChild({
    required this.childId,
    required this.childName,
    required this.schoolName,
    this.childPhoto,
    this.costPerChild,
    this.homeLocation,
    this.schoolLocation,
  });

  factory UpcomingTripChild.fromJson(Map<String, dynamic> json) {
    ChildAddressModel? home;
    if (json['home_location'] is Map<String, dynamic>) {
      home = ChildAddressModel.fromJson(json['home_location'] as Map<String, dynamic>);
    } else if (json['home_address'] is Map<String, dynamic>) {
      home = ChildAddressModel.fromJson(json['home_address'] as Map<String, dynamic>);
    }

    ChildSchoolModel? school;
    if (json['school_location'] is Map<String, dynamic>) {
      school = ChildSchoolModel.fromJson(json['school_location'] as Map<String, dynamic>);
    } else if (json['school'] is Map<String, dynamic>) {
      school = ChildSchoolModel.fromJson(json['school'] as Map<String, dynamic>);
    }

    return UpcomingTripChild(
      childId: _parseInt(json['child_id']),
      childName: json['child_name']?.toString() ?? '',
      schoolName: json['school_name']?.toString() ?? school?.name ?? '',
      childPhoto: json['child_photo']?.toString() ?? json['photo']?.toString() ?? json['photo_url']?.toString() ?? json['image']?.toString(),
      costPerChild: json['cost_per_child']?.toString(),
      homeLocation: home,
      schoolLocation: school,
    );
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val != null) return int.tryParse(val.toString()) ?? 0;
    return 0;
  }
}

class UpcomingTripPricing {
  final String totalTripCost;
  final String? costPerChild;
  final String currency;

  const UpcomingTripPricing({
    required this.totalTripCost,
    this.costPerChild,
    required this.currency,
  });

  factory UpcomingTripPricing.fromJson(Map<String, dynamic> json) {
    return UpcomingTripPricing(
      totalTripCost: json['total_trip_cost']?.toString() ?? json['total_cost']?.toString() ?? '0.00',
      costPerChild: json['cost_per_child']?.toString(),
      currency: json['currency']?.toString() ?? 'LYD',
    );
  }
}

class UpcomingTripModel {
  final int tripId;
  final String tripType;
  final String title;
  final String scheduledFor;
  final UpcomingTripDriver driver;
  final UpcomingTripDestination destination;
  final List<UpcomingTripChild> children;
  final int totalChildren;
  final UpcomingTripPricing pricing;

  const UpcomingTripModel({
    required this.tripId,
    required this.tripType,
    required this.title,
    required this.scheduledFor,
    required this.driver,
    required this.destination,
    required this.children,
    required this.totalChildren,
    required this.pricing,
  });

  // UI Backward compatibility getters
  String get direction =>
      (tripType.toLowerCase() == 'afternoon' || tripType.toLowerCase() == 'evening')
          ? 'to_home'
          : 'to_school';
  String get driverName => driver.name;
  String get schoolName => destination.name.isNotEmpty ? destination.name : (children.isNotEmpty ? children.first.schoolName : '');
  String get childName => children.isNotEmpty ? children.first.childName : '';
  String get scheduledDate => AppDateFormatter.formatDate(scheduledFor);
  String get scheduledTime => AppDateFormatter.formatTime(scheduledFor);
  String get scheduledDateTime => AppDateFormatter.formatDateTime(scheduledFor);
  VehicleInfoModel get vehicle => const VehicleInfoModel(info: 'حافلة مدرسية');

  factory UpcomingTripModel.fromJson(Map<String, dynamic> json) {
    return UpcomingTripModel(
      tripId: _parseInt(json['trip_id'] ?? json['id']),
      tripType: json['trip_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      scheduledFor: json['scheduled_for']?.toString() ?? json['scheduled_at']?.toString() ?? '',
      driver: UpcomingTripDriver.fromJson(
        (json['driver'] is Map) ? Map<String, dynamic>.from(json['driver'] as Map) : {},
      ),
      destination: UpcomingTripDestination.fromJson(
        (json['destination'] is Map) ? Map<String, dynamic>.from(json['destination'] as Map) : {},
      ),
      children: (json['children'] is List)
          ? (json['children'] as List)
              .map((e) => UpcomingTripChild.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      totalChildren: _parseInt(
        json['total_children'] ??
            (json['children'] is List ? (json['children'] as List).length : 0),
      ),
      pricing: UpcomingTripPricing.fromJson(
        (json['pricing'] is Map) ? Map<String, dynamic>.from(json['pricing'] as Map) : {},
      ),
    );
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val != null) return int.tryParse(val.toString()) ?? 0;
    return 0;
  }
}
