import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kids_transport/core/widgets/app_user_avatar.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import '../../data/models/child_trips_model.dart';
import '../../logic/child_trips_cubit/child_trips_cubit.dart';
import '../../logic/child_trips_cubit/child_trips_state.dart';
import 'trip_tracking_screen.dart';

class ChildTripsScreen extends StatefulWidget {
  final dynamic childId;

  const ChildTripsScreen({super.key, required this.childId});

  @override
  State<ChildTripsScreen> createState() => _ChildTripsScreenState();
}

class _ChildTripsScreenState extends State<ChildTripsScreen> {
  late final ChildTripsCubit _childTripsCubit;

  @override
  void initState() {
    super.initState();
    _childTripsCubit = getIt<ChildTripsCubit>()..loadChildTrips(widget.childId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'رحلات الطفل',
            style: AppTextStyles.style(
              fontWeight: FontWeight.bold,
              fontSize: 17.sp,
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          foregroundColor: isDark ? AppColors.white : AppColors.textDark,
        ),
        body: BlocProvider.value(
          value: _childTripsCubit,
          child: BlocBuilder<ChildTripsCubit, ChildTripsState>(
            builder: (context, state) {
              if (state is ChildTripsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ChildTripsError) {
                return Center(
                  child: Text(
                    'تعذر تحميل رحلات الطفل: ${state.message}',
                    style: AppTextStyles.style(color: AppColors.error),
                  ),
                );
              } else if (state is ChildTripsLoaded) {
                return _buildChildTripsContent(context, state.childTrips, isDark);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChildTripsContent(BuildContext context, ChildTripsModel model, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Header Profile & Statistics Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: context.primaryGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                  backgroundImage: model.childPhoto != null && model.childPhoto!.isNotEmpty
                      ? CachedNetworkImageProvider(
                          AppUserAvatar.resolveUrl(model.childPhoto)!,
                          headers: AppUserAvatar.imageHeaders,
                        )
                      : null,
                  child: model.childPhoto == null || model.childPhoto!.isEmpty
                      ? Icon(Icons.person_rounded, size: 32.r, color: AppColors.white)
                      : null,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.childName,
                        style: AppTextStyles.style(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'إحصائيات الرحلات لهذا الشهر',
                        style: AppTextStyles.style(
                          fontSize: 12.sp,
                          color: AppColors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${model.attendancePercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.style(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'نسبة الحضور',
                      style: AppTextStyles.style(
                        fontSize: 10.sp,
                        color: AppColors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Active Trip Section
          if (model.currentTrip != null) ...[
            Text(
              'الرحلة الحالية النشطة',
              style: AppTextStyles.style(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? context.cardSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        model.currentTrip!.driver.name,
                        style: AppTextStyles.style(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'نشطة الآن',
                          style: AppTextStyles.style(fontSize: 10.sp, color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TripTrackingScreen(trip: model.currentTrip!),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('فتح التتبع الحي'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Upcoming Trips Section
          Text(
            'الرحلات القادمة (${model.upcomingTrips.length})',
            style: AppTextStyles.style(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          SizedBox(height: 8.h),

          if (model.upcomingTrips.isEmpty)
            Text('لا توجد رحلات قادمة لهذا الطفل.', style: AppTextStyles.style(fontSize: 12.sp, color: AppColors.textMuted))
          else
            ...model.upcomingTrips.map((upcoming) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? context.cardSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: context.primaryColor, size: 20.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(upcoming.title, style: AppTextStyles.style(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
                            Text(upcoming.scheduledDateTime, style: AppTextStyles.style(fontSize: 11.sp, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

          SizedBox(height: 20.h),

          // History Section
          Text(
            'سجل الرحلات السابقة',
            style: AppTextStyles.style(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          SizedBox(height: 8.h),

          if (model.history.isEmpty)
            Text('لا يملك الطفل سجل رحلات سابق.', style: AppTextStyles.style(fontSize: 12.sp, color: AppColors.textMuted))
          else
            ...model.history.map((hist) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark ? context.cardSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.success, size: 20.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hist.tripDate, style: AppTextStyles.style(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimary)),
                            Text('السائق: ${hist.driverName}', style: AppTextStyles.style(fontSize: 11.sp, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(hist.actionType, style: AppTextStyles.style(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
