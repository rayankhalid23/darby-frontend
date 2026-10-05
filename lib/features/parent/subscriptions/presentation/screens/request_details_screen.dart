import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../logic/requests_cubit/requests_cubit.dart';
import '../../data/models/request_model.dart';

class RequestDetailsScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailsScreen({super.key, required this.request});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RequestsCubit>().fetchRequestDetail(widget.request.id);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
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

  SnackBar _snackBar(String msg, Color bg) => SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(msg,
              style: AppTextStyles.style(
                  color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      );

  void _showCancelDialog(BuildContext context, RequestModel req) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          title: Text(
            'تأكيد إلغاء الطلب',
            style: AppTextStyles.style(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          content: Text(
            'هل أنت متأكد من إلغاء طلب الاشتراك هذا؟',
            style: AppTextStyles.style(
              fontSize: 13.sp,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
              height: 1.5,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isDark
                              ? AppColors.grey700
                              : AppColors.grey300),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      'تراجع',
                      style: AppTextStyles.style(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.grey300
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<RequestsCubit>().cancelRequest(req.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      'نعم، إلغاء',
                      style: AppTextStyles.style(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تفاصيل الطلب',
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
        ),
        body: BlocConsumer<RequestsCubit, RequestsState>(
          listener: (context, state) {
            if (state is RequestsActionSuccess) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(_snackBar(state.message, AppColors.success));
              Navigator.of(context).pop(true);
            } else if (state is RequestsActionError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(_snackBar(state.message, AppColors.error));
            }
          },
          builder: (context, state) {
            // نستخدم بيانات التفاصيل إذا تحمّلت، وإلا نعود للـ widget.request
            RequestModel req = widget.request;
            if (state is RequestDetailLoaded) req = state.request;

            final isPending = req.status.toLowerCase() == 'pending';
            final isCancelling = state is RequestsActionLoading;

            if (state is RequestDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RequestDetailError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 64.r, color: AppColors.error),
                    SizedBox(height: 12.h),
                    Text(
                      state.message,
                      style: AppTextStyles.style(
                          fontSize: 14.sp,
                          color: isDark ? AppColors.white : AppColors.textDark),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => context
                          .read<RequestsCubit>()
                          .fetchRequestDetail(widget.request.id),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── بيانات السائق ──
                      _buildDriverCard(req, theme, isDark),
                      SizedBox(height: 14.h),

                      // ── تفاصيل الاشتراك المشتركة ──
                      _buildSubscriptionCard(req, theme, isDark),
                      SizedBox(height: 14.h),

                      // ── عنوان المنزل ──
                      if (req.homeAddress != null) ...[
                        _buildHomeCard(req, theme, isDark),
                        SizedBox(height: 14.h),
                      ],

                      // ── التسعير الإجمالي ──
                      if (req.pricing != null) ...[
                        _buildPricingCard(req.pricing!, theme, isDark),
                        SizedBox(height: 14.h),
                      ],

                      // ── الأطفال ──
                      _sectionTitle('الأطفال (${req.children.length})',
                          Icons.child_care_rounded, isDark),
                      SizedBox(height: 8.h),
                      ...req.children.map((c) =>
                          _buildChildCard(c, theme, isDark)),

                      // ── الملاحظات ──
                      if (req.notes != null &&
                          req.notes!.trim().isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        _buildNotesCard(req.notes!, theme, isDark),
                        SizedBox(height: 14.h),
                      ],
                    ],
                  ),
                ),

                // ── زر الإلغاء ثابت في الأسفل ──
                if (isPending)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? AppColors.grey800
                                : AppColors.grey200,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isCancelling
                              ? null
                              : () => _showCancelDialog(context, req),
                          icon: isCancelling
                              ? SizedBox(
                                  width: 16.r,
                                  height: 16.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Icon(Icons.cancel_outlined, size: 18.r),
                          label: Text(
                            isCancelling ? 'جارٍ الإلغاء...' : 'إلغاء الطلب',
                            style: AppTextStyles.style(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: AppColors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── السائق ──
  Widget _buildDriverCard(RequestModel req, ThemeData theme, bool isDark) {
    final driver = req.driver;
    final isFemale = driver.isFemale;
    final color =
        isFemale ? AppColors.femalePink : theme.colorScheme.primary;
    final initials = driver.name.isNotEmpty ? driver.name[0] : '?';

    return _cardWithTitle(
      theme: theme,
      isDark: isDark,
      icon: Icons.drive_eta_rounded,
      title: 'السائق',
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: driver.photoUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: driver.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Center(
                        child: Text(initials,
                            style: AppTextStyles.style(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ),
                    ),
                  )
                : Center(
                    child: Text(initials,
                        style: AppTextStyles.style(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
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
                            size: 13.r, color: theme.colorScheme.primary),
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
          if (driver.vehicle != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (driver.vehicle!.hasAc)
                  _badge('❄️ مكيف', Colors.blue.withValues(alpha: 0.1),
                      Colors.blue),
                if (driver.vehicle!.plateNumber != null) ...[
                  SizedBox(height: 4.h),
                  _badge(
                    driver.vehicle!.plateNumber!,
                    isDark ? AppColors.grey800 : AppColors.grey100,
                    isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ],
                if (driver.vehicle!.capacity != null) ...[
                  SizedBox(height: 4.h),
                  _badge(
                    '${driver.vehicle!.capacity} مقعد',
                    isDark ? AppColors.grey800 : AppColors.grey100,
                    isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ── الاشتراك المشترك ──
  Widget _buildSubscriptionCard(
      RequestModel req, ThemeData theme, bool isDark) {
    final sub = req.subscription;
    return _cardWithTitle(
      theme: theme,
      isDark: isDark,
      icon: Icons.receipt_long_rounded,
      title: 'تفاصيل الاشتراك',
      child: Column(
        children: [
          _row('اتجاه الرحلة', sub.directionDisplayLabel, isDark),
          _row('تاريخ البداية', _formatDate(sub.startDate), isDark),
          if (sub.endDate != null)
            _row('تاريخ الانتهاء', _formatDate(sub.endDate), isDark),
          _row('أيام العمل', '${sub.workingDaysCount} يوم', isDark),
          _row('الحالة', req.statusDisplayLabel, isDark,
              valueColor: _statusColor(req.status)),
        ],
      ),
    );
  }

  // ── المنزل ──
  Widget _buildHomeCard(RequestModel req, ThemeData theme, bool isDark) {
    final home = req.homeAddress!;
    return _cardWithTitle(
      theme: theme,
      isDark: isDark,
      icon: Icons.home_rounded,
      title: 'عنوان المنزل',
      child: Column(
        children: [
          if (home.label != null) _row('العنوان', home.label!, isDark),
          if (home.lat != null && home.lng != null)
            _row(
              'الإحداثيات',
              '${home.lat!.toStringAsFixed(4)}, ${home.lng!.toStringAsFixed(4)}',
              isDark,
            ),
        ],
      ),
    );
  }

  // ── التسعير الإجمالي ──
  Widget _buildPricingCard(
      RequestRootPricing pricing, ThemeData theme, bool isDark) {
    return _cardWithTitle(
      theme: theme,
      isDark: isDark,
      icon: Icons.attach_money_rounded,
      title: 'ملخص التسعير',
      child: Column(
        children: [
          if (pricing.hasDiscount)
            _row('السعر قبل الخصم', pricing.formattedTotal, isDark,
                valueStrikethrough: true),
          if (pricing.hasDiscount)
            _row('مبلغ الخصم', '-${pricing.formattedDiscount}', isDark,
                valueColor: AppColors.success),
          _row('الإجمالي', pricing.formattedAfterDiscount, isDark,
              valueBold: true, valueColor: AppColors.success, largeFontSize: true),
        ],
      ),
    );
  }

  // ── كرت الطفل ──
  Widget _buildChildCard(
      RequestChild child, ThemeData theme, bool isDark) {
    final isFemale = child.isFemale;
    final avatarColor =
        isFemale ? AppColors.femalePink : theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: avatarColor.withValues(alpha: 0.3)),
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
          // رأس الكرت
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
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarColor.withValues(alpha: 0.15),
                  ),
                  child: child.photoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: child.photoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Center(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                if (child.age != null)
                  Text(
                    '${child.age} سنة',
                    style: AppTextStyles.style(
                      fontSize: 11.sp,
                      color:
                          isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
                  ),
              ],
            ),
          ),

          // تفاصيل الطفل
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                _row('المدرسة', child.school.name, isDark),
                _row('فترة الطفل', child.timingDisplayLabel, isDark),
                _row('وقت الاستلام', _formatTime(child.pickupTime), isDark),
                _row('وقت التسليم', _formatTime(child.dropoffTime), isDark),
                if (child.distanceKm != null)
                  _row('المسافة',
                      '${child.distanceKm!.toStringAsFixed(1)} كم', isDark),
                if (child.medicalNotes != null &&
                    child.medicalNotes!.trim().isNotEmpty &&
                    child.medicalNotes != 'لا يوجد')
                  _row('ملاحظات طبية', child.medicalNotes!, isDark,
                      valueColor: AppColors.warning),

                // التسعير الخاص بالطفل
                if (child.pricing != null) ...[
                  Divider(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    height: 20.h,
                  ),
                  if (child.pricing!.hasDiscount)
                    _row(
                      'السعر قبل الخصم',
                      child.pricing!.formattedPriceBeforeDiscount,
                      isDark,
                      valueStrikethrough: true,
                    ),
                  if (child.pricing!.hasDiscount)
                    _row(
                      'الخصم',
                      '${child.pricing!.discountPercentage.toStringAsFixed(0)}%',
                      isDark,
                      valueColor: AppColors.success,
                    ),
                  _row(
                    'السعر بعد الخصم',
                    child.pricing!.formattedPriceAfterDiscount,
                    isDark,
                    valueBold: true,
                    valueColor: AppColors.success,
                    largeFontSize: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes, ThemeData theme, bool isDark) {
    return _cardWithTitle(
      theme: theme,
      isDark: isDark,
      icon: Icons.note_alt_rounded,
      title: 'ملاحظات',
      child: Text(
        notes,
        style: AppTextStyles.style(
          fontSize: 13.sp,
          height: 1.5,
          color: isDark ? AppColors.grey300 : AppColors.grey700,
        ),
      ),
    );
  }

  // ── Helpers ──
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return AppColors.grey500;
      default:
        return AppColors.primary;
    }
  }

  Widget _sectionTitle(String title, IconData icon, bool isDark) {
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

  Widget _badge(String label, Color bg, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8.r)),
      child: Text(label,
          style: AppTextStyles.style(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _row(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
    bool valueBold = false,
    bool valueStrikethrough = false,
    bool largeFontSize = false,
  }) {
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
                fontSize: largeFontSize ? 15.sp : 13.sp,
                fontWeight:
                    valueBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ??
                    (isDark ? AppColors.grey200 : AppColors.textDark),
                decoration: valueStrikethrough
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWithTitle({
    required ThemeData theme,
    required bool isDark,
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
            color: isDark ? AppColors.grey800 : AppColors.grey200),
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
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.1),
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
                    color:
                        isDark ? AppColors.white : AppColors.textDark,
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
}
