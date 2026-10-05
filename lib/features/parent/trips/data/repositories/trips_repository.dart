import '../datasources/trips_remote_data_source.dart';
import '../models/active_trip_model.dart';
import '../models/trip_track_model.dart';
import '../models/upcoming_trip_model.dart';
import '../models/trip_history_model.dart';
import '../models/trip_details_model.dart';
import '../models/trip_timeline_model.dart';
import '../models/child_trips_model.dart';

class TripsRepository {
  final TripsRemoteDataSource _remoteDataSource;

  TripsRepository(this._remoteDataSource);

  Future<List<ActiveTripModel>> getActiveTrips() async {
    return await _remoteDataSource.getActiveTrips();
  }

  Future<LiveTrackingModel> getTripTrack(dynamic tripId) async {
    return await _remoteDataSource.getTripTrack(tripId);
  }

  /// Stream live tracking for a single trip via Remote DataSource (Firestore)
  Stream<LiveTrackingModel> trackTripLive(
    int tripId,
    LiveTrackingModel baseModel,
  ) {
    return _remoteDataSource.trackTripLiveStream(tripId, baseModel);
  }

  /// Stream live tracking for multiple active trips via Remote DataSource (Firestore)
  Stream<List<LiveTrackingModel>> trackMultipleTripsLive(List<int> tripIds) {
    return _remoteDataSource.trackMultipleTripsLiveStream(tripIds);
  }

  Future<List<LiveTrackingModel>> getMultipleActiveTracking() async {
    return await _remoteDataSource.getMultipleActiveTracking();
  }

  Future<List<UpcomingTripModel>> getUpcomingTrips() async {
    return await _remoteDataSource.getUpcomingTrips();
  }

  Future<TripHistoryResponseModel> getTripHistory({
    int page = 1,
    int perPage = 15,
  }) async {
    return await _remoteDataSource.getTripHistory(page: page, perPage: perPage);
  }

  Future<TripDetailsModel> getTripDetails(dynamic tripId) async {
    return await _remoteDataSource.getTripDetails(tripId);
  }

  Future<List<TripTimelineItemModel>> getTripTimeline(dynamic tripId) async {
    return await _remoteDataSource.getTripTimeline(tripId);
  }

  Future<ChildTripsModel> getChildTrips(dynamic childId) async {
    return await _remoteDataSource.getChildTrips(childId);
  }

  Future<Map<String, dynamic>> getChildStatus(dynamic tripId, dynamic childId) async {
    return await _remoteDataSource.getChildStatus(tripId, childId);
  }
}
