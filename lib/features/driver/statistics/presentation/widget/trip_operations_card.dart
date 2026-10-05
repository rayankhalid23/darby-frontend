import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../data/models/driver_statistics_model.dart';

class TripOperationsCard extends StatelessWidget {
  final TripOperationsStatsModel tripStats;

  const TripOperationsCard({
    super.key,
    required this.tripStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trips = tripStats.completedTrips;
    final downtime = tripStats.absencesAndBreakdowns;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                color: theme.colorScheme.primary,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                'عمليات الرحلات والإنتاجية',
                style: AppTextStyles.style(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // تفكيك الرحلات المكتملة
          Text(
            'تفكيك الرحلات المكتملة:',
            style: AppTextStyles.style(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey400 : AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _tripRowItem(
                  Icons.wb_sunny_outlined,
                  'الرحلات الصباحية',
                  '${trips.morningTrips}',
                  AppColors.warning,
                  isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _tripRowItem(
                  Icons.nights_stay_outlined,
                  'الرحلات المسائية',
                  '${trips.eveningTrips}',
                  AppColors.info,
                  isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _tripRowItem(
                  Icons.today_rounded,
                  'المكتملة اليوم',
                  '${trips.todayCompleted}',
                  AppColors.success,
                  isDark,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),
          Divider(color: isDark ? AppColors.grey800 : AppColors.grey200, height: 1),
          SizedBox(height: 14.h),

          // الأعطال
          Text(
            'الأعطال والتوقف:',
            style: AppTextStyles.style(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey400 : AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _downtimeItem(
                  'أعطال المركبة',
                  '${downtime.vehicleBreakdownsCount} مرة',
                  isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _downtimeItem(
                  'إجمالي التوقف',
                  '${downtime.totalDowntimeDays} يوم',
                  isDark,
                  isAlert: downtime.totalDowntimeDays > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripRowItem(
    IconData icon,
    String title,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? AppColors.grey800 : AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.r),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.style(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.style(
              fontSize: 10.sp,
              color: isDark ? AppColors.grey400 : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _downtimeItem(String title, String value, bool isDark, {bool isAlert = false}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.style(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: isAlert ? AppColors.error : (isDark ? AppColors.grey300 : AppColors.textDark),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.style(
            fontSize: 10.sp,
            color: isDark ? AppColors.grey400 : AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
