import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/smooth_marker_motion.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/primary_button.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_stop_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/live_trip_child_item.dart';
import 'package:kids_transport/features/driver/trips/data/services/driver_location_source.dart';
import 'package:kids_transport/features/driver/trips/logic/live_trip_cubit/live_trip_cubit.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/forgotten_children_dialog.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/mock_route_debug_panel.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/proximity_alert_banner.dart';

import 'package:kids_transport/core/services/road_route_tracker.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/trip_progress_bar.dart';
import 'package:kids_transport/features/driver/trips/presentation/widgets/trip_child_action_card.dart';
import 'package:kids_transport/features/driver/trips/data/models/vehicle_breakdown_model.dart';

/// شاشة الرحلة الحية: الخريطة، المحطات، الطفل الحالي، التقدّم، والإجراءات
class LiveTripScreen extends StatefulWidget {
  final int tripId;

  const LiveTripScreen({super.key, required this.tripId});

  @override
  State<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends State<LiveTripScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;

  /// حركة سلسة لأيقونة الحافلة بين تحديثات الـ GPS بدل القفز
  late final SmoothMarkerMotion _busMotion;
  final DriverLocationSource _locationSource = DriverLocationSource.instance;
  StreamSubscription<Position>? _positionSub;
  int _listenGeneration = 0;
  Position? _driverPosition;
  bool _isLocating = true;
  bool _mapReady = false;
  /// مسار الشوارع من الحافلة للمحطات المتبقية — يتقصّ مع حركة السائق
  /// ويتطلب من جديد فقط لو تغيّرت المحطات أو خرج السائق عن المسار
  late final RoadRouteTracker _routeTracker = RoadRouteTracker(
    onUpdated: () {
      if (mounted) setState(() {});
    },
  );
  /// الخريطة مكبّرة على كامل الشاشة (تكبير في نفس الشاشة بدون فتح Route جديد)
  bool _isMapExpanded = false;

