import 'package:kids_transport/features/driver/trips/data/datasources/driver_trips_remote_data_source.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_absence_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_details_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_history_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_live_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_stop_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/proximity_alert_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/trip_action_result_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/vehicle_breakdown_model.dart';

/// مستودع رحلات السائق
class DriverTripsRepository {
  final DriverTripsRemoteDataSource _remoteDataSource;

  DriverTripsRepository(this._remoteDataSource);

  Future<List<DriverTripModel>> getTripsToday({String? date}) =>
      _remoteDataSource.fetchTripsToday(date: date);

  Future<DriverTripDetailsModel> getTripDetails(int tripId) =>
      _remoteDataSource.fetchTripDetails(tripId);

  Future<TripStartResultModel> startTrip(int tripId, {double? latitude, double? longitude}) =>
      _remoteDataSource.startTrip(tripId, latitude: latitude, longitude: longitude);

  Future<DriverTripLiveModel> getTripLive(int tripId) => _remoteDataSource.fetchTripLive(tripId);

  Future<List<ProximityAlertModel>> updateLocation(
    int tripId, {
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
    double? heading,
    String? recordedAt,
  }) =>
      _remoteDataSource.updateLocation(
        tripId,
        latitude: latitude,
        longitude: longitude,
        speed: speed,
        accuracy: accuracy,
        heading: heading,
        recordedAt: recordedAt,
      );

  Future<void> updateGeneralDriverLocation({
    required int tripId,
    required double driverLat,
    required double driverLng,
    double? heading,
    bool? isOnline,
  }) =>
      _remoteDataSource.updateGeneralDriverLocation(
        tripId: tripId,
        driverLat: driverLat,
        driverLng: driverLng,
        heading: heading,
        isOnline: isOnline,
      );

  Future<void> pushLiveTrackingToFirestore(
    int tripId, {
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? status,
    int? driverId,
    String? driverName,
  }) => _remoteDataSource.pushLiveTrackingToFirestore(
        tripId,
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
        status: status,
        driverId: driverId,
        driverName: driverName,
      );

  Future<void> updateFirestoreTripStatus(int tripId, String status) =>
      _remoteDataSource.updateFirestoreTripStatus(tripId, status);

  Future<DriverTripStopsResponseModel> getStops(int tripId) => _remoteDataSource.fetchStops(tripId);

  Future<ChildStatusActionResultModel> pickupChild(
    int tripId,
    int tripChildId, {
    required double latitude,
    required double longitude,
  }) => _remoteDataSource.pickupChild(
        tripId,
        tripChildId,
        latitude: latitude,
        longitude: longitude,
      );

  Future<ChildStatusActionResultModel> dropoffChild(
    int tripId,
    int tripChildId, {
    required double latitude,
    required double longitude,
  }) => _remoteDataSource.dropoffChild(
        tripId,
        tripChildId,
        latitude: latitude,
        longitude: longitude,
      );

  Future<ChildStatusActionResultModel> updateChildStatus(
    int tripId,
    int tripChildId, {
    required String action,
    required double latitude,
    required double longitude,
  }) => _remoteDataSource.updateChildStatus(
        tripId,
        tripChildId,
        action: action,
        latitude: latitude,
        longitude: longitude,
      );

  Future<ChildStatusActionResultModel> skipChild(int tripId, int tripChildId) =>
      _remoteDataSource.skipChild(tripId, tripChildId);

  Future<ChildStatusActionResultModel> verifyQr(
    int tripId,
    int tripChildId, {
    required String qrCodeToken,
    String? stage,
  }) => _remoteDataSource.verifyQr(tripId, tripChildId, qrCodeToken: qrCodeToken, stage: stage);

  Future<TripCompleteSummaryModel> completeTrip(int tripId) => _remoteDataSource.completeTrip(tripId);

  Future<DriverTripHistoryResponseModel> getHistory({String? date}) =>
      _remoteDataSource.fetchHistory(date: date);

  Future<DriverTripHistoryDetailsModel> getHistoryDetails(int tripId) =>
      _remoteDataSource.fetchHistoryDetails(tripId);

  Future<List<UpcomingAbsenceTripModel>> getUpcomingTripsForAbsence() =>
      _remoteDataSource.fetchUpcomingTripsForAbsence();

  Future<DriverRegisterAbsenceResponseModel> registerAbsenceWithTrips(
    DriverRegisterAbsenceRequestModel request,
  ) =>
      _remoteDataSource.registerAbsenceWithTrips(request);

  Future<void> registerAbsence(List<String> dates) => _remoteDataSource.registerAbsence(dates);

  Future<VehicleBreakdownResponseModel> reportBreakdown(
    int tripId,
    VehicleBreakdownRequestModel request,
  ) =>
      _remoteDataSource.reportBreakdown(tripId, request);

  Future<TripStatusChangeResultModel> resumeTrip(int tripId) =>
      _remoteDataSource.resumeTrip(tripId);
}
