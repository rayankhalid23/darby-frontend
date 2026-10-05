import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/theme_context.dart';
import '../../data/models/location_change_options_model.dart';

class AddressSelectionBottomSheet extends StatelessWidget {
  final List<SavedAddressModel> addresses;
  final SavedAddressModel? selectedAddress;
  final ValueChanged<SavedAddressModel> onAddressSelected;
  final VoidCallback? onAddNewAddress;

  const AddressSelectionBottomSheet({
    super.key,
    required this.addresses,
    this.selectedAddress,
    required this.onAddressSelected,
    this.onAddNewAddress,
  });

  static Future<SavedAddressModel?> show(
    BuildContext context, {
    required List<SavedAddressModel> addresses,
    SavedAddressModel? selectedAddress,
    VoidCallback? onAddNewAddress,
  }) {
    return showModalBottomSheet<SavedAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionBottomSheet(
        addresses: addresses,
        selectedAddress: selectedAddress,
        onAddressSelected: (address) => Navigator.pop(context, address),
        onAddNewAddress: onAddNewAddress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? context.cardSurface : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey700 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختر مكان التوصيل/الاستلام',
                  style: AppTextStyles.style(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (addresses.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text(
                    'لا توجد عناوين محفوظة حالياً',
                    style: AppTextStyles.style(
                      fontSize: 14.sp,
                      color: context.textMuted,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final item = addresses[index];
                    final isSelected = selectedAddress?.id == item.id;

                    return InkWell(
                      onTap: () => onAddressSelected(item),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : (isDark ? context.cardSurface : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : (isDark ? AppColors.grey800 : AppColors.grey200),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : (isDark ? AppColors.grey800 : AppColors.grey200),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 20.sp,
                                color: isSelected ? Colors.white : context.textMuted,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label.isNotEmpty ? item.label : 'عنوان محفوظ',
                                    style: AppTextStyles.style(
                                      fontSize: 14.sp,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'الإحداثيات: ${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}',
                                    style: AppTextStyles.style(
                                      fontSize: 11.sp,
                                      color: context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 22.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (onAddNewAddress != null) {
                  onAddNewAddress!();
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(
                'إضافة عنوان جديد على الخريطة',
                style: AppTextStyles.style(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}
