import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kids_transport/core/widgets/app_user_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kids_transport/core/network/api_exception.dart';
import 'package:kids_transport/core/routes/app_router.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/primary_button.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/core/services/battery_service.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/low_battery_dialog.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_details_model.dart';
import 'package:kids_transport/features/driver/trips/logic/driver_trips_cubit/driver_trips_cubit.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/trip_child_status_badge.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/trip_status_badge.dart';

/// شاشة تفاصيل الرحلة: الأطفال، المدرسة، الترتيب، ETA، حالة كل طفل
class TripDetailsScreen extends StatefulWidget {
  final int tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    context.read<DriverTripsCubit>().loadTripDetails(widget.tripId);
  }

  Future<void> _startTrip() async {
    setState(() => _isStarting = true);
    try {
      final batteryService = getIt<BatteryService>();
      final batteryLevel = await batteryService.getBatteryLevel();

      if (batteryLevel != null && batteryLevel < 50) {
        if (!mounted) return;
        final proceed = await LowBatteryDialog.show(context, batteryLevel: batteryLevel);
        if (proceed != true) {
          if (mounted) setState(() => _isStarting = false);
          return;
        }
      }

      Position? position;
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
        }
      } catch (_) {}

      if (!mounted) return;
      final tripId = await context.read<DriverTripsCubit>().startTrip(
            widget.tripId,
            latitude: position?.latitude,
            longitude: position?.longitude,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.driverLiveTrip, arguments: tripId);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'فشل بدء الرحلة: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.backgroundSurface,
        appBar: AppBar(title: const Text('تفاصيل الرحلة')),
        body: BlocBuilder<DriverTripsCubit, DriverTripsState>(
          builder: (context, state) {
            if (state is DriverTripDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DriverTripDetailsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 50, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style: AppTextStyles.style(fontSize: 14, color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<DriverTripsCubit>().loadTripDetails(widget.tripId),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is DriverTripDetailsLoaded) {
              final details = state.details;
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, details),
                          const SizedBox(height: 16),
                          Text(
                            'الأطفال (${details.children.length})',
                            style: AppTextStyles.style(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...details.children
                              .map((child) => _ChildTile(child: child)),
                        ],
                      ),
                    ),
                  ),
                  if (details.isPending)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: PrimaryButton(
                        label: 'بدء الرحلة',
                        icon: Icons.play_arrow_rounded,
                        isLoading: _isStarting,
                        width: double.infinity,
                        onPressed: _startTrip,
                      ),
                    )
                  else if (details.isInProgress || details.isSuspended)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: PrimaryButton(
                        label: 'الرحلة الحية',
                        icon: Icons.navigation_rounded,
                        width: double.infinity,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.driverLiveTrip,
                          arguments: widget.tripId,
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DriverTripDetailsModel details) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.boxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppTheme.radius(16),
        border: AppTheme.border(
          color: isDark ? AppColors.grey800 : AppColors.grey.withValues(alpha: 0.15),
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
                  details.routeName,
                  style: AppTextStyles.style(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TripStatusBadge(status: details.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _StatItem(icon: Icons.child_care_rounded, label: '${details.statistics.children} طفل'),
              _StatItem(icon: Icons.school_rounded, label: '${details.statistics.schools} مدرسة'),
              _StatItem(icon: Icons.timelapse_rounded, label: '${details.estimatedDuration} دقيقة'),
              if (details.recommendedDeparture != null)
                _StatItem(icon: Icons.schedule_rounded, label: details.recommendedDeparture!),
              if (details.vehicle.plate.isNotEmpty)
                _StatItem(icon: Icons.directions_car_rounded, label: details.vehicle.plate),
              if (details.vehicle.capacity > 0)
                _StatItem(
                  icon: Icons.event_seat_rounded,
                  label:
                      'مقاعد متاحة: ${details.vehicle.capacity - details.statistics.children}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.textMuted),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.style(fontSize: 12, color: context.textMuted)),
      ],
    );
  }
}

class _ChildTile extends StatelessWidget {
  final TripDetailsChildModel child;

  const _ChildTile({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.boxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: AppTheme.radius(14),
        border: AppTheme.border(
          color: isDark ? AppColors.grey800 : AppColors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: AppTheme.boxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${child.sequenceOrder}',
                  style: AppTextStyles.style(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (child.photo != null && child.photo!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CachedNetworkImage(
                    imageUrl: AppUserAvatar.resolveUrl(child.photo)!,
                    httpHeaders: AppUserAvatar.imageHeaders,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  child.name,
                  style: AppTextStyles.style(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              TripChildStatusBadge(status: child.status, compact: true),
            ],
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المدرسة: ${child.school}',
                  style: AppTextStyles.style(fontSize: 12, color: context.textMuted),
                ),
                if (child.pickupAddress.isNotEmpty)
                  Text(
                    'الاصطحاب: ${child.pickupAddress}',
                    style: AppTextStyles.style(fontSize: 12, color: context.textMuted),
                  ),
                if (child.eta != null)
                  Text(
                    'الوصول التقديري: ${child.eta}',
                    style: AppTextStyles.style(fontSize: 12, color: context.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
