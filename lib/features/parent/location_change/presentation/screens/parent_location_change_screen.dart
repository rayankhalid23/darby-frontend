import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/di/dependency_injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/theme_context.dart';
import '../../logic/cubit/location_change_cubit.dart';
import '../widgets/address_selection_bottom_sheet.dart';
import 'location_change_history_screen.dart';
import 'package:kids_transport/features/parent/addresses/presentation/widgets/add_address_sheet.dart';

class ParentLocationChangeScreen extends StatefulWidget {
  const ParentLocationChangeScreen({super.key});

  @override
  State<ParentLocationChangeScreen> createState() =>
      _ParentLocationChangeScreenState();
}

class _ParentLocationChangeScreenState
    extends State<ParentLocationChangeScreen> {
  late LocationChangeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LocationChangeCubit>()..fetchOptions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return BlocProvider.value(
      value: _cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'تغيير موقع الرحلة',
              style: AppTextStyles.style(
                fontSize: 16.5.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          body: BlocConsumer<LocationChangeCubit, LocationChangeState>(
            listener: (context, state) {
              if (state is LocationChangeOptionsLoaded) {
                if (state.submitSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          state.submitMessage ?? 'تم إرسال الطلب بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LocationChangeHistoryScreen(),
                    ),
                  );
                } else if (state.error != null && state.error!.isNotEmpty) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: context.errorColor,
                    ),
                  );
                  _cubit.clearError();
                }
              }
            },
            builder: (context, state) {
              if (state is LocationChangeLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is LocationChangeError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48.sp, color: context.errorColor),
                      SizedBox(height: 12.h),
                      Text(
                        state.message,
                        style: AppTextStyles.style(
                            fontSize: 13.5.sp, color: context.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => _cubit.fetchOptions(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (state is LocationChangeOptionsLoaded) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 1. اختيار الأبناء (نمط ميسنجر - Messenger Horizontal Scroll) ──
                      _buildChildrenMessengerSection(context, state, isDark),
                      SizedBox(height: 16.h),

                      // ── 2. التاريخ ونوع التغيير ──
                      _buildDateAndTypeCard(context, state, isDark),
                      SizedBox(height: 16.h),

                      // ── 3. الموقع الجديد المطلوب ──
                      _buildAddressCard(context, state, isDark),
                      SizedBox(height: 16.h),

                      // ── 4. معاينة التكلفة والإرسال ──
                      _buildPreviewAndSubmitCard(context, state, isDark),
                      SizedBox(height: 24.h),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ── Messenger-Style Children Horizontal View ──
  Widget _buildChildrenMessengerSection(
    BuildContext context,
    LocationChangeOptionsLoaded state,
    bool isDark,
  ) {
    final children = state.options.children;
    final selectedIds = state.selectedChildIds;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
                'اختر الأطفال',
                style: AppTextStyles.style(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  final allSelected =
                      children.isNotEmpty && selectedIds.length == children.length;
                  _cubit.selectAllChildren(!allSelected);
                },
                child: Text(
                  selectedIds.length == children.length
                      ? 'إلغاء الكل'
                      : 'تحديد الكل',
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (children.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Center(
                child: Text(
                  'لا يوجد أطفال مسجلون حالياً',
                  style: AppTextStyles.style(
                      fontSize: 12.5.sp, color: context.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 110.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                separatorBuilder: (_, _) => SizedBox(width: 14.w),
                itemBuilder: (context, index) {
                  final child = children[index];
                  final isSelected = selectedIds.contains(child.id);

                  return InkWell(
                    onTap: () => _cubit.toggleChildSelection(child.id),
                    borderRadius: BorderRadius.circular(40.r),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2.5.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  width: 2.2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26.r,
                                backgroundColor: isSelected
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppColors.grey800
                                        : AppColors.grey200),
                                backgroundImage: (child.photoUrl != null &&
                                        child.photoUrl!.isNotEmpty)
                                    ? NetworkImage(child.photoUrl!)
                                    : null,
                                child: (child.photoUrl == null ||
                                        child.photoUrl!.isEmpty)
                                    ? Text(
                                        child.name.isNotEmpty
                                            ? child.name.characters.first
                                            : 'طفل',
                                        style: AppTextStyles.style(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : context.textPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  padding: EdgeInsets.all(2.r),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 12.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: 62.w,
                          child: Text(
                            child.name.split(' ').first,
                            style: AppTextStyles.style(
                              fontSize: 11.5.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : context.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Date & Type Section ──
  Widget _buildDateAndTypeCard(
    BuildContext context,
    LocationChangeOptionsLoaded state,
    bool isDark,
  ) {
    final formattedDate =
        "${state.changeDate.year}/${state.changeDate.month}/${state.changeDate.day}";

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
                'تاريخ التغيير',
                style: AppTextStyles.style(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  DateTime initial = state.changeDate;
                  if (initial.isBefore(today)) {
                    initial = today;
                  }

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    _cubit.setChangeDate(picked);
                  }
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 16.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        formattedDate,
                        style: AppTextStyles.style(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'نوع النقطة',
            style: AppTextStyles.style(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      'مكان الاستلام (Pickup)',
                      style: AppTextStyles.style(
                        fontSize: 12.sp,
                        fontWeight: state.pointType == 'pickup'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  selected: state.pointType == 'pickup',
                  onSelected: (selected) {
                    if (selected) _cubit.setPointType('pickup');
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      'مكان التسليم (Dropoff)',
                      style: AppTextStyles.style(
                        fontSize: 12.sp,
                        fontWeight: state.pointType == 'dropoff'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  selected: state.pointType == 'dropoff',
                  onSelected: (selected) {
                    if (selected) _cubit.setPointType('dropoff');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Address Card ──
  Widget _buildAddressCard(
    BuildContext context,
    LocationChangeOptionsLoaded state,
    bool isDark,
  ) {
    final selectedAddress = state.selectedAddress;
    final hasCustom = state.customLat != null && state.customLng != null;

    String displayLabel = 'لم يتم اختيار عنوان بعد';
    if (selectedAddress != null) {
      displayLabel = selectedAddress.label.isNotEmpty
          ? selectedAddress.label
          : 'عنوان محفوظ';
    } else if (hasCustom) {
      displayLabel = state.customLabel?.isNotEmpty == true
          ? state.customLabel!
          : 'موقع محدد على الخريطة';
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
                'الموقع الجديد',
                style: AppTextStyles.style(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final address = await AddressSelectionBottomSheet.show(
                    context,
                    addresses: state.options.addresses,
                    selectedAddress: state.selectedAddress,
                    onAddNewAddress: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => AddAddressSheet(
                          onSave: (newAddr) async {
                            _cubit.setCustomLocation(
                              newAddr.latitude,
                              newAddr.longitude,
                              newAddr.title,
                            );
                            return null;
                          },
                        ),
                      );
                    },
                  );
                  if (address != null) {
                    _cubit.selectAddress(address);
                  }
                },
                child: Text(
                  'تغيير العنوان',
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.grey800.withValues(alpha: 0.4)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    displayLabel,
                    style: AppTextStyles.style(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview & Submit Card ──
  Widget _buildPreviewAndSubmitCard(
    BuildContext context,
    LocationChangeOptionsLoaded state,
    bool isDark,
  ) {
    final preview = state.previewData;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
                'التكلفة الإضافية',
                style: AppTextStyles.style(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              if (preview == null)
                TextButton(
                  onPressed: state.isPreviewLoading
                      ? null
                      : () => _cubit.calculatePreview(),
                  child: Text(
                    state.isPreviewLoading ? 'جاري المعاينة...' : 'حساب المعاينة',
                    style: AppTextStyles.style(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          if (preview != null) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: preview.groupedRequests.length,
              itemBuilder: (context, idx) {
                final group = preview.groupedRequests[idx];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السائق: ${group.driverName} (${group.extraDistanceKm.toStringAsFixed(1)} كم)',
                        style: AppTextStyles.style(
                          fontSize: 12.sp,
                          color: context.textMuted,
                        ),
                      ),
                      Text(
                        '${group.feeAmount} ${preview.currency}',
                        style: AppTextStyles.style(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Divider(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي التكلفة المطلوبة:',
                  style: AppTextStyles.style(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${preview.totalFee} ${preview.currency}',
                  style: AppTextStyles.style(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: state.isSubmitting || state.selectedChildIds.isEmpty
                  ? null
                  : () => _cubit.submitRequests(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: state.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'إرسال طلب التغيير للسائق',
                      style: AppTextStyles.style(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
