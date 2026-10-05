import 'package:flutter/material.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/features/driver/trips/data/services/mock_route_provider.dart';

/// لوحة تحكم وضع المحاكاة — تظهر فقط في نسخة التطوير عند تفعيل المحاكاة
class MockRouteDebugPanel extends StatelessWidget {
  final MockRouteProvider provider;

  const MockRouteDebugPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MockRouteStatus>(
      valueListenable: provider.status,
      builder: (context, status, _) {
        final String stateText;
        if (status.isWaitingAtStop) {
          stateText = 'واقف عند: ${status.stopName ?? 'محطة'}';
        } else if (status.isFinished) {
          stateText = 'آخر محطة: ${status.stopName ?? ''} — أكّد النزول ثم أنهِ الرحلة';
        } else if (status.isRunning) {
          stateText = status.currentLeg;
        } else {
          stateText = 'متوقف مؤقتاً';
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: AppTheme.boxDecoration(
            color: AppColors.orange.withValues(alpha: 0.1),
            borderRadius: AppTheme.radius(12),
            border: AppTheme.border(color: AppColors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.science_rounded, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضع المحاكاة — نقطة ${status.step}/${status.total}',
                      style: AppTextStyles.style(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      stateText,
                      style: AppTextStyles.style(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (status.isWaitingAtStop)
                TextButton.icon(
                  onPressed: provider.continueFromStop,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('تكملة'),
                )
              else if (!status.isFinished)
                IconButton(
                  tooltip: status.isRunning ? 'إيقاف مؤقت' : 'تشغيل',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(status.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: status.isRunning ? provider.pause : provider.start,
                ),
              IconButton(
                tooltip: 'من البداية',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.replay_rounded),
                onPressed: () {
                  provider.reset();
                  provider.start();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
