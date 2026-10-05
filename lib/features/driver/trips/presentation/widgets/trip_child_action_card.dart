import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kids_transport/core/widgets/app_user_avatar.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/features/driver/trips/data/models/live_trip_child_item.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/trip_child_status_badge.dart';

/// بطاقة إجراء طفل واحد ضمن قائمة الرحلة الحية
class TripChildActionCard extends StatelessWidget {
  final LiveTripChildItem item;
  final bool isCurrent;
  final bool isPendingAction;
  final double? distanceMeters;

  /// false يعني إحداثيات المحطة الهدف غير متوفرة أصلاً من Backend (بيانات
  /// ناقصة) — حالة مختلفة عن "بعيد عن المحطة"، ويجب توضيحها للسائق بدل
  /// تعطيل زر التأكيد اليدوي بصمت.
  final bool hasTargetCoordinates;
  final bool isTripCompleted;
  final VoidCallback onManualConfirm;
  final VoidCallback? onScanQr;
  final VoidCallback onAbsent;
  final VoidCallback onSkip;
  final VoidCallback onDropoffFailed;
  final VoidCallback onDirectParentHandling;

  const TripChildActionCard({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.isPendingAction,
    required this.distanceMeters,
    required this.hasTargetCoordinates,
    this.isTripCompleted = false,
    required this.onManualConfirm,
    this.onScanQr,
    required this.onAbsent,
    required this.onSkip,
    required this.onDropoffFailed,
    required this.onDirectParentHandling,
  });

  int get _allowedRangeMeters => item.targetIsSchool ? 200 : 100;

  bool get _canConfirmManually {
    if (distanceMeters == null) return false;
    return distanceMeters! <= _allowedRangeMeters;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final resolved = item.isResolved;
    final address = item.isDropoffPhase ? item.dropoffAddress : item.pickupAddress;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.boxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppTheme.radius(16),
        border: AppTheme.border(
          color: isCurrent
              ? context.primaryColor
              : (isDark ? AppColors.grey700 : AppColors.grey300),
          width: isCurrent ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: AppTheme.boxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${item.sequenceOrder}',
                  style: AppTextStyles.style(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (item.photo != null && item.photo!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: AppUserAvatar.resolveUrl(item.photo)!,
                    httpHeaders: AppUserAvatar.imageHeaders,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(
                      item.isDropoffPhase ? Icons.school_rounded : Icons.home_rounded,
                      size: 18,
                      color: context.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(
                  item.isDropoffPhase ? Icons.school_rounded : Icons.home_rounded,
                  size: 18,
                  color: context.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.style(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TripChildStatusBadge(status: item.status, compact: true),
            ],
          ),

          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Text(
                address,
                style: AppTextStyles.style(fontSize: 12, color: context.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (item.eta != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: context.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'الوصول التقديري: ${item.eta}',
                    style: AppTextStyles.style(fontSize: 11, color: context.textMuted),
                  ),
                ],
              ),
            ),
          ],
          if (!resolved && !isTripCompleted) ...[
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (isPendingAction) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
      );
    }

    final manualLabel = item.isDropoffPhase ? 'تأكيد النزول' : 'تأكيد الصعود';
    final manualEnabled = _canConfirmManually;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: manualEnabled ? onManualConfirm : null,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(manualLabel, style: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.bold)),
            style: AppTheme.elevatedButtonStyle(
              backgroundColor: context.primaryColor,
              foregroundColor: AppColors.white,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        if (!manualEnabled) ...[
          const SizedBox(height: 6),
          Text(
            !hasTargetCoordinates
                ? 'لا تتوفر إحداثيات دقيقة لهذه المحطة.'
                : (distanceMeters == null
                    ? 'بانتظار تحديد موقعك الحالي...'
                    : 'أنت بعيد عن المحطة (${distanceMeters!.round()}م)، يرجى الاقتراب لتأكيد الوصول'),
            style: AppTextStyles.style(fontSize: 11, color: AppColors.pending),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (item.isPickupPhase) ...[
              _TextActionButton(label: 'لم يحضر', color: AppColors.error, onTap: onAbsent),
              const SizedBox(width: 12),
              _TextActionButton(label: 'تجاوز المحطة', color: AppColors.pending, onTap: onSkip),
            ],
            const Spacer(),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, size: 20, color: context.textMuted),
              onSelected: (value) {
                if (value == 'dropoff_failed') onDropoffFailed();
                if (value == 'direct_parent_handling') onDirectParentHandling();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'dropoff_failed', child: Text('تعذر التسليم')),
                PopupMenuItem(value: 'direct_parent_handling', child: Text('تسليم مباشر لولي الأمر')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TextActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TextActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: AppTextStyles.style(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
