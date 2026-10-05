import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../data/models/request_model.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;
  final bool isCancelling;
  final VoidCallback? onDetailsPressed;
  final VoidCallback? onCancelPressed;

  const RequestCard({
    super.key,
    required this.request,
    this.isCancelling = false,
    this.onDetailsPressed,
    this.onCancelPressed,
  });

  Color _statusColor(BuildContext context) {
    switch (request.status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return AppColors.grey500;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(context);
    final isPending = request.status.toLowerCase() == 'pending';
    final driver = request.driver;
    final sub = request.subscription;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── شريط الحالة ──
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20.r),
                topLeft: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: statusColor),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    request.statusDisplayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.style(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDate(request.createdAt),
                  style: AppTextStyles.style(
                    fontSize: 11.sp,
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── صف السائق ──
                Row(
                  children: [
                    _driverAvatar(driver, theme),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.style(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textDark,
                            ),
                          ),
                          if (driver.phone != null)
                            Text(
                              driver.phone!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.style(
                                fontSize: 12.sp,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // مكيف
                    if (driver.vehicle?.hasAc == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.ac_unit_rounded,
                                size: 10.r, color: Colors.blue),
                            SizedBox(width: 3.w),
                            Text(
                              'مكيف',
                              style: AppTextStyles.style(
                                fontSize: 10.sp,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12.h),
                Divider(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    height: 1),
                SizedBox(height: 12.h),

                // ── معلومات الاشتراك المشتركة ──
                _infoRow(
                  icon: Icons.calendar_month_rounded,
                  label: sub.typeDisplayLabel,
                  value:
                      '${_formatDate(sub.startDate)} — ${_formatDate(sub.endDate ?? '')}',
                  isDark: isDark,
                ),
                SizedBox(height: 6.h),
                _infoRow(
                  icon: Icons.sync_alt_rounded,
                  label: 'الرحلة',
                  value: sub.directionDisplayLabel,
                  isDark: isDark,
                ),
                SizedBox(height: 6.h),
                _infoRow(
                  icon: Icons.group_rounded,
                  label: 'عدد الأطفال',
                  value: '${request.childrenCount}',
                  isDark: isDark,
                ),

                // ── التسعير الإجمالي ──
                if (request.pricing != null) ...[
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'الإجمالي بعد الخصم',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.style(
                            fontSize: 12.sp,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        request.formattedTotalPrice,
                        style: AppTextStyles.style(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 12.h),
                Divider(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    height: 1),
                SizedBox(height: 12.h),

                // ── سبب الرفض ──
                if (request.status.toLowerCase() == 'rejected' &&
                    request.notes != null) ...[
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14.r, color: AppColors.error),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            request.notes!,
                            style: AppTextStyles.style(
                              fontSize: 12.sp,
                              color: AppColors.error,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // ── أزرار ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDetailsPressed,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(
                          'التفاصيل',
                          style: AppTextStyles.style(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    if (isPending && onCancelPressed != null) ...[
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCancelling ? null : onCancelPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: isCancelling
                              ? SizedBox(
                                  width: 16.r,
                                  height: 16.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  'إلغاء',
                                  style: AppTextStyles.style(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                    color: AppColors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverAvatar(RequestDriver driver, ThemeData theme) {
    final isFemale = driver.isFemale;
    final color =
        isFemale ? AppColors.femalePink : theme.colorScheme.primary;
    final initials =
        driver.name.isNotEmpty ? driver.name[0] : '?';

    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12)),
      child: driver.photoUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: driver.photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Center(
                  child: Text(initials,
                      style: AppTextStyles.style(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ),
            )
          : Center(
              child: Text(initials,
                  style: AppTextStyles.style(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 13.r,
            color: isDark ? AppColors.grey500 : AppColors.grey400),
        SizedBox(width: 6.w),
        Text(
          '$label: ',
          style: AppTextStyles.style(
            fontSize: 12.sp,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.style(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.grey200 : AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw.split('T').first);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