  /// بلاغ الطوارئ قيد الإرسال (جلب الموقع + الطلب)
  bool _isReportingBreakdown = false;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
    _busMotion = SmoothMarkerMotion(vsync: this, maxDuration: const Duration(seconds: 5));
    context.read<LiveTripCubit>().loadAll(widget.tripId);
    context.read<LiveTripCubit>().startBackgroundSync(widget.tripId);
    _locationSource.mockEnabled.addListener(_onLocationModeChanged);
    _listenToPosition();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _locationSource.mockEnabled.removeListener(_onLocationModeChanged);
    // الخروج من الشاشة يرجّع دائماً للـ GPS الحقيقي
    if (_locationSource.isMock) _locationSource.setMockEnabled(false);
    _animatedMapController.dispose();
    _busMotion.dispose();
    super.dispose();
  }

  /// عند التبديل بين GPS الحقيقي والمحاكاة نعيد الاشتراك بالمصدر الجديد
  void _onLocationModeChanged() {
    if (!mounted) return;
    // الخريطة تُعاد بناؤها، فنوقف تتبع الكاميرا لين onMapReady من جديد
    setState(() {
      _isLocating = true;
      _mapReady = false;
    });
    _listenToPosition();
  }

  Future<void> _toggleMockMode() async {
    final enable = !_locationSource.isMock;
    try {
      await _locationSource.setMockEnabled(enable);
    } catch (e) {
      debugPrint('❌ [LiveTripScreen] تعذر تشغيل المحاكاة: $e');
      if (mounted) _showSnack('تعذر تحميل ملف مسار المحاكاة', isError: true);
    }
  }

  Future<void> _listenToPosition() async {
    // لو تبدّل المصدر أثناء الانتظار، نتجاهل نتيجة الاستدعاء القديم
    final generation = ++_listenGeneration;
    await _positionSub?.cancel();
    _positionSub = null;
    try {
      final hasPermission = await _locationSource.ensurePermission();
      if (generation != _listenGeneration) return;
      if (!hasPermission) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }

      // نجيب أول إحداثي فعلي قبل ما نرسم الخريطة، حتى ما نتمركز غلط على أول محطة
      // بدل موقع السائق الحقيقي (كان هذا سبب ظهور السائق "واقف" بالخريطة).
      final initialPosition = await _locationSource.getCurrentPosition();
      if (generation != _listenGeneration) return;
      debugPrint(
        '📍 [LiveTripScreen] أول إحداثي GPS: lat=${initialPosition.latitude}, lng=${initialPosition.longitude}',
      );
      if (mounted) {
        _busMotion.moveTo(LatLng(initialPosition.latitude, initialPosition.longitude));
        setState(() {
          _driverPosition = initialPosition;
          _isLocating = false;
        });
      }

      if (!mounted) return;
      _positionSub = _locationSource.positionStream().listen(
        (position) {
          // فحص احترازي: نتأكد إن الـ Stream ينبض ولا يتوقف بسبب توفير الطاقة بالنظام
          debugPrint(
            '📍 [LiveTripScreen] تحديث GPS: lat=${position.latitude}, lng=${position.longitude}, '
            'heading=${position.heading}°, speed=${position.speed} م/ث',
          );
          if (!mounted) return;
          final isMoving = _busMotion.moveTo(LatLng(position.latitude, position.longitude));
          setState(() => _driverPosition = position);
          _followDriver(position, isMoving: isMoving);
        },
        onError: (e) => debugPrint('❌ [LiveTripScreen] خطأ ببث الموقع: $e'),
      );
    } catch (e) {
      debugPrint('❌ [LiveTripScreen] تعذر جلب الموقع الأولي: $e');
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// يحرّك الكاميرا بسلاسة (Pan) لتتبع السائق تلقائياً مع كل تحديث GPS،
  /// بدل ما تتجمد الخريطة على أول تمركز.
  /// لما الحافلة تمشي بسلاسة، الكاميرا تمشي بنفس المدة وبسرعة ثابتة
  /// حتى تقعد الحافلة في نص الشاشة بدل ما تسبقها الكاميرا
  void _followDriver(Position position, {bool isMoving = false}) {
    if (!_mapReady) return;
    _animatedMapController.animateTo(
      dest: LatLng(position.latitude, position.longitude),
      zoom: _animatedMapController.mapController.camera.zoom,
      duration: isMoving ? _busMotion.currentDuration : null,
      curve: isMoving ? Curves.linear : null,
    );
  }

  double? _distanceToChild(LiveTripChildItem item) {
    if (_driverPosition == null) return null;
    if (item.targetLatitude == null || item.targetLongitude == null) return null;
    return Geolocator.distanceBetween(
      _driverPosition!.latitude,
      _driverPosition!.longitude,
      item.targetLatitude!,
      item.targetLongitude!,
    );
  }

  Future<void> _handleManualConfirm(LiveTripChildItem item) async {
    Position? pos = _driverPosition;
    if (pos == null) {
      try {
        pos = await _locationSource.getCurrentPosition();
      } catch (_) {}
    }
    if (pos == null) {
      _showSnack(
        'يتعذر الحصول على الموقع الجغرافي الحالي لتأكيد الإجراء، يرجى تفعيل الموقع أو استخدام مسح QR.',
        isError: true,
      );
      return;
    }
    if (!mounted) return;
    final cubit = context.read<LiveTripCubit>();
    if (item.isDropoffPhase) {
      await cubit.manualDropoff(
        widget.tripId,
        item,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } else {
      await cubit.manualPickup(
        widget.tripId,
        item,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }
  }



  Future<void> _confirmAndRunWithLocation(
    String title,
    String message,
    void Function(double lat, double lng) onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      Position? pos = _driverPosition;
      if (pos == null) {
        try {
          pos = await _locationSource.getCurrentPosition();
        } catch (_) {}
      }
      if (pos == null) {
        if (!mounted) return;
        _showSnack(
          'يتعذر الحصول على الموقع الجغرافي الحالي لتأكيد الإجراء، يرجى تفعيل الموقع.',
          isError: true,
        );
        return;
      }
      onConfirm(pos.latitude, pos.longitude);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _handleComplete() async {
    final state = context.read<LiveTripCubit>().state;
    if (state is LiveTripLoaded && !state.canComplete) {
      final remaining = state.progress.remaining;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: AppTheme.roundedRectangleBorder(borderRadius: AppTheme.radius(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
                const SizedBox(width: 8),
                const Expanded(child: Text('لا تزال هناك محطات متبقية')),
              ],
            ),
            content: Text(
              'يوجد $remaining من أصل ${state.progress.total} لم تُحسم حالتهم بعد. '
              'هل تريد إنهاء الرحلة رغم ذلك؟',
              textAlign: TextAlign.right,
              style: AppTextStyles.style(fontSize: 14),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dCtx).pop(false), child: const Text('رجوع')),
              ElevatedButton(
                onPressed: () => Navigator.of(dCtx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('إنهاء رغم ذلك'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (!mounted) return;
    await context.read<LiveTripCubit>().completeTrip(widget.tripId);
  }

  Future<void> _handleReportBreakdown() async {
    if (_isReportingBreakdown) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _BreakdownReasonDialog(),
    );
    if (!mounted || reason == null) return;

    // مؤشر إرسال يغطي الشاشة ويمنع إرسال بلاغ ثاني لين يوصل الرد
    setState(() => _isReportingBreakdown = true);
    try {
      final position = await _breakdownPosition();
      if (!mounted) return;

      // بدون موقع نبعتوا البلاغ بلا إحداثيات (الباك يستعمل آخر موقع عنده)
      // بدل (0, 0)، وبدون عنوان لأن عنوان بيت الطفل مش مكان العطل
      final request = VehicleBreakdownRequestModel(
        latitude: position?.latitude,
        longitude: position?.longitude,
        reason: reason,
        accuracy: position?.accuracy,
        speed: position?.speed,
      );
      await context.read<LiveTripCubit>().reportBreakdown(widget.tripId, request);
    } finally {
      if (mounted) setState(() => _isReportingBreakdown = false);
    }
  }

  /// موقع لحظة البلاغ: GPS جديد (بحد أقصى 10 ثواني)، وإلا آخر موقع معروف
  /// للحافلة، وإلا null
  Future<Position?> _breakdownPosition() async {
    try {
      await _locationSource.ensurePermission();
      return await _locationSource.getCurrentPosition().timeout(const Duration(seconds: 10));
    } catch (_) {
      return _driverPosition;
    }
  }

  Widget _buildBreakdownSendingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Material(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.error),
                  const SizedBox(height: 14),
                  Text(
                    'جاري إرسال بلاغ الطوارئ...',
                    style: AppTextStyles.style(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBreakdownResultDialog(VehicleBreakdownResponseModel result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.isNoSubstitutes ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              color: result.isNoSubstitutes ? AppColors.warning : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.isBroadcasted
                    ? 'تم بث بلاغ الطوارئ'
                    : (result.isNoSubstitutes ? 'تنبيه السائقين البدلاء' : 'نتيجة بلاغ الطوارئ'),
                style: AppTextStyles.style(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message, style: AppTextStyles.style(fontSize: 14)),
            if (result.strandedChildrenCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                'عدد الأطفال المتأثرين بالتعطل: ${result.strandedChildrenCount}',
                style: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            if (result.isBroadcasted && result.candidatesCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                'عدد السائقين المتاحين بالمنطقة: ${result.candidatesCount}',
                style: AppTextStyles.style(fontSize: 13, color: AppColors.primary),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // زر الرجوع وهي مكبّرة يصغّر الخريطة بدل الخروج من الرحلة
    return PopScope(
      canPop: !_isMapExpanded && !_isReportingBreakdown,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isMapExpanded) {
          setState(() => _isMapExpanded = false);
        }
      },
      child: Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
      Scaffold(
        backgroundColor: context.backgroundSurface,
        appBar: AppBar(
          // اسم المسار (route_name) من /driver/trips/{id} — يظهر بمجرد توفره بالحالة
          title: BlocBuilder<LiveTripCubit, LiveTripState>(
            buildWhen: (previous, current) =>
                current is LiveTripLoaded && current.routeName != (previous is LiveTripLoaded ? previous.routeName : ''),
            builder: (context, state) {
              final routeName = state is LiveTripLoaded ? state.routeName : '';
              return Text(routeName.isNotEmpty ? routeName : 'الرحلة الحية');
            },
          ),
          actions: [
            // مفتاح المحاكاة — نسخة التطوير فقط، لا يظهر نهائياً في نسخة الإصدار
            if (kDebugMode)
              ValueListenableBuilder<bool>(
                valueListenable: _locationSource.mockEnabled,
                builder: (context, isMock, _) => IconButton(
                  tooltip: isMock ? 'إيقاف المحاكاة (رجوع للـ GPS)' : 'تشغيل محاكاة الرحلة',
                  icon: Icon(
                    isMock ? Icons.science_rounded : Icons.science_outlined,
                    color: isMock ? AppColors.orange : null,
                  ),
                  onPressed: _toggleMockMode,
                ),
              ),
            BlocBuilder<LiveTripCubit, LiveTripState>(
              builder: (context, state) {
                if (state is! LiveTripLoaded) return const SizedBox.shrink();
                if (state.isInProgress) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: TextButton.icon(
                      onPressed: _isReportingBreakdown ? null : _handleReportBreakdown,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.error.withValues(alpha: 0.5),
                        disabledForegroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: Text(
                        'طوارئ',
                        style: AppTextStyles.style(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<LiveTripCubit, LiveTripState>(
          listenWhen: (previous, current) =>
              current is LiveTripLoaded &&
              (current.blockingErrorMessage != null ||
                  current.actionErrorMessage != null ||
                  current.isCompleted ||
                  // نتيجة البلاغ تظهر مرة وحدة بس: لحظة وصولها
                  (current.breakdownResult != null &&
                      (previous is! LiveTripLoaded || previous.breakdownResult == null))),
          listener: (context, state) {
            if (state is! LiveTripLoaded) return;
            if (state.blockingErrorMessage != null) {
              final cubit = context.read<LiveTripCubit>();
              ForgottenChildrenDialog.show(
                context,
                message: state.blockingErrorMessage!,
                onGoToStops: cubit.clearBlockingError,
              ).then((_) => cubit.clearBlockingError());
            } else if (state.actionErrorMessage != null) {
              _showSnack(state.actionErrorMessage!, isError: true);
              context.read<LiveTripCubit>().clearActionError();
            } else if (state.breakdownResult != null) {
              final result = state.breakdownResult!;
              // نمسحوها طول حتى ما تسبقش ديالوج إنهاء الرحلة ولا تتعاود
              context.read<LiveTripCubit>().clearBreakdownResult();
              _showBreakdownResultDialog(result);
            } else if (state.isCompleted && state.completedSummary != null) {
              _showCompletionDialog(state);
            }
          },
          builder: (context, state) {
            if (state is LiveTripLoading || state is LiveTripInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LiveTripError) {
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
                        onPressed: () => context.read<LiveTripCubit>().loadAll(widget.tripId),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state as LiveTripLoaded;
            // نفس الـ SizedBox يتغير ارتفاعه فقط، فالخريطة ما تنبنيش من جديد
            // ويكمل تتبع الـ GPS والكاميرا والمسار بدون انقطاع
            return LayoutBuilder(
              builder: (context, constraints) => Column(
              children: [
                SizedBox(
                  height: _isMapExpanded ? constraints.maxHeight : 220,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _isLocating ? _buildMapLoadingPlaceholder() : _buildMap(loaded.stops),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'driver_live_map_expand',
                          tooltip: _isMapExpanded ? 'تصغير الخريطة' : 'تكبير الخريطة',
                          backgroundColor: context.isDarkMode ? AppColors.grey400 : AppColors.white,
                          elevation: 4,
                          onPressed: () => setState(() => _isMapExpanded = !_isMapExpanded),
                          child: Icon(
                            _isMapExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                            color: context.primaryColor,
                          ),
                        ),
                      ),
                      if (_isMapExpanded)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _buildExpandedMapBottomCard(loaded, constraints.maxHeight),
                        ),
                    ],
                  ),
                ),
                if (!_isMapExpanded) ...[
                if (_locationSource.isMock) MockRouteDebugPanel(provider: _locationSource.mockRoute),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TripProgressBar(
                    completed: loaded.progress.completed,
                    total: loaded.progress.total,
                  ),
                ),
                if (loaded.isSuspended) _buildSuspendedBanner(loaded),
                if (loaded.proximityAlert != null && loaded.proximityAlertReceivedAt != null)
                  ProximityAlertBanner(
                    key: ValueKey(loaded.proximityAlert!.key),
                    alert: loaded.proximityAlert!,
                    receivedAt: loaded.proximityAlertReceivedAt!,
                    onDismiss: context.read<LiveTripCubit>().dismissProximityAlert,
                  ),
                if (loaded.isInProgress) _buildNextStationSection(loaded),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: loaded.childItems.length,
                    itemBuilder: (context, index) {
                      final item = loaded.childItems[index];
                      final isCurrent = loaded.currentChild?.tripChildId == item.tripChildId;
                      return _buildChildActionCard(loaded, item, isCurrent);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildTripEndButton(loaded),
                ),
                ],
              ],
            ),
            );
          },
        ),
      ),
          if (_isReportingBreakdown) _buildBreakdownSendingOverlay(),
        ],
      ),
      ),
    );
  }

  Widget _buildSuspendedBanner(LiveTripLoaded loaded) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.boxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppTheme.radius(12),
        border: AppTheme.border(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loaded.substituteAccepted
                  ? 'استلم السائق البديل مهمة نقل الأطفال — لا يمكن استئناف هذه الرحلة.'
                  : 'الرحلة متوقفة مؤقتاً (عطل) — استأنفها للاستمرار في الإجراءات.',
              style: AppTextStyles.style(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة إجراءات طفل واحد (استلام/غياب/تخطي...) — تُستخدم بالقائمة وبالكرت العايم فوق الخريطة المكبّرة
  Widget _buildChildActionCard(LiveTripLoaded loaded, LiveTripChildItem item, bool isCurrent) {
    return TripChildActionCard(
      item: item,
      isCurrent: isCurrent,
      isPendingAction: loaded.pendingActionTripChildId == item.tripChildId,
      distanceMeters: _distanceToChild(item),
      hasTargetCoordinates: item.targetLatitude != null && item.targetLongitude != null,
      isTripCompleted: loaded.isCompleted || loaded.tripStatus == 'completed',
      onManualConfirm: loaded.isSuspended ? () {} : () => _handleManualConfirm(item),
      onAbsent: loaded.isSuspended
          ? () {}
          : () => _confirmAndRunWithLocation(
                'تأكيد الغياب',
                'هل تؤكد أن ${item.name} غير موجود في هذه المحطة؟',
                (lat, lng) => context.read<LiveTripCubit>().markAbsent(
                      widget.tripId,
                      item,
                      latitude: lat,
                      longitude: lng,
                    ),
              ),
      onSkip: loaded.isSuspended
          ? () {}
          : () => context.read<LiveTripCubit>().skipChild(widget.tripId, item),
      onDropoffFailed: loaded.isSuspended
          ? () {}
          : () => _confirmAndRunWithLocation(
                'تعذر التسليم',
                'سيتم تسجيل هذه المحطة كحالة تعذر تسليم. هل أنت متأكد؟',
                (lat, lng) => context.read<LiveTripCubit>().markDropoffFailed(
                      widget.tripId,
                      item,
                      latitude: lat,
                      longitude: lng,
                    ),
              ),
      onDirectParentHandling: loaded.isSuspended
          ? () {}
          : () => _confirmAndRunWithLocation(
                'تسليم مباشر لولي الأمر',
                'سيتم تسجيل استلام ولي الأمر للطفل مباشرة. هل أنت متأكد؟',
                (lat, lng) => context.read<LiveTripCubit>().markDirectParentHandling(
                      widget.tripId,
                      item,
                      latitude: lat,
                      longitude: lng,
                    ),
              ),
    );
  }

  /// الكرت العايم أسفل الخريطة المكبّرة: المحطة الجاية وبطاقة الطفل الحالي
  /// بأزرارها — حتى يكمل السائق الرحلة بدون تصغير الخريطة
  Widget _buildExpandedMapBottomCard(LiveTripLoaded loaded, double availableHeight) {
    final isDark = context.isDarkMode;
    LiveTripChildItem? currentItem;
    for (final item in loaded.childItems) {
      if (item.tripChildId == loaded.currentChild?.tripChildId) {
        currentItem = item;
        break;
      }
    }

    return Container(
      // سقف للارتفاع حتى تبقى الخريطة ظاهرة، والمحتوى الزايد يتسكرول
      constraints: BoxConstraints(maxHeight: availableHeight * 0.55),
      decoration: BoxDecoration(
        color: (isDark ? context.cardSurface : AppColors.white).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loaded.isSuspended) _buildSuspendedBanner(loaded),
            if (loaded.isInProgress) _buildNextStationSection(loaded),
            if (currentItem != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildChildActionCard(loaded, currentItem, true),
              ),
          ],
        ),
      ),
    );
  }

  /// زر إنهاء الرحلة أو استئنافها حسب حالة التوقف
  Widget _buildTripEndButton(LiveTripLoaded loaded) {
    // بعد قبول البديل الاستئناف مرفوض من الباك — نعطوه طريق للخروج بدل زر ما يخدمش
    if (loaded.isSuspended && loaded.substituteAccepted) {
      return PrimaryButton(
        label: 'رجوع للرئيسية',
        icon: Icons.home_rounded,
        width: double.infinity,
        onPressed: () => Navigator.of(context).pop(),
      );
    }
    return loaded.isSuspended
      ? PrimaryButton(
          label: 'استئناف الرحلة',
          icon: Icons.play_circle_outline_rounded,
          width: double.infinity,
          onPressed: () => context.read<LiveTripCubit>().resumeTrip(widget.tripId),
        )
      : PrimaryButton(
          label: 'إنهاء الرحلة',
          icon: Icons.flag_circle_rounded,
          backgroundColor: loaded.canComplete ? AppColors.success : AppColors.grey400,
          width: double.infinity,
          onPressed: _handleComplete,
        );
  }

  /// يعرض "المحطة التالية" بالاعتماد حصراً على next_stop/next_child القادمين
  /// فعلياً من استجابة آخر إجراء ناجح (Backend Authoritative Source). عند
  /// عدم توفرهما (لم يُنفَّذ أي إجراء بعد، أو تقدّمت الرحلة والانتظار لإجراء
  /// جديد)، لا نفترض مباشرة انتهاء الرحلة — نتحقق من trip_status وprogress
  /// أولاً، تماشياً مع الـ Backend Contract الفعلي.
  Widget _buildNextStationSection(LiveTripLoaded loaded) {
    final nextStop = loaded.nextStop;
    final nextChild = loaded.nextChild;

    if (nextStop != null || nextChild != null) {
      final title = nextChild?.name ??
          nextStop?.childName ??
          nextStop?.name ??
          nextStop?.title ??
          nextStop?.schoolName ??
          'المحطة التالية';
      final subtitleParts = <String>[
        if (nextStop?.address != null && nextStop!.address!.isNotEmpty) nextStop.address!,
        if (nextStop?.eta != null && nextStop!.eta!.isNotEmpty) 'الوصول التقديري: ${nextStop.eta}',
      ];
      final isSchool = nextStop?.isSchool ?? false;

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.boxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: AppTheme.radius(12),
          border: AppTheme.border(color: AppColors.primaryLight.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              isSchool ? Icons.school_rounded : Icons.home_rounded,
              color: AppColors.primaryLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المحطة التالية',
                    style: AppTextStyles.style(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    title,
                    style: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitleParts.isNotEmpty)
                    Text(
                      subtitleParts.join(' • '),
                      style: AppTextStyles.style(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // next_stop غير متوفرة بعد — لا نفسّرها كنهاية للرحلة إلا بدليل إضافي
    final looksFinished = loaded.tripStatus == 'completed' || loaded.progress.remaining <= 0;
    final message =
        looksFinished ? 'هذه آخر محطة في الرحلة' : 'سيتم تحديد المحطة التالية بعد إتمام الإجراء الحالي';
    final icon = looksFinished ? Icons.flag_circle_rounded : Icons.hourglass_bottom_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.boxDecoration(
        color: AppColors.grey.withValues(alpha: 0.08),
        borderRadius: AppTheme.radius(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTextStyles.style(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  /// يُعرض ريثما نحصل على أول إحداثي GPS حقيقي، بدل رسم الخريطة على موقع
  /// محطة عشوائية ثم القفز لموقع السائق لاحقاً.
  Widget _buildMapLoadingPlaceholder() {
    return Container(
      color: context.backgroundSurface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'جارٍ تحديد موقعك...',
            style: AppTextStyles.style(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<DriverTripStopModel> stops) {
    final driverLatLng = _driverPosition != null
        ? LatLng(_driverPosition!.latitude, _driverPosition!.longitude)
        : (stops.isNotEmpty ? LatLng(stops.first.latitude, stops.first.longitude) : const LatLng(0, 0));

    final currentState = context.read<LiveTripCubit>().state;
    LiveTripLoaded? loadedState;
    if (currentState is LiveTripLoaded) {
      loadedState = currentState;
    }

    final routeTargets = stops
        .where((s) => s.latitude != 0.0 && s.longitude != 0.0)
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();
    final roadPolylinePoints = _driverPosition != null && routeTargets.isNotEmpty
        ? _routeTracker.update(driverLatLng, routeTargets)
        : const <LatLng>[];

    // أيقونة الحافلة تنرسم في طبقة منفصلة فوق المحطات وتتحرك بسلاسة (_busMotion)
    final Widget? busIcon = _driverPosition == null
        ? null
        : Transform.rotate(
            angle: _driverPosition!.heading * math.pi / 180,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          );

    final markers = <Marker>[
      ...List.generate(stops.length, (i) {
        final stop = stops[i];
        final badgeNum = stop.sequenceOrder > 0 ? stop.sequenceOrder : (i + 1);
        final isCompleted = stop.isResolved;
        final isCurrentTarget = loadedState?.currentChild != null &&
            ((stop.isHome && stop.childId == loadedState!.currentChild!.childId) ||
                (stop.isSchool && stop.schoolId != null));

        return Marker(
          point: LatLng(stop.latitude, stop.longitude),
          width: 50,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
                      : (isCurrentTarget ? AppColors.orange : AppColors.primaryLight),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: isCurrentTarget ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : (stop.isSchool ? Icons.school_rounded : Icons.home_rounded),
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.green700 : AppColors.secondaryDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: Text(
                    '$badgeNum',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ];


    return FlutterMap(
      mapController: _animatedMapController.mapController,
      options: MapOptions(
        initialCenter: driverLatLng,
        initialZoom: 14,
        onMapReady: () => _mapReady = true,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kids_transport.app',
        ),
        if (roadPolylinePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: roadPolylinePoints,
                strokeWidth: 4.5,
                color: AppColors.primaryLight,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        if (busIcon != null)
          AnimatedBuilder(
            animation: _busMotion.controller,
            builder: (context, _) => MarkerLayer(
              markers: [
                Marker(
                  point: _busMotion.position ?? driverLatLng,
                  width: 48,
                  height: 48,
                  child: busIcon,
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showCompletionDialog(LiveTripLoaded state) {
    final summary = state.completedSummary!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        shape: AppTheme.roundedRectangleBorder(borderRadius: AppTheme.radius(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('تم إنهاء الرحلة بنجاح'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: 'عدد الأطفال', value: '${summary.children}'),
            _SummaryRow(label: 'تم اصطحابهم', value: '${summary.pickedUp}'),
            _SummaryRow(label: 'تم تسليمهم', value: '${summary.droppedOff}'),
            _SummaryRow(label: 'الغياب', value: '${summary.absent}'),
            _SummaryRow(label: 'المدة', value: '${summary.duration} دقيقة'),
            _SummaryRow(label: 'المسافة', value: '${summary.distance.toStringAsFixed(1)} كم'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.style(fontSize: 13, color: AppColors.textMuted)),
          Text(value, style: AppTextStyles.style(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// ديالوج سبب العطل — يملك الـ TextEditingController ويتخلص منه مع إغلاقه،
/// ويرجّع السبب المكتوب أو null عند الإلغاء
class _BreakdownReasonDialog extends StatefulWidget {
  const _BreakdownReasonDialog();

  @override
  State<_BreakdownReasonDialog> createState() => _BreakdownReasonDialogState();
}

class _BreakdownReasonDialogState extends State<_BreakdownReasonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'يرجى إدخال سبب العطل لتفعيل بلاغ الطوارئ');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          SizedBox(width: 8),
          Text('إبلاغ طوارئ تعطل المركبة', textAlign: TextAlign.right),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يرجى كتابة سبب العطل بشكل دقيق للإدارة والسائقين البدلاء قبل إرسال بلاغ الطوارئ:',
            style: AppTextStyles.style(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'مثال: عطل في المحرك وتوقف تام للمركبة في طريق الشط',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('إرسال بلاغ الطوارئ'),
        ),
      ],
    );
  }
}
