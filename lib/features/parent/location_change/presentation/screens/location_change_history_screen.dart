import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/di/dependency_injection.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/theme_context.dart';
import '../../data/models/location_change_request_model.dart';
import '../../logic/cubit/location_change_cubit.dart';

class LocationChangeHistoryScreen extends StatefulWidget {
  const LocationChangeHistoryScreen({super.key});

  @override
  State<LocationChangeHistoryScreen> createState() =>
      _LocationChangeHistoryScreenState();
}

class _LocationChangeHistoryScreenState
    extends State<LocationChangeHistoryScreen> {
  late LocationChangeCubit _cubit;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LocationChangeCubit>()..fetchHistory(status: _selectedStatusFilter);
  }

  void _onTabChanged(String status) {
    setState(() => _selectedStatusFilter = status);
    _cubit.fetchHistory(status: status);
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
              'سجل طلبات تغيير الموقع',
              style: AppTextStyles.style(
                fontSize: 16.5.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Filter Tabs ──
              _buildFilterTabs(context, isDark),

              // ── Request List ──
              Expanded(
                child: BlocConsumer<LocationChangeCubit, LocationChangeState>(
                  listener: (context, state) {
                    if (state is LocationChangeHistoryLoaded &&
                        state.actionMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.actionMessage!),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      );
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
                                  fontSize: 13.sp, color: context.textMuted),
                            ),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: () =>
                                  _cubit.fetchHistory(status: _selectedStatusFilter),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is LocationChangeHistoryLoaded) {
                      final requests = state.requests;

                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off_rounded,
                                size: 54.sp,
                                color:
                                    isDark ? AppColors.grey700 : AppColors.grey400,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'لا توجد طلبات تغيير موقع حالياً',
                                style: AppTextStyles.style(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            _cubit.fetchHistory(status: _selectedStatusFilter),
                        child: ListView.separated(
                          padding: EdgeInsets.all(16.w),
                          itemCount: requests.length,
                          separatorBuilder: (_, _) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final item = requests[index];
                            return _buildRequestItemCard(
                                context, item, state.isCancelling, isDark);
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'الكل'},
      {'key': 'pending', 'label': 'المعلقة'},
      {'key': 'approved', 'label': 'المقبولة'},
      {'key': 'rejected', 'label': 'المرفوضة'},
      {'key': 'cancelled', 'label': 'الملغاة'},
    ];

    return Container(
      height: 44.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, idx) {
          final filter = filters[idx];
          final isSelected = _selectedStatusFilter == filter['key'];

          return ChoiceChip(
            label: Text(
              filter['label']!,
              style: AppTextStyles.style(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => _onTabChanged(filter['key']!),
          );
        },
      ),
    );
  }

  Widget _buildRequestItemCard(
    BuildContext context,
    LocationChangeRequestModel item,
    bool isCancelling,
    bool isDark,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (item.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'مقبول وتم التطبيق';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = context.errorColor;
        statusText = 'مرفوض من السائق';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
        statusColor = AppColors.grey500;
        statusText = 'ملغي';
        statusIcon = Icons.remove_circle_outline_rounded;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'قيد انتظار رد السائق';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final pointTypeText =
        item.pointType == 'pickup' ? 'مكان الاستلام' : 'مكان التسليم';

    final childrenNames = item.children.map((c) => c.name).join('، ');

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
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
              Expanded(
                child: Text(
                  childrenNames.isNotEmpty ? childrenNames : 'الأطفال المعنيون',
                  style: AppTextStyles.style(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13.sp),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: AppTextStyles.style(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          if (item.driverName != null && item.driverName!.isNotEmpty)
            Text(
              'السائق: ${item.driverName}',
              style: AppTextStyles.style(
                fontSize: 12.sp,
                color: context.textMuted,
              ),
            ),
          Divider(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التاريخ والتوع:',
                style: AppTextStyles.style(
                    fontSize: 11.5.sp, color: context.textMuted),
              ),
              Text(
                '${item.changeDate} • $pointTypeText',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الموقع الجديد:',
                style: AppTextStyles.style(
                    fontSize: 11.5.sp, color: context.textMuted),
              ),
              Text(
                item.newLocation?.label.isNotEmpty == true
                    ? item.newLocation!.label
                    : 'موقع محدد',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الزيادة والرسوم:',
                style: AppTextStyles.style(
                    fontSize: 11.5.sp, color: context.textMuted),
              ),
              Text(
                '${item.distanceKm.toStringAsFixed(1)} كم • ${item.feeAmount} ${item.currency}',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),

          // ── If Approved: Show Informative Note ──
          if (item.isApproved) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.green, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'تم تثبيت التغيير وموافقة السائق.. في حال رغبتك بالتراجع يرجى التواصل مع السائق.',
                      style: AppTextStyles.style(
                        fontSize: 11.sp,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── If Pending: Show Cancel Request Button ──
          if (item.isPending) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 38.h,
              child: OutlinedButton.icon(
                onPressed: isCancelling ? null : () => _cubit.cancelRequest(item.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.errorColor,
                  side: BorderSide(color: context.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.cancel_outlined, size: 16.sp),
                label: Text(
                  'إلغاء الطلب المعلق',
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: context.errorColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
