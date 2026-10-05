import 'active_trip_model.dart';
import 'upcoming_trip_model.dart';
import 'trip_history_model.dart';

class ChildTripsModel {
  final int childId;
  final String childName;
  final String? childPhoto;
  final ActiveTripModel? currentTrip;
  final List<UpcomingTripModel> upcomingTrips;
  final List<TripHistoryModel> history;
  final int totalTripsThisMonth;
  final double attendancePercentage;

  const ChildTripsModel({
    required this.childId,
    required this.childName,
    this.childPhoto,
    this.currentTrip,
    required this.upcomingTrips,
    required this.history,
    this.totalTripsThisMonth = 0,
    this.attendancePercentage = 100.0,
  });

  factory ChildTripsModel.fromJson(Map<String, dynamic> json) {
    ActiveTripModel? active;
    if (json['current_trip'] is Map<String, dynamic>) {
      active = ActiveTripModel.fromJson(json['current_trip'] as Map<String, dynamic>);
    }

    List<UpcomingTripModel> upcoming = [];
    if (json['upcoming_trips'] is List) {
      upcoming = (json['upcoming_trips'] as List)
          .map((e) => UpcomingTripModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<TripHistoryModel> historyList = [];
    if (json['history'] is List) {
      historyList = (json['history'] as List)
          .map((e) => TripHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ChildTripsModel(
      childId: json['child_id'] as int? ?? json['id'] as int? ?? 0,
      childName: json['child_name']?.toString() ?? json['name']?.toString() ?? '',
      childPhoto: json['child_photo']?.toString() ?? json['photo']?.toString() ?? json['photo_url']?.toString() ?? json['image']?.toString(),
      currentTrip: active,
      upcomingTrips: upcoming,
      history: historyList,
      totalTripsThisMonth: json['total_trips_this_month'] as int? ?? 24,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 98.5,
    );
  }
}
