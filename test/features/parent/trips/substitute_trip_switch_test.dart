import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_transport/features/parent/trips/data/models/active_trip_model.dart';
import 'package:kids_transport/features/parent/trips/data/models/trip_track_model.dart';
import 'package:kids_transport/features/parent/trips/data/repositories/trips_repository.dart';
import 'package:kids_transport/features/parent/trips/logic/trip_tracking_cubit/substitute_trip_switch.dart';
import 'package:kids_transport/features/parent/trips/logic/trip_tracking_cubit/trip_tracking_cubit.dart';
import 'package:kids_transport/features/parent/trips/logic/trip_tracking_cubit/trip_tracking_state.dart';

ActiveTripModel _trip(int id, {int? originalTripId, bool withSchoolLocation = true}) {
  return ActiveTripModel.fromJson({
    'trip_id': id,
    'status': 'in_progress',
    'is_substitute': originalTripId != null,
    'original_trip_id': originalTripId,
    'driver': {'id': id, 'name': 'سائق $id', 'phone': '091'},
    'children': [
      {
        'child_id': 45,
        'child_name': 'عمر',
        'child_status': 'waiting',
        if (withSchoolLocation) 'school': {'id': 3, 'name': 'مدرسة', 'lat': 32.87, 'lng': 13.19},
        if (!withSchoolLocation) 'school_name': 'مدرسة',
      },
    ],
  });
}

LiveTrackingModel _track(int id, String status, {List<TrackingChildInfo> children = const []}) {
  return LiveTrackingModel(
    tripId: id,
    status: status,
    driverLat: 32.88,
    driverLng: 13.18,
    lastUpdated: 'الآن',
    children: children,
  );
}

/// مستودع وهمي: Firestore = StreamControllers بنتحكموا فيهم، و trips/active و /track قيم ثابتة
class _FakeTripsRepository extends Fake implements TripsRepository {
  List<ActiveTripModel> activeTrips = [];
  int activeTripsCalls = 0;
  final List<int> trackRequests = [];
  final List<int> singleStreamsOpened = [];
  final Map<int, StreamController<LiveTrackingModel>> single = {};
  final StreamController<List<LiveTrackingModel>> multi = StreamController.broadcast();
  Completer<LiveTrackingModel>? pendingTrack;

  @override
  Future<List<ActiveTripModel>> getActiveTrips() async {
    activeTripsCalls++;
    return activeTrips;
  }

  @override
  Future<LiveTrackingModel> getTripTrack(dynamic tripId) {
    final id = int.parse(tripId.toString());
    trackRequests.add(id);
    final pending = pendingTrack;
    if (pending != null) return pending.future;
    return Future.value(
      _track(id, 'in_progress', children: [
        TrackingChildInfo.fromJson({
          'child_id': 45,
          'school': {'id': 3, 'name': 'مدرسة', 'lat': 32.87, 'lng': 13.19},
        }),
      ]),
    );
  }

  @override
  Stream<LiveTrackingModel> trackTripLive(int tripId, LiveTrackingModel baseModel) {
    singleStreamsOpened.add(tripId);
    return (single[tripId] ??= StreamController<LiveTrackingModel>.broadcast()).stream;
  }

  @override
  Stream<List<LiveTrackingModel>> trackMultipleTripsLive(List<int> tripIds) => multi.stream;
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('replaceWithSubstitutes', () {
    test('تبدّل الرحلة المعطلة بمكانها وتخلي الباقي', () {
      final result = replaceWithSubstitutes(
        [_trip(850), _trip(900)],
        [_trip(851, originalTripId: 850)],
      );
      expect(result?.map((t) => t.tripId), [851, 900]);
    });

    test('ما تكررش رحلة البديل لو موجودة أصلاً', () {
      final result = replaceWithSubstitutes(
        [_trip(850), _trip(851, originalTripId: 850)],
        [_trip(851, originalTripId: 850)],
      );
      expect(result?.map((t) => t.tripId), [851]);
    });

    test('ترجّع null لو ما فيش رحلة تبدّلت', () {
      expect(replaceWithSubstitutes([_trip(900)], [_trip(851, originalTripId: 850)]), isNull);
      expect(replaceWithSubstitutes([_trip(850)], [_trip(900)]), isNull);
    });
  });

