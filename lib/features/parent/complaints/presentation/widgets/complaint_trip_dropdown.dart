import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/app_date_formatter.dart';
import '../../data/models/driver_trip_model.dart';

class ComplaintTripDropdown extends StatelessWidget {
  final List<DriverTripModel> trips;
  final int? selectedTripId;
  final ValueChanged<int?> onChanged;
  final bool isLoading;

  const ComplaintTripDropdown({
    super.key,
    required this.trips,
    required this.selectedTripId,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isDark ? AppColors.grey800 : AppColors.grey300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18.w,
              height: 18.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'جاري تحميل رحلات السائق...',
              style: AppTextStyles.style(
                fontSize: 12.sp,
                color: isDark ? AppColors.grey400 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? AppColors.grey800 : AppColors.grey300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedTripId,
          isExpanded: true,
          hint: Text(
            'شكوى عامة (ليست مرتبطة برحلة)',
            style: AppTextStyles.style(
              fontSize: 12.sp,
              color: isDark ? AppColors.grey400 : AppColors.textMuted,
            ),
          ),
          icon: Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.primary),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'شكوى عامة (ليست مرتبطة برحلة)',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...trips.map((trip) {
              final String timingAr = (trip.tripType?.toLowerCase() == 'morning') ? 'صباحية' : 'مسائية';
              final String statusAr = switch (trip.status?.toLowerCase() ?? '') {
                'pending' => 'معلقة',
                'active' || 'ongoing' || 'started' => 'جاري التوصيل',
                'completed' || 'finished' => 'مكتملة',
                'cancelled' => 'ملغاة',
                _ => trip.status ?? 'غير متوفر',
              };
              final String dateStr = trip.scheduledFor != null
                  ? AppDateFormatter.formatDate(trip.scheduledFor)
                  : 'غير متوفر';

              return DropdownMenuItem<int?>(
                value: trip.id,
                child: Text(
                  'رحلة #${trip.id} - $timingAr (التاريخ: $dateStr) [الحالة: $statusAr]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
