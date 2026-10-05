import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';

class ComplaintStatusBadge extends StatelessWidget {
  final String status;

  const ComplaintStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final st = status.toLowerCase();
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (st) {
      case 'pending':
        bgColor = AppColors.pending.withValues(alpha: 0.12);
        textColor = AppColors.pending;
        label = 'قيد الانتظار';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'completed':
      case 'action_taken':
      case 'resolved':
        bgColor = AppColors.success.withValues(alpha: 0.12);
        textColor = AppColors.success;
        label = 'تمت المعالجة';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'dismissed':
      case 'rejected':
        bgColor = AppColors.error.withValues(alpha: 0.12);
        textColor = AppColors.error;
        label = 'مغلقة';
        icon = Icons.cancel_outlined;
        break;
      case 'closed':
        bgColor = AppColors.grey500.withValues(alpha: 0.12);
        textColor = AppColors.grey600;
        label = 'مغلقة';
        icon = Icons.lock_outline_rounded;
        break;
      default:
        bgColor = AppColors.info.withValues(alpha: 0.12);
        textColor = AppColors.info;
        label = status;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.r, color: textColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.style(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
