import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../data/models/complaint_model.dart';
import 'complaint_status_badge.dart';

class ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  String _fmtDate(String raw) {
    try {
      if (raw.isEmpty) return '—';
      final parts = raw.split('T');
      final dateStr = parts.first;
      final ymd = dateStr.split('-');
      if (ymd.length == 3) {
        return '${ymd[0]}/${ymd[1]}/${ymd[2]}';
      }
      return dateStr;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14.r,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            backgroundImage: (complaint.driverAvatar != null && complaint.driverAvatar!.isNotEmpty)
                                ? NetworkImage(complaint.driverAvatar!)
                                : null,
                            child: (complaint.driverAvatar == null || complaint.driverAvatar!.isEmpty)
                                ? Icon(Icons.person_rounded, size: 14.r, color: theme.colorScheme.primary)
                                : null,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              complaint.driverName ?? 'الكابتن',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.style(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ComplaintStatusBadge(status: complaint.status),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.directions_bus_outlined, size: 14.r, color: isDark ? AppColors.grey400 : AppColors.textMuted),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        complaint.tripTitle ??
                            ((complaint.tripId != null && complaint.tripId! > 0)
                                ? 'رحلة #${complaint.tripId}'
                                : 'شكوى عامة (ليست مرتبطة برحلة)'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.style(
                          fontSize: 11.5.sp,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.calendar_today_outlined, size: 12.r, color: isDark ? AppColors.grey400 : AppColors.textMuted),
                    SizedBox(width: 4.w),
                    Text(
                      _fmtDate(complaint.createdAt),
                      style: AppTextStyles.style(
                        fontSize: 10.5.sp,
                        color: isDark ? AppColors.grey400 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  complaint.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.grey400 : AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
                if (complaint.isPending && (onEdit != null || onDelete != null)) ...[
                  SizedBox(height: 12.h),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.grey800 : AppColors.grey200,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: Icon(Icons.edit_outlined, size: 14.r, color: theme.colorScheme.primary),
                          label: Text(
                            'تعديل',
                            style: AppTextStyles.style(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (onEdit != null && onDelete != null) SizedBox(width: 8.w),
                      if (onDelete != null)
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: Icon(Icons.delete_outline_rounded, size: 14.r, color: AppColors.error),
                          label: Text(
                            'حذف',
                            style: AppTextStyles.style(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
