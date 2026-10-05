import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/app_user_avatar.dart';
import '../../data/models/active_trip_model.dart';
import '../../logic/trip_tracking_cubit/trip_tracking_cubit.dart';
import '../../logic/trip_tracking_cubit/trip_tracking_state.dart';
import '../widgets/messenger_children_bar.dart';
import '../widgets/tracking_map_widget.dart';
import '../widgets/child_trip_progress_stepper.dart';
import '../widgets/driver_card.dart';
import '../widgets/trip_status_chip.dart';
import 'full_tracking_map_screen.dart';
import 'trip_details_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  final ActiveTripModel? trip;
  final List<ActiveTripModel> allActiveTrips;
  final int? initialSelectedChildId;

  const TripTrackingScreen({
    super.key,
    this.trip,
    this.allActiveTrips = const [],
    this.initialSelectedChildId,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  late final TripTrackingCubit _trackingCubit;
  late final MapController _mapController;

  bool _isAllSelected = true;
  int? _selectedChildId;
  ActiveTripModel? _currentDisplayedTrip;
  List<ActiveTripModel> _effectiveTrips = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _trackingCubit = getIt<TripTrackingCubit>();

    if (widget.initialSelectedChildId != null) {
      _isAllSelected = false;
      _selectedChildId = widget.initialSelectedChildId;
    }

    if (widget.allActiveTrips.isNotEmpty) {
      _effectiveTrips = widget.allActiveTrips;
    } else if (widget.trip != null) {
      _effectiveTrips = [widget.trip!];
    } else {
      _effectiveTrips = [];
    }

    if (_effectiveTrips.isNotEmpty) {
      _currentDisplayedTrip = widget.trip ?? _effectiveTrips.first;
      _trackingCubit.startMultiTracking(activeTrips: _effectiveTrips);
    } else {
      _trackingCubit.startMultiTracking(activeTrips: []);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<MessengerChildItem> _extractChildrenItems() {
    final List<MessengerChildItem> items = [];
    final Set<int> addedChildIds = {};

    for (final trip in _effectiveTrips) {
      for (final child in trip.children) {
        if (!addedChildIds.contains(child.childId)) {
          addedChildIds.add(child.childId);
          items.add(
            MessengerChildItem(
              childId: child.childId,
              childName: child.childName,
              childPhoto: child.childPhoto,
              childStatus: child.childStatus,
              tripId: trip.tripId,
            ),
          );
        }
      }
    }
    return items;
  }

  void _onSelectAll() {
    setState(() {
      _isAllSelected = true;
      _selectedChildId = null;
      if (_effectiveTrips.isNotEmpty) {
        _currentDisplayedTrip = _effectiveTrips.first;
      }
    });
    _trackingCubit.startMultiTracking(activeTrips: _effectiveTrips);
  }

  // 🌟 UX FIX: Selecting a child story updates page mode dynamically without pushing a new screen!
  void _onSelectChild(MessengerChildItem item) {
    ActiveTripModel? targetTrip;
    try {
      targetTrip = _effectiveTrips.firstWhere((t) => t.tripId == item.tripId);
    } catch (_) {
      targetTrip = null;
    }

    setState(() {
      _isAllSelected = false;
      _selectedChildId = item.childId;
      _currentDisplayedTrip = targetTrip;
    });

    if (targetTrip != null) {
      _trackingCubit.startTracking(
        targetTrip.tripId,
        activeTrip: targetTrip,
        childId: item.childId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final childrenItems = _extractChildrenItems();

    // Selected child info if single child mode is active
    MessengerChildItem? selectedChildItem;
    if (!_isAllSelected && _selectedChildId != null) {
      try {
        selectedChildItem = childrenItems.firstWhere((c) => c.childId == _selectedChildId);
      } catch (_) {}
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'تتبع أبنائي',
            style: AppTextStyles.style(
              fontWeight: FontWeight.bold,
              fontSize: 17.sp,
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? AppColors.white : AppColors.textDark,
              size: 18.r,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // 1) TOP STORIES BAR (RTL)
            if (childrenItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: MessengerChildrenBar(
                  children: childrenItems,
                  isAllSelected: _isAllSelected,
                  selectedChildId: _selectedChildId,
                  activeTripsCount: _effectiveTrips.length,
                  onSelectAll: _onSelectAll,
                  onSelectChild: _onSelectChild,
                ),
              ),

            // 2) MIDDLE INTERACTIVE MAP WITH EXPAND BUTTON
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BlocProvider.value(
                      value: _trackingCubit,
                      child: BlocBuilder<TripTrackingCubit, TripTrackingState>(
                        builder: (context, state) {
                          return TrackingMapWidget(
                            mapController: _mapController,
                            isMultiMode: _isAllSelected,
                            singleTrack: state is TripTrackingSingleLoaded ? state.trackData : null,
                            singleTrip: _currentDisplayedTrip,
                            multiTracks: state is TripTrackingMultiLoaded ? state.tracks : [],
                            multiTrips: _effectiveTrips,
                            locationErrorMessage: TrackingMapWidget.locationErrorFrom(state),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16.h,
                    left: 16.w,
                    child: FloatingActionButton.small(
                      heroTag: 'expand_map_main',
                      backgroundColor: isDark ? AppColors.grey400 : AppColors.white,
                      elevation: 4,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullTrackingMapScreen(
                              selectedTrip: _isAllSelected ? null : _currentDisplayedTrip,
                              allTrips: _effectiveTrips,
                            ),
                          ),
                        );
                      },
                      child: Icon(Icons.fullscreen_rounded, color: context.primaryColor, size: 24.r),
                    ),
                  ),
                ],
              ),
            ),

            // 3) DYNAMIC BOTTOM SHEET (MODE 1: ALL TRIPS | MODE 2: SINGLE CHILD TRIP)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? context.cardSurface : AppColors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey700 : AppColors.grey300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      child: Text(
                        _isAllSelected
                            ? 'الرحلات النشطة (${_effectiveTrips.length})'
                            : 'تتبع رحلة ${selectedChildItem?.childName ?? "الطفل"}',
                        style: AppTextStyles.style(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isAllSelected
                          ? ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                              itemCount: _effectiveTrips.length,
                              separatorBuilder: (context, index) => SizedBox(height: 10.h),
                              itemBuilder: (context, index) {
                                final trip = _effectiveTrips[index];
                                return _buildActiveTripCard(context, trip, isDark);
                              },
                            )
                          : _buildSingleChildTripContent(
                              context,
                              selectedChildItem,
                              _currentDisplayedTrip,
                              isDark,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODE 1 CARD: Active Trip Item Card in Trips List Mode
  Widget _buildActiveTripCard(BuildContext context, ActiveTripModel trip, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailsScreen(tripId: trip.tripId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey900 : AppColors.grey50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.grey800 : AppColors.grey200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.person_rounded, color: context.primaryColor, size: 22.r),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.driver.name,
                        style: AppTextStyles.style(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        trip.vehicle.info,
                        style: AppTextStyles.style(
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (trip.busOccupancy != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'ركاب الحافلة: ${trip.busOccupancy!.displayOccupancy}',
                          style: AppTextStyles.style(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TripStatusChip.fromStatusString(trip.status),
                    SizedBox(height: 4.h),
                    Text(
                      trip.startedAt,
                      style: AppTextStyles.style(
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 16.h, thickness: 1),
            Row(
              children: [
                Text(
                  'الأطفال: ',
                  style: AppTextStyles.style(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
                ...trip.children.map((c) {
                  return Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppUserAvatar(
                          imageUrl: c.childPhoto,
                          radius: 9.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          c.childName.split(' ')[0],
                          style: AppTextStyles.style(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MODE 2 CONTENT: Single Child Trip View inside Bottom Sheet with Children Progress List
  Widget _buildSingleChildTripContent(
    BuildContext context,
    MessengerChildItem? childItem,
    ActiveTripModel? trip,
    bool isDark,
  ) {
    if (trip == null || childItem == null) {
      return Center(
        child: Text(
          'لا توجد رحلة نشطة لهذا الطفل حالياً',
          style: AppTextStyles.style(fontSize: 13.sp, color: AppColors.textMuted),
        ),
      );
    }

    final childInfo = trip.children.firstWhere(
      (c) => c.childId == childItem.childId,
      orElse: () => trip.children.first,
    );

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      children: [
        // 0) CHILD PROGRESS STEPPER BAR (TOP OF CARD FOR SELECTED CHILD)
        ChildTripProgressStepperWidget(
          childName: childItem.childName,
          childStatus: childInfo.childStatus,
          tripDirection: trip.direction,
          pickupTime: childInfo.pickupTime,
        ),
        SizedBox(height: 12.h),

        // 1) TRIP METRICS ROW: Departure Time & Total Children/Occupancy
        Row(
          children: [
            _buildMetricCard(context, Icons.flag_rounded, 'وقت الانطلاق', trip.startedAt),
            SizedBox(width: 8.w),
            _buildMetricCard(
              context,
              Icons.groups_rounded,
              'أطفال الرحلة',
              '${trip.children.length} أطفال',
            ),
            if (trip.busOccupancy != null) ...[
              SizedBox(width: 8.w),
              _buildMetricCard(
                context,
                Icons.directions_bus_rounded,
                'على متن الحافلة',
                '${trip.busOccupancy!.currentOnboardCount} من ${trip.busOccupancy!.totalTripChildren}',
              ),
            ],
          ],
        ),
        SizedBox(height: 12.h),

        // 2) DRIVER CARD (Tap driver photo/name to view Profile)
        DriverCard(driver: trip.driver),
        SizedBox(height: 12.h),

        // 3) ALL CHILDREN & PROGRESS IN THIS TRIP SECTION
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.grey900 : AppColors.grey50,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? AppColors.grey800 : AppColors.grey200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تقدم أطفال الرحلة (${trip.children.length}):',
                    style: AppTextStyles.style(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  TripStatusChip.fromStatusString(trip.status),
                ],
              ),
              SizedBox(height: 8.h),
              ...trip.children.map((c) {
                final isSelectedChild = c.childId == childItem.childId;
                final homeTitle = c.homeAddress?.title ??
                    (trip.uniqueHomeAddresses.isNotEmpty ? trip.uniqueHomeAddresses.first.title : null);
                final schoolName = c.school?.name ?? trip.destination.name;

                return Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelectedChild
                        ? context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                        : (isDark ? AppColors.grey800 : AppColors.white),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelectedChild
                          ? context.primaryColor
                          : (isDark ? AppColors.grey800 : AppColors.grey200),
                      width: isSelectedChild ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      AppUserAvatar(
                        imageUrl: c.childPhoto,
                        radius: 14.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.childName,
                                  style: AppTextStyles.style(
                                    fontSize: 11.sp,
                                    fontWeight: isSelectedChild ? FontWeight.bold : FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                                if (isSelectedChild) ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                                    decoration: BoxDecoration(
                                      color: context.primaryColor,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'المحدد',
                                      style: AppTextStyles.style(
                                        fontSize: 8.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Icon(Icons.home_rounded, size: 12.r, color: AppColors.orange),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    homeTitle ?? 'المنزل',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.style(
                                      fontSize: 9.5.sp,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(Icons.school_rounded, size: 12.r, color: context.primaryColor),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    schoolName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.style(
                                      fontSize: 9.5.sp,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      TripStatusChip.fromStatusString(c.childStatus),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // 4) ACTION BUTTON: FULL TRIP DETAILS
        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailsScreen(tripId: trip.tripId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.assignment_outlined, size: 18),
            label: Text(
              'عرض تفاصيل الرحلة بالكامل',
              style: AppTextStyles.style(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, String title, String value) {
    final isDark = context.isDarkMode;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey900 : AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? AppColors.grey800 : AppColors.grey200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.r, color: context.primaryColor),
            SizedBox(height: 4.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: AppTextStyles.style(
                  fontSize: 10.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: AppTextStyles.style(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
