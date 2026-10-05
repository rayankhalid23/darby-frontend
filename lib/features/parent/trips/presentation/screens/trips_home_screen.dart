import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/app_user_avatar.dart';
import 'package:kids_transport/core/widgets/app_section_header.dart';
import '../../data/models/active_trip_model.dart';
import '../../data/models/upcoming_trip_model.dart';
import '../../data/models/trip_history_model.dart';
import '../../logic/trips_cubit/trips_cubit.dart';
import '../../logic/trips_cubit/trips_state.dart';
import '../widgets/skeleton_loading_widget.dart';
import '../widgets/trip_status_chip.dart';
import 'trip_tracking_screen.dart';
import 'trip_details_screen.dart';
import 'active_trips_screen.dart';
import 'upcoming_trips_screen.dart';
import 'trip_history_screen.dart';
import 'child_trips_screen.dart';

class TripsHomeScreen extends StatefulWidget {
  const TripsHomeScreen({super.key});

  @override
  State<TripsHomeScreen> createState() => _TripsHomeScreenState();
}

class _TripsHomeScreenState extends State<TripsHomeScreen> {
  late final TripsCubit _tripsCubit;

  @override
  void initState() {
    super.initState();
    _tripsCubit = getIt<TripsCubit>()..fetchTripsOverview();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocProvider.value(
      value: _tripsCubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: BlocBuilder<TripsCubit, TripsState>(
              builder: (context, state) {
                if (state is TripsLoading) {
                  return ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: 3,
                    itemBuilder: (context, index) => const TripCardSkeleton(),
                  );
                }

                if (state is TripsError) {
                  return _buildErrorState(context, state.message);
                }

                if (state is TripsLoaded) {
                  final activeTrips = state.filteredActiveTrips;
                  final upcomingTrips = state.filteredUpcomingTrips;
                  final historyTrips = state.filteredHistoryTrips;

                  return RefreshIndicator(
                    onRefresh: () => _tripsCubit.fetchTripsOverview(),
                    color: context.primaryColor,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      children: [
                        // 1) 🌟 FULL-WIDTH DROPDOWN FILTER CONTAINER (SPANNING FROM START TO END)
                        _buildFullWidthChildrenDropdown(context, state, isDark),
                        SizedBox(height: 14.h),

                        // 2) SUMMARY METRICS ROW (ELEVATED COMPACT CARDS)
                        _buildSummaryMetricsRow(
                          context,
                          activeCount: activeTrips.length,
                          upcomingCount: upcomingTrips.length,
                          historyCount: historyTrips.length,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),

                        // 3) ACTIVE TRIPS SECTION (NO EMOJIS, SMALLER FONTS)
                        _buildSectionHeader(
                          context,
                          title: 'الرحلات النشطة الآن',
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ActiveTripsScreen(activeTrips: activeTrips),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 10.h),
                        if (state.activeError != null)
                          _buildErrorSectionCard(context, state.activeError!)
                        else if (activeTrips.isEmpty)
                          _buildEmptySectionCard(
                            context,
                            'لا توجد رحلات نشطة حالياً',
                          )
                        else ...[
                          _buildActiveTripPreviewCard(
                            context,
                            activeTrips.first,
                            activeTrips,
                            isDark,
                          ),
                        ],
                        SizedBox(height: 26.h),

                        // 4) UPCOMING TRIPS SECTION (NO EMOJIS, SMALLER FONTS)
                        _buildSectionHeader(
                          context,
                          title: 'الرحلات القادمة',
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpcomingTripsScreen(
                                  upcomingTrips: upcomingTrips,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 10.h),
                        if (state.upcomingError != null)
                          _buildErrorSectionCard(context, state.upcomingError!)
                        else if (upcomingTrips.isEmpty)
                          _buildEmptySectionCard(
                            context,
                            'لا توجد رحلات قادمة مجدولة',
                          )
                        else
                          _buildUpcomingTripPreviewCard(
                            context,
                            upcomingTrips.first,
                            isDark,
                          ),
                        SizedBox(height: 26.h),

                        // 5) HISTORY TRIPS SECTION (NO EMOJIS, SMALLER FONTS)
                        _buildSectionHeader(
                          context,
                          title: 'الرحلات المكتملة',
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripHistoryScreen(
                                  historyTrips: historyTrips,
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 10.h),
                        if (state.historyError != null)
                          _buildErrorSectionCard(context, state.historyError!)
                        else if (historyTrips.isEmpty)
                          _buildEmptySectionCard(
                            context,
                            'لا توجد رحلات بسجل المكتملة',
                          )
                        else
                          _buildHistoryTripPreviewCard(
                            context,
                            historyTrips.first,
                            isDark,
                          ),
                        SizedBox(height: 14.h),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 FULL-WIDTH DROPDOWN FILTER CONTAINER (EDGE TO EDGE)
  Widget _buildFullWidthChildrenDropdown(
    BuildContext context,
    TripsLoaded state,
    bool isDark,
  ) {
    final Map<int, String> uniqueChildren = {};
    for (final t in state.activeTrips) {
      for (final c in t.children) {
        if (c.childId > 0 && c.childName.isNotEmpty) {
          uniqueChildren[c.childId] = c.childName;
        }
      }
    }
    for (final t in state.upcomingTrips) {
      for (final c in t.children) {
        if (c.childId > 0 && c.childName.isNotEmpty) {
          uniqueChildren[c.childId] = c.childName;
        }
      }
    }
    for (final t in state.historyTrips) {
      for (final c in t.children) {
        if (c.childId > 0 && c.childName.isNotEmpty) {
          uniqueChildren[c.childId] = c.childName;
        }
      }
    }

    final List<Map<String, dynamic>> childrenOptions = [
      {'id': null, 'name': 'جميع الأطفال'},
      ...uniqueChildren.entries.map((e) => {'id': e.key, 'name': e.value}),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: state.selectedChildId,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.primaryColor,
            size: 22.r,
          ),
          items: childrenOptions.map((opt) {
            return DropdownMenuItem<int?>(
              value: opt['id'] as int?,
              child: Row(
                children: [
                  Icon(
                    opt['id'] == null
                        ? Icons.people_alt_rounded
                        : Icons.person_rounded,
                    color: context.primaryColor,
                    size: 18.r,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    opt['name'] as String,
                    style: AppTextStyles.style(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            final selectedName =
                childrenOptions.firstWhere((o) => o['id'] == val)['name']
                    as String;
            _tripsCubit.filterByChild(val, selectedName);
            if (val != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChildTripsScreen(childId: val),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Summary Metrics Row
  Widget _buildSummaryMetricsRow(
    BuildContext context, {
    required int activeCount,
    required int upcomingCount,
    required int historyCount,
    required bool isDark,
  }) {
    return Row(
      children: [
        _buildMetricBox(
          context,
          'نشطة الآن',
          '$activeCount',
          AppColors.success,
          isDark,
        ),
        SizedBox(width: 8.w),
        _buildMetricBox(
          context,
          'قادمة',
          '$upcomingCount',
          AppColors.warning,
          isDark,
        ),
        SizedBox(width: 8.w),
        _buildMetricBox(
          context,
          'مكتملة',
          '$historyCount',
          AppColors.maleBlue,
          isDark,
        ),
      ],
    );
  }

  Widget _buildMetricBox(
    BuildContext context,
    String label,
    String count,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: AppTextStyles.style(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: AppTextStyles.style(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header with Grey Title and Grey Divider Line
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onViewAll,
  }) {
    return AppSectionHeader(
      title: title,
      actionWidget: InkWell(
        onTap: onViewAll,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            'عرض الكل',
            style: AppTextStyles.style(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // Active Trip Preview Card
  Widget _buildActiveTripPreviewCard(
    BuildContext context,
    ActiveTripModel trip,
    List<ActiveTripModel> allTrips,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppUserAvatar(imageUrl: trip.driver.photo, radius: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driver.name,
                      style: AppTextStyles.style(
                        fontSize: 12.sp,
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
                        'إشغال الحافلة: ${trip.busOccupancy!.displayOccupancy} أطفال',
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
                  SizedBox(height: 3.h),
                  Text(
                    'بدأ ${trip.startedAt}',
                    style: AppTextStyles.style(
                      fontSize: 9.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 18.h, thickness: 1),

          // Children List in Trip
          ...trip.children.map((c) {
            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  AppUserAvatar(imageUrl: c.childPhoto, radius: 9.r),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      c.childName,
                      style: AppTextStyles.style(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  TripStatusChip.fromStatusString(c.childStatus),
                ],
              ),
            );
          }),
          SizedBox(height: 10.h),

          // Action Buttons: "التفاصيل" & "تتبع"
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36.h,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TripDetailsScreen(tripId: trip.tripId),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      side: BorderSide(color: context.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt_rounded, size: 14),
                    label: Text(
                      'التفاصيل',
                      style: AppTextStyles.style(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SizedBox(
                  height: 36.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripTrackingScreen(
                            trip: trip,
                            allActiveTrips: allTrips,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.location_on_rounded, size: 14),
                    label: Text(
                      'تتبع',
                      style: AppTextStyles.style(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Upcoming Trip Preview Card
  Widget _buildUpcomingTripPreviewCard(
    BuildContext context,
    UpcomingTripModel trip,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.warning,
              size: 16.r,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.scheduledDateTime,
                  style: AppTextStyles.style(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'السائق: ${trip.driver.name}',
                  style: AppTextStyles.style(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 12.r,
            color: AppColors.grey400,
          ),
        ],
      ),
    );
  }

  // History Trip Preview Card
  Widget _buildHistoryTripPreviewCard(
    BuildContext context,
    TripHistoryModel trip,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.grey700 : AppColors.grey300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 16.r,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رحلة بتاريخ ${trip.tripDate}',
                  style: AppTextStyles.style(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'السائق: ${trip.driverName}',
                  style: AppTextStyles.style(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trip.tripCost,
            style: AppTextStyles.style(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.grey900 : AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.style(fontSize: 10.sp, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildErrorSectionCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 16.r, color: AppColors.error),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.start,
              style: AppTextStyles.style(fontSize: 10.sp, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44.r,
              color: AppColors.error,
            ),
            SizedBox(height: 12.h),
            Text(message, style: AppTextStyles.style(color: AppColors.error)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _tripsCubit.fetchTripsOverview(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
