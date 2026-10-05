import 'package:flutter/material.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/app_section_header.dart';
import 'package:kids_transport/features/driver/requests/data/models/driver_request_model.dart';

/// قسم طلبات الاشتراك الجديدة في الصفحة الرئيسية للسائق
/// يعرض أول طلب جديد مع زر "عرض الكل"
class NewRequestsSection extends StatelessWidget {
  final List<DriverRequestModel> requests;
  final VoidCallback? onViewAll;

  const NewRequestsSection({
    super.key,
    required this.requests,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'طلبات الاشتراك الجديدة (${requests.length})',
          actionWidget: onViewAll != null
              ? InkWell(
                  onTap: onViewAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'عرض الكل',
                      style: AppTextStyles.style(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),

        if (requests.isEmpty)
          const _EmptyRequestsState()
        else
          _HomeRequestCard(request: requests.first),
      ],
    );
  }
}

class _EmptyRequestsState extends StatelessWidget {
  const _EmptyRequestsState();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: AppTheme.boxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppTheme.radius(20),
        border: AppTheme.border(
          color: isDark
              ? AppColors.grey800
              : AppColors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: AppTheme.boxDecoration(
              color: AppColors.grey.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: AppColors.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد طلبات جديدة',
            style: AppTextStyles.style(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ستظهر هنا طلبات اشتراك أولياء الأمور عند وصولها',
            style: AppTextStyles.style(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HomeRequestCard extends StatelessWidget {
  final DriverRequestModel request;

  const _HomeRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final parentName = request.parent.name.isNotEmpty
        ? request.parent.name
        : 'طلب اشتراك #${request.id}';
    final childrenSummary = request.children.isNotEmpty
        ? request.children.map((c) => c.name).join('، ')
        : 'لا يوجد أطفال محددين';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/driver-request-details',
          arguments: request.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.boxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: AppTheme.radius(20),
          border: AppTheme.border(
            color: isDark
                ? AppColors.grey800
                : AppColors.grey.withValues(alpha: 0.15),
          ),
          boxShadow: [
            AppTheme.boxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── رأس الكرت: ولي الأمر وعدد الأطفال ──
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      AppColors.primaryLight.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentName,
                        style: AppTextStyles.style(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.child_care_rounded,
                            color: AppColors.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${request.childrenCount} أطفال: $childrenSummary',
                              style: AppTextStyles.style(
                                fontSize: 12,
                                color: AppColors.textMuted,
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
              ],
            ),
            const SizedBox(height: 12),

            // ── تفاصيل الطلب ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.boxDecoration(
                color: isDark ? AppColors.grey900 : AppColors.backgroundLight,
                borderRadius: AppTheme.radius(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoItem(
                        icon: Icons.calendar_today_rounded,
                        iconColor: AppColors.primaryLight,
                        label: 'النوع',
                        value: request.typeDisplayLabel,
                      ),
                      _InfoItem(
                        icon: Icons.alt_route_rounded,
                        iconColor: context.primaryColor,
                        label: 'الاتجاه',
                        value: request.directionDisplayLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التكلفة الإجمالية:',
                        style: AppTextStyles.style(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        request.totalPriceDisplay,
                        style: AppTextStyles.style(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── عرض التفاصيل ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${request.id}',
                  style: AppTextStyles.style(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'عرض تفاصيل الطلب',
                      style: AppTextStyles.style(
                        fontSize: 11,
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: context.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppTextStyles.style(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.style(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
