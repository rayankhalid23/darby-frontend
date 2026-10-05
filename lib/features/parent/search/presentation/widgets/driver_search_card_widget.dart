import 'package:flutter/material.dart';
import 'package:kids_transport/features/parent/search/data/models/driver_search_model.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';

class DriverSearchCardWidget extends StatelessWidget {
  final DriverSearchModel driver;
  final bool isSelected;
  final bool showPricing;
  final bool isSubscriptionSearch;
  final bool isTopRecommended;
  final double? calculatedPrice;
  final String? priceCaption;
  final bool showCheckbox;
  final bool showMessageButton;
  final ValueChanged<bool?>? onSelectedChanged;
  final VoidCallback onTap;
  final VoidCallback? onMessageTap;

  const DriverSearchCardWidget({
    super.key,
    required this.driver,
    required this.isSelected,
    required this.onTap,
    this.showPricing = true,
    this.isSubscriptionSearch = false,
    this.isTopRecommended = false,
    this.calculatedPrice,
    this.priceCaption,
    this.showCheckbox = false,
    this.showMessageButton = false,
    this.onSelectedChanged,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? AppColors.surfaceDark : AppColors.white;
    final borderColor = isSelected
        ? cs.primary
        : (isDark ? AppColors.grey800 : AppColors.grey200);
    final subTextColor = isDark ? AppColors.grey400 : AppColors.textMuted;
    final bodyTextColor = isDark ? AppColors.grey200 : AppColors.textDark;

    final displayPrice = calculatedPrice ?? driver.price;
    final displayCaption = priceCaption ?? 'ابتداءً من';

    final bool showAiRecommendation =
        isSubscriptionSearch &&
        isTopRecommended &&
        driver.aiRankingReasons.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primary.withValues(alpha: isDark ? 0.10 : 0.04)
            : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── AI Recommendation Badge (Top Header) ───
              if (showAiRecommendation) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.35)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'موصى به',
                        style: AppTextStyles.style(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ─── Row 1: Avatar + Info + Price ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (driver.gender == 'FEMALE'
                              ? AppColors.femalePink
                              : cs.primary)
                          .withValues(alpha: isDark ? 0.15 : 0.10),
                    ),
                    child: Icon(
                      driver.gender == 'FEMALE'
                          ? Icons.face_4_rounded
                          : Icons.person_rounded,
                      size: 30,
                      color: driver.gender == 'FEMALE'
                          ? AppColors.femalePink
                          : cs.primary,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Driver Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          driver.fullName,
                          style: AppTextStyles.style(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: bodyTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.amber, size: 15),
                            const SizedBox(width: 3),
                            Text(
                              driver.rating.toStringAsFixed(1),
                              style: AppTextStyles.style(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.grey200
                                    : AppColors.grey800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${driver.reviewsCount})',
                              style: AppTextStyles.style(
                                fontSize: 11,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Vehicle
                        Row(
                          children: [
                            Icon(Icons.directions_bus_filled_outlined,
                                size: 13, color: subTextColor),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                driver.vehicleType,
                                style: AppTextStyles.style(
                                    fontSize: 12, color: subTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Working Zone
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: subTextColor),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                driver.serviceZones.join('، '),
                                style: AppTextStyles.style(
                                    fontSize: 12, color: subTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Price column
                  if (showPricing) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showCheckbox && onSelectedChanged != null)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: cs.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: onSelectedChanged,
                            ),
                          ),
                        if (driver.hasSiblingDiscount)
                          Text(
                            '${driver.subtotalPrice.toInt()} د.ل',
                            style: AppTextStyles.style(
                              fontSize: 12,
                              color: subTextColor,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: subTextColor,
                            ),
                          ),
                        Text(
                          '${displayPrice.toInt()} د.ل',
                          style: AppTextStyles.style(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayCaption,
                          style: AppTextStyles.style(
                            fontSize: 10,
                            color: subTextColor,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // ─── AI Recommendation Reasons Container ───
              if (showAiRecommendation) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.grey900.withValues(alpha: 0.5)
                        : AppColors.grey100.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.grey800 : AppColors.grey200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'أسباب التوصية:',
                            style: AppTextStyles.style(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.grey200
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...driver.aiRankingReasons.map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: AppTextStyles.style(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: AppTextStyles.style(
                                    fontSize: 11.5,
                                    color: subTextColor,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ─── Row 2: Action Buttons ───
              Row(
                children: [
                  // View Details
                  Expanded(
                    flex: showMessageButton ? 2 : 1,
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary, width: 1.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'عرض التفاصيل',
                          style: AppTextStyles.style(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Message button (only shown in Flow 2)
                  if (showMessageButton) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: onMessageTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            side: BorderSide(
                              color: cs.primary.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 14, color: cs.primary),
                              const SizedBox(width: 4),
                              Text(
                                'رسالة',
                                style: AppTextStyles.style(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: cs.primary,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
