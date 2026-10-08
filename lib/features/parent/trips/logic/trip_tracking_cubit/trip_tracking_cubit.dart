import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/trips_repository.dart';
import '../../data/models/active_trip_model.dart';
import '../../data/models/trip_track_model.dart';
import 'substitute_trip_switch.dart';
import 'trip_tracking_state.dart';

class TripTrackingCubit extends Cubit<TripTrackingState> {
  final TripsRepository _repository;

  StreamSubscription<LiveTrackingModel>? _singleTrackSubscription;
  StreamSubscription<List<LiveTrackingModel>>? _multiTrackSubscription;

  dynamic _currentTripId;
  bool _isMultiMode = false;
  List<ActiveTripModel> _allActiveTrips = [];
  LiveTrackingModel? _baseTrackData;
  int? _currentChildId;

  /// يزيد مع كل startTracking — رد /track متأخر لطلب قديم ما يركبش فوق الجديد
  int _singleTrackRequest = 0;

  /// لما رحلة متتبَّعة تتوقف بعطل (suspended_breakdown) نعاودوا نطلبوا
  /// trips/active لين تظهر رحلة السائق البديل (original_trip_id = الرحلة المعطلة)
  /// ونتحولوا ليها. يوقف بعد التحويل أو بعد [_substitutePollTimeout]
  Timer? _substitutePollTimer;
  DateTime? _substitutePollStartedAt;
  bool _substituteCheckInFlight = false;
  static const Duration _substitutePollInterval = Duration(seconds: 20);
  static const Duration _substitutePollTimeout = Duration(minutes: 30);
  static const String _suspendedStatus = 'suspended_breakdown';

  /// مواقع المدارس/البيوت من /track للرحلات اللي trips/active يرجّعها بدون
  /// إحداثيات (رحلة البديل) — Firestore ما فيهوش المواقع هذي بوضع "كل الأطفال"
  final Map<int, List<TrackingChildInfo>> _trackChildrenCache = {};
  final Set<int> _trackChildrenRequested = {};

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
    _currentChildId = childId;
    _stopSubscriptions();
    _resetSubstituteWatch();

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
    final request = ++_singleTrackRequest;
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

    // الشاشة ممكن تتقفل (والكيوبت معاها) وإحنا نستنوا /track، أو التتبع
    // تحوّل لرحلة ثانية (طفل ثاني، أو رحلة البديل) قبل ما يوصل الرد
    if (isClosed || request != _singleTrackRequest || _isMultiMode) return;

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
        _watchForSubstitute([updatedModel]);
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
    _resetSubstituteWatch();

    if (state is! TripTrackingMultiLoaded &&
        state is! TripTrackingSingleLoaded) {
      emit(TripTrackingLoading());
    }

