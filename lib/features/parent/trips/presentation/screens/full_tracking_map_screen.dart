import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import '../../data/models/active_trip_model.dart';
import '../../logic/trip_tracking_cubit/substitute_trip_switch.dart';
import '../../logic/trip_tracking_cubit/trip_tracking_cubit.dart';
import '../../logic/trip_tracking_cubit/trip_tracking_state.dart';
import '../widgets/tracking_map_widget.dart';
import '../widgets/trip_status_chip.dart';

class FullTrackingMapScreen extends StatefulWidget {
  final ActiveTripModel? selectedTrip;
  final List<ActiveTripModel> allTrips;

  const FullTrackingMapScreen({
    super.key,
    this.selectedTrip,
    this.allTrips = const [],
  });

  @override
  State<FullTrackingMapScreen> createState() => _FullTrackingMapScreenState();
}

class _FullTrackingMapScreenState extends State<FullTrackingMapScreen> {
  late final TripTrackingCubit _trackingCubit;
  late final MapController _mapController;
  late ActiveTripModel? _currentTrip;
  late List<ActiveTripModel> _trips;
  bool _isMultiMode = true;
  StreamSubscription<TripTrackingState>? _substituteSync;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _trackingCubit = getIt<TripTrackingCubit>();
    _substituteSync = _trackingCubit.stream.listen(_syncSubstituteTrip);

    _currentTrip = widget.selectedTrip;
    _trips = List.of(widget.allTrips);
    _isMultiMode = widget.selectedTrip == null;

    if (_isMultiMode) {
      _trackingCubit.startMultiTracking(activeTrips: _trips);
    } else {
      _trackingCubit.startTracking(widget.selectedTrip!.tripId, activeTrip: widget.selectedTrip);
    }
  }

  @override
  void dispose() {
    _substituteSync?.cancel();
    // الكيوبت factory خاص بالشاشة هذي — نقفلوه حتى ما يقعدش يسمع لـ Firestore
    // ويطلب trips/active بعد ما الشاشة تتقفل
    _trackingCubit.close();
    _mapController.dispose();
    super.dispose();
  }

  /// الكيوبت يتحول وحده لرحلة السائق البديل لما الحافلة تتعطل
  void _syncSubstituteTrip(TripTrackingState state) {
    if (!mounted) return;
    final substitutes = substituteTripsIn(state);
    if (substitutes.isEmpty) return;
    final updatedTrips = replaceWithSubstitutes(_trips, substitutes);
    final shownSubstitute = substituteFor(_currentTrip, substitutes);
    if (updatedTrips == null && shownSubstitute == null) return;

    setState(() {
      if (updatedTrips != null) _trips = updatedTrips;
      if (shownSubstitute != null) _currentTrip = shownSubstitute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // 1) FULL SCREEN MAP
            Positioned.fill(
              child: BlocProvider.value(
                value: _trackingCubit,
                child: BlocBuilder<TripTrackingCubit, TripTrackingState>(
                  builder: (context, state) {
                    return TrackingMapWidget(
                      mapController: _mapController,
                      isMultiMode: _isMultiMode || state is TripTrackingMultiLoaded,
                      singleTrack: state is TripTrackingSingleLoaded ? state.trackData : null,
                      singleTrip: _currentTrip,
                      multiTracks: state is TripTrackingMultiLoaded ? state.tracks : [],
                      multiTrips: _trips,
                      locationErrorMessage: TrackingMapWidget.locationErrorFrom(state),
                    );
                  },
                ),
              ),
            ),

            // 2) TOP HEADER BAR WITH BACK BUTTON
            Positioned(
              top: MediaQuery.of(context).padding.top + 12.h,
              right: 16.w,
              left: 16.w,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? AppColors.grey900 : AppColors.white,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, size: 18.r, color: context.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.grey900 : AppColors.white).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      _isMultiMode ? 'خريطة التتبع الشاملة 🟢' : 'تتبع رحلة ${_currentTrip?.driver.name ?? ""}',
                      style: AppTextStyles.style(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3) BOTTOM ACTIVE TRIPS LIST CARD (Matching Screenshot #6)
            Positioned(
              bottom: 16.h,
              left: 16.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: (isDark ? context.cardSurface : AppColors.white).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرحلات النشطة (${_trips.length})',
                      style: AppTextStyles.style(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ..._trips.map((trip) {
                      final isSelected = !_isMultiMode && _currentTrip?.tripId == trip.tripId;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _isMultiMode = false;
                            _currentTrip = trip;
                          });
                          _trackingCubit.startTracking(trip.tripId, activeTrip: trip);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            children: [
                              TripStatusChip.fromStatusString(trip.status, isCompact: true),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  trip.driver.name,
                                  style: AppTextStyles.style(
                                    fontSize: 13.sp,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? context.primaryColor : context.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: AppColors.grey400),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
