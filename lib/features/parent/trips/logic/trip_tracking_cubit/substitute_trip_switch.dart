import '../../data/models/active_trip_model.dart';
import 'trip_tracking_state.dart';

/// منطق مشترك لاستبدال رحلة حافلة معطلة برحلة السائق البديل
/// (is_substitute + original_trip_id) — يستعمله الكيوبت وشاشات التتبع.

/// رحلات البدلاء اللي الكيوبت تحوّل ليها، من حالته الحالية
List<ActiveTripModel> substituteTripsIn(TripTrackingState state) {
  if (state is TripTrackingMultiLoaded) {
    return state.activeTrips.where((t) => t.isSubstitute).toList();
  }
  if (state is TripTrackingSingleLoaded) {
    final trip = state.activeTrip;
    if (trip != null && trip.isSubstitute) return [trip];
  }
  return const [];
}

/// رحلة البديل اللي حلّت محل [trip] من بين [candidates]، أو null
ActiveTripModel? substituteFor(ActiveTripModel? trip, Iterable<ActiveTripModel> candidates) {
  if (trip == null) return null;
  for (final candidate in candidates) {
    if (candidate.isSubstitute && candidate.originalTripId == trip.tripId) return candidate;
  }
  return null;
}

/// نسخة من [trips] كل رحلة معطلة فيها مبدّلة برحلة بديلها من [candidates]
/// بنفس مكانها، بدون تكرار لو رحلة البديل موجودة أصلاً.
/// null لو ما فيش حتى رحلة تبدّلت.
List<ActiveTripModel>? replaceWithSubstitutes(
  List<ActiveTripModel> trips,
  Iterable<ActiveTripModel> candidates,
) {
  final byOriginal = <int, ActiveTripModel>{};
  for (final candidate in candidates) {
    final originalId = candidate.originalTripId;
    if (candidate.isSubstitute && originalId != null && trips.any((t) => t.tripId == originalId)) {
      byOriginal[originalId] = candidate;
    }
  }
  if (byOriginal.isEmpty) return null;

  final next = <ActiveTripModel>[];
  for (final trip in trips) {
    final replacement = byOriginal[trip.tripId] ?? trip;
    if (!next.any((n) => n.tripId == replacement.tripId)) next.add(replacement);
  }
  return next;
}
