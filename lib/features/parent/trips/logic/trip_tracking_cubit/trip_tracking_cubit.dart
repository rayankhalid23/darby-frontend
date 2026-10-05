import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/trips_repository.dart';
import '../../data/models/active_trip_model.dart';
import '../../data/models/trip_track_model.dart';
import 'trip_tracking_state.dart';

class TripTrackingCubit extends Cubit<TripTrackingState> {
  final TripsRepository _repository;

  StreamSubscription<LiveTrackingModel>? _singleTrackSubscription;
  StreamSubscription<List<LiveTrackingModel>>? _multiTrackSubscription;

  dynamic _currentTripId;
  bool _isMultiMode = false;
  List<ActiveTripModel> _allActiveTrips = [];
  LiveTrackingModel? _baseTrackData;

  TripTrackingCubit(this._repository) : super(TripTrackingInitial());

  void setAllActiveTrips(List<ActiveTripModel> trips) {
    _allActiveTrips = trips;
  }

  /// ─── 1. تتبع رحلة واحدة عبر الفايربيز (Clean Architecture) ───
  void startTracking(
    dynamic tripId, {
    ActiveTripModel? activeTrip,
    int? childId,
  }) {
    _isMultiMode = false;
    _currentTripId = tripId;
    _stopSubscriptions();

    if (state is! TripTrackingSingleLoaded &&
        state is! TripTrackingMultiLoaded) {
      emit(TripTrackingLoading());
    }

    _initAndListenSingleTrack(
      tripId,
      activeTrip: activeTrip,
      childId: childId,
    );
  }

  Future<void> _initAndListenSingleTrack(
    dynamic tripId, {
    ActiveTripModel? activeTrip,
    int? childId,
  }) async {
    // 1. محاولة جلب المعلومات التأسيسية للرحلة (السائق، الوجهة، الأطفال) عبر الـ Repository
    try {
      _baseTrackData = await _repository.getTripTrack(tripId);
    } catch (_) {
      final parsedTripId = int.tryParse(tripId.toString()) ?? 0;
      _baseTrackData = LiveTrackingModel(
        tripId: parsedTripId,
        status: 'active',
        driverLat: 0.0,
        driverLng: 0.0,
        lastUpdated: 'الآن',
      );
    }

    ActiveTripModel? matchedTrip = activeTrip;
    if (matchedTrip == null && _allActiveTrips.isNotEmpty) {
      try {
        matchedTrip = _allActiveTrips.firstWhere((t) => t.tripId == tripId);
      } catch (_) {}
    }

    final int parsedTripId = int.tryParse(tripId.toString()) ?? 0;

    // 2. الاستماع للبث اللحظي القادم من الـ Repository
    _singleTrackSubscription = _repository
        .trackTripLive(parsedTripId, _baseTrackData!)
        .listen(
      (updatedModel) {
        _baseTrackData = updatedModel;
        emit(
          TripTrackingSingleLoaded(
            trackData: updatedModel,
            activeTrip: matchedTrip,
            selectedChildId: childId,
            isOffline: false,
          ),
        );
      },
      onError: (error) {
        debugPrint('❌ [Firestore] تعذر قراءة موقع السائق trips_tracking/$parsedTripId: $error');
        if (state is TripTrackingSingleLoaded) {
          final current = state as TripTrackingSingleLoaded;
          emit(
            TripTrackingSingleLoaded(
              trackData: current.trackData,
              activeTrip: current.activeTrip,
              selectedChildId: current.selectedChildId,
              isOffline: true,
              offlineMessage: 'تعثر تحديث الموقع اللحظي من الفايربيز',
            ),
          );
        } else {
          emit(TripTrackingError('خطأ في البث اللحظي للفايربيز: $error'));
        }
      },
    );
  }

  /// ─── 2. تتبع رحلات متعددة عبر الفايربيز (Clean Architecture) ───
  void startMultiTracking({List<ActiveTripModel>? activeTrips}) {
    _isMultiMode = true;
    _currentTripId = null;
    if (activeTrips != null && activeTrips.isNotEmpty) {
      _allActiveTrips = activeTrips;
    }
    _stopSubscriptions();

    if (state is! TripTrackingMultiLoaded &&
        state is! TripTrackingSingleLoaded) {
      emit(TripTrackingLoading());
    }

    _listenMultiTrack();
  }

  void _listenMultiTrack() {
    final tripIds = _allActiveTrips.map((t) => t.tripId).toList();
    _multiTrackSubscription = _repository.trackMultipleTripsLive(tripIds).listen(
      (tracks) {
        emit(
          TripTrackingMultiLoaded(
            tracks: tracks,
            activeTrips: _allActiveTrips,
            isOffline: false,
          ),
        );
      },
      onError: (error) {
        debugPrint('❌ [Firestore] تعذر قراءة مواقع السائقين من trips_tracking: $error');
        if (state is! TripTrackingMultiLoaded) {
          emit(TripTrackingError('خطأ في تتبع الرحلات المتعددة: $error'));
        }
      },
    );
  }

  Future<void> refresh() async {
    if (_isMultiMode) {
      _listenMultiTrack();
    } else if (_currentTripId != null) {
      startTracking(_currentTripId);
    }
  }

  void _stopSubscriptions() {
    _singleTrackSubscription?.cancel();
    _singleTrackSubscription = null;
    _multiTrackSubscription?.cancel();
    _multiTrackSubscription = null;
  }

  void stopTracking() {
    _stopSubscriptions();
  }

  @override
  Future<void> close() {
    _stopSubscriptions();
    return super.close();
  }
}