  group('TripTrackingCubit - التحويل لرحلة البديل', () {
    late _FakeTripsRepository repo;
    late TripTrackingCubit cubit;

    setUp(() {
      repo = _FakeTripsRepository();
      cubit = TripTrackingCubit(repo);
    });

    tearDown(() => cubit.close());

    test('رحلة عادية: ما يطلبش trips/active', () async {
      cubit.startTracking(850, activeTrip: _trip(850), childId: 45);
      await _settle();
      repo.single[850]!.add(_track(850, 'in_progress'));
      await _settle();

      expect(repo.activeTripsCalls, 0);
      expect((cubit.state as TripTrackingSingleLoaded).activeTrip?.tripId, 850);
    });

    test('طفل واحد: لما الرحلة تتعطل يتحول لرحلة البديل ويسمع لـ Firestore متاعها', () async {
      repo.activeTrips = [_trip(851, originalTripId: 850)];
      cubit.startTracking(850, activeTrip: _trip(850), childId: 45);
      await _settle();

      repo.single[850]!.add(_track(850, 'suspended_breakdown'));
      await _settle();

      expect(repo.activeTripsCalls, 1);
      expect(repo.singleStreamsOpened, [850, 851]);

      repo.single[851]!.add(_track(851, 'in_progress'));
      await _settle();
      final state = cubit.state as TripTrackingSingleLoaded;
      expect(state.activeTrip?.tripId, 851);
      expect(state.activeTrip?.isSubstitute, isTrue);
      expect(state.selectedChildId, 45);
    });

    test('طفل واحد: لو البديل مازال ما قبلش، يقعد على الرحلة المعطلة', () async {
      repo.activeTrips = [];
      cubit.startTracking(850, activeTrip: _trip(850), childId: 45);
      await _settle();

      repo.single[850]!.add(_track(850, 'suspended_breakdown'));
      await _settle();

      expect(repo.activeTripsCalls, 1);
      expect(repo.singleStreamsOpened, [850]);
    });

    test('كل الأطفال: يبدّل الرحلة المعطلة بمكانها ويجيب مدرستها من /track', () async {
      repo.activeTrips = [_trip(851, originalTripId: 850, withSchoolLocation: false), _trip(900)];
      cubit.startMultiTracking(activeTrips: [_trip(850), _trip(900)]);
      await _settle();
      expect(repo.trackRequests, isEmpty, reason: 'الرحلات العادية مواقعها جاية أصلاً');

      repo.multi.add([_track(850, 'suspended_breakdown'), _track(900, 'in_progress')]);
      await _settle();

      expect(repo.trackRequests, [851]);
      repo.multi.add([_track(851, 'in_progress'), _track(900, 'in_progress')]);
      await _settle();

      final state = cubit.state as TripTrackingMultiLoaded;
      expect(state.activeTrips.map((t) => t.tripId), [851, 900]);
      final substituteTrack = state.tracks.firstWhere((t) => t.tripId == 851);
      expect(substituteTrack.uniqueSchools, hasLength(1));
    });

    test('قفل الكيوبت وهو يستنى /track ما يطيّحش التطبيق', () async {
      repo.pendingTrack = Completer<LiveTrackingModel>();
      cubit.startTracking(850, activeTrip: _trip(850));
      await cubit.close();

      repo.pendingTrack!.complete(_track(850, 'in_progress'));
      await _settle();
      expect(repo.singleStreamsOpened, isEmpty);
    });

    test('رد /track قديم ما يركبش فوق تتبع رحلة أحدث', () async {
      repo.pendingTrack = Completer<LiveTrackingModel>();
      cubit.startTracking(850, activeTrip: _trip(850));
      final slow = repo.pendingTrack!;
      repo.pendingTrack = null;
      cubit.startTracking(900, activeTrip: _trip(900));
      await _settle();

      slow.complete(_track(850, 'in_progress'));
      await _settle();
      expect(repo.singleStreamsOpened, [900]);
    });
  });
}
