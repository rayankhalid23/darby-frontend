import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_transport/core/routes/app_router.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/widgets/app_section_header.dart';
import 'package:kids_transport/features/driver/driver_preferences/logic/driver_preferences_cubit.dart';
import 'package:kids_transport/features/driver/driver_preferences/logic/driver_preferences_state.dart';
import 'package:kids_transport/features/driver/shared/di/driver_injection.dart';

class WorkAreasCard extends StatelessWidget {
  const WorkAreasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => driverSl<DriverPreferencesCubit>()..loadDriverPreferences(),
      child: const _WorkAreasCardContent(),
    );
  }
}

class _WorkAreasCardContent extends StatelessWidget {
  const _WorkAreasCardContent();

  List<String> _extractAreaNames(DriverPreferencesState state) {
    if (state is! DriverPreferencesLoaded || state.preferences == null) {
      return [];
    }
    final List<String> areaNames = [];
    final coverage = state.preferences!.coverage;

    for (final cov in coverage) {
      if (cov.zones.isNotEmpty) {
        for (final z in cov.zones) {
          if (z.name.trim().isNotEmpty && !areaNames.contains(z.name.trim())) {
            areaNames.add(z.name.trim());
          }
        }
      } else {
        final name = cov.subMunicipalityName.trim().isNotEmpty
            ? cov.subMunicipalityName.trim()
            : cov.municipalityName.trim();
        if (name.isNotEmpty && !areaNames.contains(name)) {
          areaNames.add(name);
        }
      }
    }
    return areaNames;
  }

  void _navigateToPreferences(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.driverPreferences).then((_) {
      if (context.mounted) {
        context.read<DriverPreferencesCubit>().loadDriverPreferences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<DriverPreferencesCubit, DriverPreferencesState>(
      builder: (context, state) {
        final areas = _extractAreaNames(state);
        final isLoading =
            state is DriverPreferencesLoading || state is DriverPreferencesInitial;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.boxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppTheme.radius(20),
            border: Border.all(
              color: isDark ? AppColors.grey700 : AppColors.grey300,
              width: 1.2,
            ),
            boxShadow: [
              AppTheme.boxShadow(
                color: AppColors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'مناطق العمل الحالية',
                icon: Icons.map_outlined,
                actionWidget: IconButton(
                  onPressed: () => _navigateToPreferences(context),
                  icon: const Icon(
                    Icons.edit_location_alt_rounded,
                    color: AppColors.primaryLight,
                  ),
                  tooltip: 'تعديل المناطق',
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (areas.isEmpty)
                InkWell(
                  onTap: () => _navigateToPreferences(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'لم يتم تحديد مناطق عمل بعد في إعداداتك. اضغط للتعديل.',
                            style: AppTextStyles.style(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: areas.map((area) {
                    return Chip(
                      label: Text(
                        area,
                        style: AppTextStyles.style(
                          fontSize: 13,
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      shape: AppTheme.roundedRectangleBorder(
                        borderRadius: AppTheme.radius(8),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