    _listenMultiTrack();
    _fetchMissingStopLocations();
  }

  void _listenMultiTrack() {
    final tripIds = _allActiveTrips.map((t) => t.tripId).toList();
    _multiTrackSubscription = _repository.trackMultipleTripsLive(tripIds).listen(
      (tracks) {
        emit(
          TripTrackingMultiLoaded(
            tracks: _withCachedChildren(tracks),
            activeTrips: _allActiveTrips,
            isOffline: false,
          ),
        );
        _watchForSubstitute(tracks);
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

  /// رحلة بدون مواقع مدارس/بيوت بـ trips/active (رحلة البديل) → نجيبوها من
  /// /track مرة وحدة. الرحلات العادية مواقعها جاية أصلاً، فما يتطلبلهاش شي
  void _fetchMissingStopLocations() {
    for (final trip in _allActiveTrips) {
      if (trip.uniqueSchools.isNotEmpty || trip.uniqueHomeAddresses.isNotEmpty) continue;
      if (!_trackChildrenRequested.add(trip.tripId)) continue;
      _loadTrackChildren(trip.tripId);
    }
  }

  Future<void> _loadTrackChildren(int tripId) async {
    try {
      final track = await _repository.getTripTrack(tripId);
      if (isClosed || track.children.isEmpty) return;
      _trackChildrenCache[tripId] = track.children;
      final current = state;
      if (current is TripTrackingMultiLoaded) {
        emit(
          TripTrackingMultiLoaded(
            tracks: _withCachedChildren(current.tracks),
            activeTrips: current.activeTrips,
            isOffline: current.isOffline,
          ),
        );
      }
    } catch (_) {
      _trackChildrenRequested.remove(tripId); // نعاودوا لما يعاود يبدا التتبع
    }
  }

  List<LiveTrackingModel> _withCachedChildren(List<LiveTrackingModel> tracks) {
    if (_trackChildrenCache.isEmpty) return tracks;
    return [
      for (final track in tracks)
        (track.children.isEmpty && _trackChildrenCache.containsKey(track.tripId))
            ? track.copyWith(children: _trackChildrenCache[track.tripId])
            : track,
    ];
  }

  // ─── 3. التحويل التلقائي لرحلة السائق البديل بعد عطل الحافلة ───

  void _resetSubstituteWatch() {
    _substitutePollTimer?.cancel();
    _substitutePollTimer = null;
    _substitutePollStartedAt = null;
  }

  void _watchForSubstitute(Iterable<LiveTrackingModel> tracks) {
    if (!tracks.any((t) => t.status == _suspendedStatus)) return;
    if (_substitutePollTimer != null) return;
    final startedAt = _substitutePollStartedAt;
    // انتهت المهلة لهذي الجلسة — ما نعاودوش لين يعاود يبدا التتبع
    if (startedAt != null && DateTime.now().difference(startedAt) > _substitutePollTimeout) return;
    _substitutePollStartedAt ??= DateTime.now();
    _checkForSubstitute();
    _substitutePollTimer = Timer.periodic(_substitutePollInterval, (_) => _checkForSubstitute());
  }

  Future<void> _checkForSubstitute() async {
    final startedAt = _substitutePollStartedAt;
    if (startedAt != null && DateTime.now().difference(startedAt) > _substitutePollTimeout) {
      _substitutePollTimer?.cancel();
      _substitutePollTimer = null;
      return;
    }
    if (_substituteCheckInFlight) return;
    _substituteCheckInFlight = true;

    final List<ActiveTripModel> latest;
    try {
      latest = await _repository.getActiveTrips();
    } catch (_) {
      return; // نعاودوا المحاولة بالدورة الجاية
    } finally {
      _substituteCheckInFlight = false;
    }
    if (isClosed) return;

    if (_isMultiMode) {
      final updated = replaceWithSubstitutes(_allActiveTrips, latest);
      if (updated == null) return;
      debugPrint('🔄 [Tracking] تحويل للسائق البديل (كل الأطفال): ${updated.map((t) => t.tripId).toList()}');
      startMultiTracking(activeTrips: updated);
      return;
    }

    final currentId = int.tryParse(_currentTripId?.toString() ?? '');
    ActiveTripModel? substitute;
    for (final trip in latest) {
      if (trip.isSubstitute && currentId != null && trip.originalTripId == currentId) {
        substitute = trip;
        break;
      }
    }
    if (substitute == null) return;
    debugPrint('🔄 [Tracking] تحويل للسائق البديل: $currentId → ${substitute.tripId}');

    // القائمة الكاملة تتحدث هي كمان، حتى لو رجع ولي الأمر لوضع "كل الأطفال"
    final updated = replaceWithSubstitutes(_allActiveTrips, [substitute]) ?? List.of(_allActiveTrips);
    if (!updated.any((t) => t.tripId == substitute!.tripId)) updated.add(substitute);
    _allActiveTrips = updated;
    startTracking(substitute.tripId, activeTrip: substitute, childId: _currentChildId);
  }

  void stopTracking() {
    _stopSubscriptions();
    _resetSubstituteWatch();
  }

  @override
  Future<void> close() {
    _stopSubscriptions();
    _resetSubstituteWatch();
    return super.close();
  }
}
