import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../data/models/active_subscription_model.dart';

class SubscriptionCard extends StatelessWidget {
  final ActiveSubscriptionModel subscription;
  final VoidCallback onDetailsPressed;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onDetailsPressed,
  });

  Color _statusColor(BuildContext context) {
    switch (subscription.status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return AppColors.success;
      case 'pending_start':
        return Theme.of(context).colorScheme.primary;
      case 'completed':
        return AppColors.grey500;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final driver = subscription.driver;
    final sub = subscription.subscription;
    final statusColor = _statusColor(context);

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
            width: double.infinity,
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
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  subscription.statusDisplayLabel,
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  sub.directionDisplayLabel,
                  style: AppTextStyles.style(
                    fontSize: 11.sp,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
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
                            style: AppTextStyles.style(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.white : AppColors.textDark,
                            ),
                          ),
                          if (driver.phone != null)
                            Text(
                              driver.phone!,
                              style: AppTextStyles.style(
                                fontSize: 12.sp,
                                color: isDark ? AppColors.grey400 : AppColors.grey600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // مكيف + لوحة
                    if (driver.vehicle != null) ...[
                      if (driver.vehicle!.hasAc)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.ac_unit_rounded, size: 10.r, color: Colors.blue),
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
                  ],
                ),

                SizedBox(height: 12.h),
                Divider(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  height: 1,
                ),
                SizedBox(height: 12.h),

                // ── معلومات الاشتراك المشتركة ──
                _infoRow(
                  icon: Icons.calendar_month_rounded,
                  label: sub.typeDisplayLabel,
                  value:
                      '${_formatDate(sub.startDate)} — ${_formatDate(sub.endDate ?? '')}',
                  isDark: isDark,
                  theme: theme,
                ),
                SizedBox(height: 8.h),
                _infoRow(
                  icon: Icons.sync_alt_rounded,
                  label: 'الرحلة',
                  value: sub.directionDisplayLabel,
                  isDark: isDark,
                  theme: theme,
                ),

                SizedBox(height: 12.h),
                Divider(
                  color: isDark ? AppColors.grey800 : AppColors.grey100,
                  height: 1,
                ),
                SizedBox(height: 12.h),

                // ── قائمة الأطفال ──
                ...subscription.children.map((child) =>
                    _childRow(child, isDark, theme)),

                SizedBox(height: 12.h),

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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _childRow(ActiveChild child, bool isDark, ThemeData theme) {
    final isFemale = child.isFemale;
    final avatarColor =
        isFemale ? AppColors.femalePink : theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          // أفاتار الطفل
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withValues(alpha: 0.12),
            ),
            child: child.photoUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: child.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Center(
                        child: Text(child.avatarInitials,
                            style: AppTextStyles.style(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: avatarColor)),
                      ),
                    ),
                  )
                : Center(
                    child: Text(child.avatarInitials,
                        style: AppTextStyles.style(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: avatarColor)),
                  ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: AppTextStyles.style(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.school_rounded,
                        size: 11.r,
                        color: isDark ? AppColors.grey500 : AppColors.grey400),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        child.school.name,
                        style: AppTextStyles.style(
                          fontSize: 11.sp,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // سعر الطفل
          if (child.pricing != null)
            Text(
              child.pricing!.formattedPriceAfterDiscount,
              style: AppTextStyles.style(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }

  Widget _driverAvatar(ActiveDriver driver, ThemeData theme) {
    final color = driver.isFemale ? AppColors.femalePink : theme.colorScheme.primary;
    final initials = driver.name.isNotEmpty ? driver.name[0] : '?';

    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: driver.avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: driver.avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Center(
                    child: Text(initials,
                        style: AppTextStyles.style(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: color))),
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
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 14.r,
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
