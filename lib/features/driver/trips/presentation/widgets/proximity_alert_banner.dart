import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/features/driver/trips/data/models/proximity_alert_model.dart';

/// شريط تنبيه الاقتراب/الوصول القادم من proximity.alerts، مع عداد انتظار
/// تنازلي عند الوصول (10 دقائق للمنزل، 15 للمدرسة)
class ProximityAlertBanner extends StatefulWidget {
  final ProximityAlertModel alert;
  final DateTime receivedAt;
  final VoidCallback onDismiss;

  const ProximityAlertBanner({
    super.key,
    required this.alert,
    required this.receivedAt,
    required this.onDismiss,
  });

  @override
  State<ProximityAlertBanner> createState() => _ProximityAlertBannerState();
}

class _ProximityAlertBannerState extends State<ProximityAlertBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.alert.waitDuration != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration? get _remaining {
    final wait = widget.alert.waitDuration;
    if (wait == null) return null;
    final left = wait - DateTime.now().difference(widget.receivedAt);
    return left.isNegative ? Duration.zero : left;
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final name = alert.childName;
    final String title;
    final IconData icon;
    final Color color;
    switch (alert.type) {
      case ProximityAlertModel.approachingHome:
        title = name != null ? 'أنت تقترب من منزل $name' : 'أنت تقترب من منزل الطالب';
        icon = Icons.near_me_rounded;
        color = AppColors.primaryLight;
      case ProximityAlertModel.arrivedHome:
        title = name != null ? 'وصلت إلى منزل $name' : 'وصلت إلى منزل الطالب';
        icon = Icons.home_rounded;
        color = AppColors.success;
      case ProximityAlertModel.arrivedSchool:
        title = 'وصلت إلى المدرسة';
        icon = Icons.school_rounded;
        color = AppColors.success;
      default:
        title = alert.message ?? alert.type;
        icon = Icons.notifications_active_rounded;
        color = AppColors.primaryLight;
    }

    final remaining = _remaining;
    final expired = remaining != null && remaining == Duration.zero;
    final String? subtitle;
    if (remaining == null) {
      subtitle = alert.message != null && alert.message != title ? alert.message : null;
    } else if (expired) {
      subtitle = 'انتهت مدة الانتظار — يمكنك تخطي الطالب إن لم يحضر';
    } else {
      subtitle = alert.type == ProximityAlertModel.arrivedSchool
          ? 'أكّد نزول الطلاب — الوقت المتبقي ${_format(remaining)}'
          : 'أكّد صعود الطالب — الوقت المتبقي ${_format(remaining)}';
    }
    final effectiveColor = expired ? AppColors.warning : color;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: AppTheme.boxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: AppTheme.radius(12),
        border: AppTheme.border(color: effectiveColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyles.style(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إخفاء',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );
  }
}
