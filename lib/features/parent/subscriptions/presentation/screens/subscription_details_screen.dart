import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../logic/subscriptions_cubit/subscriptions_cubit.dart';
import '../../data/models/active_subscription_model.dart';
import '../../data/models/request_model.dart'
    show RequestChildPricing;

/// شاشة تفاصيل الاشتراك النشط — لا تستدعي API جديد
/// تعرض البيانات مباشرة من [ActiveSubscriptionModel] المُمرَّر إليها
/// شاشة تفاصيل الاشتراك النشط — لا تستدعي API تفاصيل مخصص
/// تدعم التمرير المباشر لـ [ActiveSubscriptionModel] أو تحميله عبر [subscriptionId]
class SubscriptionDetailsScreen extends StatefulWidget {
  final ActiveSubscriptionModel? subscription;
  final int? subscriptionId;

  const SubscriptionDetailsScreen({
    super.key,
    this.subscription,
    this.subscriptionId,
  }) : assert(subscription != null || subscriptionId != null,
            'Must provide either subscription or subscriptionId');

  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  ActiveSubscriptionModel? _subscription;

  ActiveSubscriptionModel get subscription =>
      _subscription ?? widget.subscription!;

  @override
  void initState() {
    super.initState();
    _subscription = widget.subscription;
    if (_subscription == null && widget.subscriptionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SubscriptionsCubit>().fetchSubscriptions();
        }
      });
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'غير محدد';
    try {
      final dt = DateTime.parse(raw.split('T').first);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == 'null') {
      return 'غير محدد';
    }
    final clean = raw.trim();
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        final period = h >= 12 ? 'مساءً' : 'صباحًا';
        final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final hourStr = displayHour.toString().padLeft(2, '0');
        final minStr = m.toString().padLeft(2, '0');
        return '$hourStr:$minStr $period';
      }
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : const Color(0xFFF4F6FA),
        appBar: _buildAppBar(isDark, theme, context),
        body: BlocConsumer<SubscriptionsCubit, SubscriptionsState>(
          listener: (context, state) {
            if (state is SubscriptionsActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                _snackBar(state.message, AppColors.success),
              );
              Navigator.of(context).pop(true);
            } else if (state is SubscriptionsActionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                _snackBar(state.message, AppColors.error),
              );
            }
          },
          builder: (context, state) {
            if (_subscription == null) {
              if (state is SubscriptionsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is SubscriptionsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        style: AppTextStyles.style(
                          color: isDark ? AppColors.white : AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ElevatedButton(
                        onPressed: () => context
                            .read<SubscriptionsCubit>()
                            .fetchSubscriptions(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final list = state is SubscriptionsLoaded
                  ? state.subscriptions
                  : (state is SubscriptionsActionLoading
                      ? state.currentList
                      : (state is SubscriptionsActionSuccess
                          ? state.updatedList
                          : (state is SubscriptionsActionError
                              ? state.currentList
                              : <ActiveSubscriptionModel>[])));

              final found = list
                  .where((s) => s.id == widget.subscriptionId)
                  .firstOrNull;
              if (found != null) {
                _subscription = found;
              } else {
                return Center(
                  child: Text(
                    'لم يتم العثور على الاشتراك',
                    style: AppTextStyles.style(
                      color: isDark ? AppColors.white : AppColors.textDark,
                    ),
                  ),
                );
              }
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. بيانات السائق
                  _buildDriverCard(theme, isDark),
                  SizedBox(height: 14.h),

                  // 2. بيانات الاشتراك المشتركة
                  _buildSubscriptionInfoCard(theme, isDark),
                  SizedBox(height: 14.h),

                  // 3. مواعيد الرحلة (إن وجدت)
                  if (subscription.pickupTime != null ||
                      subscription.dropoffTime != null) ...[
                    _buildTimingCard(theme, isDark),
                    SizedBox(height: 14.h),
                  ],

                  // 4. عنوان المنزل
                  if (subscription.homeAddress != null) ...[
                    _buildHomeAddressCard(theme, isDark),
                    SizedBox(height: 14.h),
                  ],

                  // 5. كروت الأطفال (طفل أو أكثر)
                  _buildSectionTitle(
                      'الأطفال', Icons.child_care_rounded, isDark),
                  SizedBox(height: 8.h),
                  ...subscription.children.asMap().entries.map((entry) =>
                      _buildChildCard(context, entry.value, theme, isDark)),

                  // 6. الملاحظات
                  if (subscription.notes != null &&
                      subscription.notes!.trim().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    _buildNotesCard(theme, isDark),
                    SizedBox(height: 14.h),
                  ],

                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // AppBar
  // ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark, ThemeData theme, BuildContext context) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'تفاصيل الاشتراك',
        style: AppTextStyles.style(
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
          color: isDark ? AppColors.white : AppColors.textDark,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? AppColors.white : AppColors.textDark,
          size: 18.r,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // بيانات السائق
  // ───────────────────────────────────────────────────────────────
  Widget _buildDriverCard(ThemeData theme, bool isDark) {
    final driver = subscription.driver;
    final driverColor =
        driver.isFemale ? AppColors.femalePink : theme.colorScheme.primary;

    return _card(
      isDark: isDark,
      child: Row(
        children: [
          // أفاتار
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: driverColor.withValues(alpha: 0.12),
            ),
            child: driver.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driver.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _driverInitials(
                          driver.name, driverColor),
                    ),
                  )
                : _driverInitials(driver.name, driverColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: AppTextStyles.style(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                ),
                if (driver.phone != null) ...[
                  SizedBox(height: 4.h),
                  GestureDetector(
                    onLongPress: () =>
                        Clipboard.setData(ClipboardData(text: driver.phone!)),
                    child: Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 13.r,
                            color: theme.colorScheme.primary),
                        SizedBox(width: 4.w),
                        Text(
                          driver.phone!,
                          style: AppTextStyles.style(
                            fontSize: 13.sp,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // معلومات السيارة
          if (driver.vehicle != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (driver.vehicle!.hasAc)
                  _badge(
                    label: 'مكيف ❄️',
                    bg: Colors.blue.withValues(alpha: 0.1),
                    color: Colors.blue,
                  ),
                if (driver.vehicle!.plateNumber != null) ...[
                  SizedBox(height: 4.h),
                  _badge(
                    label: driver.vehicle!.plateNumber!,
                    bg: isDark
                        ? AppColors.grey800
                        : AppColors.grey100,
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // بيانات الاشتراك المشتركة
  // ───────────────────────────────────────────────────────────────
  Widget _buildSubscriptionInfoCard(ThemeData theme, bool isDark) {
    final sub = subscription.subscription;
    return _cardWithTitle(
      isDark: isDark,
      theme: theme,
      icon: Icons.receipt_long_rounded,
      title: 'تفاصيل الاشتراك',
      child: Column(
        children: [
          _detailRow('اتجاه الرحلة', sub.directionDisplayLabel, isDark),
          _detailRow('تاريخ البداية', _formatDate(sub.startDate), isDark),
          if (sub.endDate != null)
            _detailRow('تاريخ الانتهاء', _formatDate(sub.endDate), isDark),
          _detailRow('أيام العمل', '${sub.workingDaysCount} يوم', isDark),
          _detailRow('حالة الاشتراك',
              subscription.statusDisplayLabel, isDark,
              valueColor: _statusColor(subscription.status)),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // مواعيد الرحلة
  // ───────────────────────────────────────────────────────────────
  Widget _buildTimingCard(ThemeData theme, bool isDark) {
    return _cardWithTitle(
      isDark: isDark,
      theme: theme,
      icon: Icons.access_time_rounded,
      title: 'مواعيد الرحلة',
      child: Column(
        children: [
          if (subscription.pickupTime != null)
            _detailRow('وقت الاصطحاب',
                _formatTime(subscription.pickupTime), isDark),
          if (subscription.dropoffTime != null)
            _detailRow('وقت التوصيل',
                _formatTime(subscription.dropoffTime), isDark),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // عنوان المنزل
  // ───────────────────────────────────────────────────────────────
  Widget _buildHomeAddressCard(ThemeData theme, bool isDark) {
    final home = subscription.homeAddress!;
    return _cardWithTitle(
      isDark: isDark,
      theme: theme,
      icon: Icons.home_rounded,
      title: 'عنوان المنزل',
      child: Column(
        children: [
          if (home.label != null)
            _detailRow('العنوان', home.label!, isDark),
          if (home.lat != null && home.lng != null)
            _detailRow(
                'الإحداثيات', '${home.lat!.toStringAsFixed(4)}, ${home.lng!.toStringAsFixed(4)}', isDark),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // كرت الطفل
  // ───────────────────────────────────────────────────────────────
  Widget _buildChildCard(BuildContext context, ActiveChild child,
      ThemeData theme, bool isDark) {
    final isFemale = child.isFemale;
    final avatarColor = isFemale ? AppColors.femalePink : theme.colorScheme.primary;

    return BlocBuilder<SubscriptionsCubit, SubscriptionsState>(
      builder: (context, state) {

        return Container(
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: avatarColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black
                    .withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 10.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── رأس كرت الطفل ──
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(18.r),
                    topLeft: Radius.circular(18.r),
                  ),
                ),
                child: Row(
                  children: [
                    // أفاتار
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor.withValues(alpha: 0.15),
                      ),
                      child: child.photoUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: child.photoUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    Center(
                                  child: Text(child.avatarInitials,
                                      style: AppTextStyles.style(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          color: avatarColor)),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(child.avatarInitials,
                                  style: AppTextStyles.style(
                                      fontSize: 13.sp,
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? AppColors.white : AppColors.textDark,
                            ),
                          ),
                          if (child.gradeLabelDisplay.isNotEmpty)
                            Text(
                              child.gradeLabelDisplay,
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
                    // جنس + عمر
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (child.age != null)
                          Text(
                            '${child.age} سنة',
                            style: AppTextStyles.style(
                              fontSize: 11.sp,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                            ),
                          ),
                        SizedBox(height: 2.h),
                        Icon(
                          isFemale
                              ? Icons.face_4_rounded
                              : Icons.face_rounded,
                          size: 16.r,
                          color: avatarColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── تفاصيل الطفل ──
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  children: [
                    _detailRow('المدرسة', child.school.name, isDark),
                    _detailRow('الفترة', child.timingDisplayLabel, isDark),
                    _detailRow('وقت الاستلام', _formatTime(child.pickupTime), isDark),
                    _detailRow('وقت التسليم', _formatTime(child.dropoffTime), isDark),
                    if (child.distanceKm != null)
                      _detailRow('المسافة',
                          '${child.distanceKm!.toStringAsFixed(1)} كم', isDark),
                    if (child.hasMedicalNotes.isNotEmpty)
                      _detailRow('ملاحظات طبية', child.hasMedicalNotes, isDark,
                          valueColor: AppColors.warning),

                    // التسعير
                    if (child.pricing != null) ...[
                      Divider(
                        color: isDark ? AppColors.grey800 : AppColors.grey100,
                        height: 20.h,
                      ),
                      _buildChildPricing(child.pricing!, isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildPricing(RequestChildPricing pricing, bool isDark) {
    return Column(
      children: [
        if (pricing.hasDiscount)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السعر قبل الخصم',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
              Text(
                pricing.formattedPriceBeforeDiscount,
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  color: isDark ? AppColors.grey400 : AppColors.grey500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        if (pricing.hasDiscount) SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'السعر بعد الخصم',
              style: AppTextStyles.style(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textDark,
              ),
            ),
            Text(
              pricing.formattedPriceAfterDiscount,
              style: AppTextStyles.style(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        if (pricing.hasDiscount) ...[
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الخصم',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  color: AppColors.success,
                ),
              ),
              Text(
                '${pricing.discountPercentage.toStringAsFixed(0)}%  (-${pricing.formattedPriceAfterDiscount})',
                style: AppTextStyles.style(
                  fontSize: 12.sp,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────
  // الملاحظات
  // ───────────────────────────────────────────────────────────────
  Widget _buildNotesCard(ThemeData theme, bool isDark) {
    return _cardWithTitle(
      isDark: isDark,
      theme: theme,
      icon: Icons.note_alt_rounded,
      title: 'ملاحظات',
      child: Text(
        subscription.notes!,
        style: AppTextStyles.style(
          fontSize: 13.sp,
          height: 1.5,
          color: isDark ? AppColors.grey300 : AppColors.grey700,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────


  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return AppColors.success;
      case 'pending_start':
        return AppColors.primary;
      case 'completed':
        return AppColors.grey500;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }

  Widget _driverInitials(String name, Color color) => Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: AppTextStyles.style(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );

  Widget _badge(
      {required String label, required Color bg, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(label,
          style: AppTextStyles.style(
              fontSize: 10.sp, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 16.r,
            color: isDark ? AppColors.grey400 : AppColors.grey600),
        SizedBox(width: 6.w),
        Text(
          title,
          style: AppTextStyles.style(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: AppTextStyles.style(
                fontSize: 12.sp,
                color: isDark ? AppColors.grey500 : AppColors.grey500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.style(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: valueColor ??
                    (isDark ? AppColors.grey200 : AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardWithTitle({
    required bool isDark,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon,
                      size: 16.r, color: theme.colorScheme.primary),
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: AppTextStyles.style(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark ? AppColors.grey800 : AppColors.grey100,
            height: 1,
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: child,
          ),
        ],
      ),
    );
  }

  SnackBar _snackBar(String message, Color bg) {
    return SnackBar(
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(message,
            style: AppTextStyles.style(
                color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }
}
