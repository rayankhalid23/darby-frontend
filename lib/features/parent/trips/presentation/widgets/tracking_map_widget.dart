import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/services/osrm_routing_service.dart';
import 'package:kids_transport/core/services/road_route_tracker.dart';
import 'package:kids_transport/core/utils/smooth_marker_motion.dart';
import '../../data/models/active_trip_model.dart';
import '../../data/models/trip_track_model.dart';
import '../../logic/trip_tracking_cubit/trip_tracking_state.dart';

class TrackingMapWidget extends StatefulWidget {
  final MapController mapController;
  final bool isMultiMode;
  final LiveTrackingModel? singleTrack;
  final ActiveTripModel? singleTrip;
  final List<LiveTrackingModel> multiTracks;
  final List<ActiveTripModel> multiTrips;
  final Function(int tripId)? onSelectTrip;

  /// رسالة تظهر فوق الخريطة لما يفشل جلب موقع السائق (مثلاً رفض قواعد Firestore)
  final String? locationErrorMessage;

  const TrackingMapWidget({
    super.key,
    required this.mapController,
    required this.isMultiMode,
    this.singleTrack,
    this.singleTrip,
    this.multiTracks = const [],
    this.multiTrips = const [],
    this.onSelectTrip,
    this.locationErrorMessage,
  });

  /// رسالة الخطأ المعروضة فوق الخريطة حسب حالة التتبع (مشتركة بين شاشات التتبع)
  static String? locationErrorFrom(TripTrackingState state) {
    if (state is TripTrackingError) return 'تعذر جلب موقع السائق حالياً';
    if (state is TripTrackingSingleLoaded && state.isOffline) {
      return state.offlineMessage ?? 'تعذر تحديث موقع السائق';
    }
    return null;
  }

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget> with TickerProviderStateMixin {
  static const LatLng defaultLocation = LatLng(32.8872, 13.1913);

  /// مسار شوارع ثابت لكل (رحلة، وجهة): يتقصّ مع حركة الحافلة بدل ما
  /// يتطلب من جديد ويترسم مستقيم مع كل تحديث للموقع
  final Map<String, RoadRouteTracker> _routeTrackers = {};

  /// الكاميرا تتبع الحافلة تلقائياً، وتتوقف لما ولي الأمر يحرّك الخريطة بيده
  /// لين يضغط زر التوسيط
  bool _followDriver = true;

  static bool _hasLocation(double lat, double lng) => lat != 0.0 && lng != 0.0;

  /// القائمة الأولى لو فيها عناصر، وإلا البديلة (قائمة فاضية مش null فـ ?? ما يكفيش)
  static List<T> _nonEmptyOr<T>(List<T>? primary, List<T> fallback) =>
      (primary != null && primary.isNotEmpty) ? primary : fallback;

  /// نقطة تمركز للرحلة لما موقع السائق مش متوفر: الوجهة ثم المدرسة ثم المنزل
  LatLng? _tripAnchor(ActiveTripModel? trip) {
    if (trip == null) return null;
    if (_hasLocation(trip.destination.lat, trip.destination.lng)) {
      return LatLng(trip.destination.lat, trip.destination.lng);
    }
    if (trip.uniqueSchools.isNotEmpty) {
      return LatLng(trip.uniqueSchools.first.lat, trip.uniqueSchools.first.lng);
    }
    if (trip.uniqueHomeAddresses.isNotEmpty) {
      return LatLng(trip.uniqueHomeAddresses.first.lat, trip.uniqueHomeAddresses.first.lng);
    }
    return null;
  }

  final List<Color> _paletteColors = const [
    AppColors.primaryLight,
    AppColors.secondaryDark,
    AppColors.accentPurple,
    AppColors.accentGreen,
    AppColors.maleBlue,
  ];

  /// حركة سلسة لأيقونة كل حافلة (المفتاح رقم الرحلة)
  final Map<int, SmoothMarkerMotion> _motions = {};

  /// الرحلة اللي الكاميرا تتبع حافلتها
  int? _followTripId;

  SmoothMarkerMotion _motionFor(int tripId) => _motions.putIfAbsent(tripId, () {
        final motion = SmoothMarkerMotion(vsync: this);
        motion.controller.addListener(() => _followMotion(tripId));
        return motion;
      });

  /// الكاميرا تمشي مع الحافلة فريم بفريم بدل ما تقفز
  void _followMotion(int tripId) {
    if (!_followDriver || tripId != _followTripId) return;
    final position = _motions[tripId]?.position;
    if (position == null) return;
    try {
      widget.mapController.move(position, widget.mapController.camera.zoom);
    } catch (_) {
      // الخريطة مازالت ما جهزتش
    }
  }

  void _syncMotions(Map<int, LatLng> targets, int? followTripId) {
    if (!mounted) return;
    _followTripId = followTripId;
    targets.forEach((tripId, target) {
      // قفزة مباشرة (أول موقع) ما تشغّلش أنيميشن، فنحرّك الكاميرا يدوياً
      if (!_motionFor(tripId).moveTo(target)) _followMotion(tripId);
    });
  }

  @override
  void dispose() {
    for (final motion in _motions.values) {
      motion.dispose();
    }
    super.dispose();
  }

  List<LatLng> _getPolylinePoints(int tripId, LatLng driver, LatLng destination) {
    if (!_hasLocation(driver.latitude, driver.longitude) ||
        !_hasLocation(destination.latitude, destination.longitude)) {
      return const [];
    }
    final key = '$tripId->${destination.latitude.toStringAsFixed(5)},${destination.longitude.toStringAsFixed(5)}';
    final tracker = _routeTrackers.putIfAbsent(
      key,
      () => RoadRouteTracker(
        onUpdated: () {
          if (mounted) setState(() {});
        },
      ),
    );
    return tracker.update(driver, [destination]);
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _zoomIn() {
    final currentZoom = widget.mapController.camera.zoom;
    widget.mapController.move(
      widget.mapController.camera.center,
      currentZoom + 1,
    );
  }

  void _zoomOut() {
    final currentZoom = widget.mapController.camera.zoom;
    widget.mapController.move(
      widget.mapController.camera.center,
      currentZoom - 1,
    );
  }

  void _centerDriver() {
    _followDriver = true;
    LatLng target = defaultLocation;

    if (!widget.isMultiMode && widget.singleTrack != null && widget.singleTrack!.driverLat != 0.0 && widget.singleTrack!.driverLng != 0.0) {
      target = LatLng(widget.singleTrack!.driverLat, widget.singleTrack!.driverLng);
    } else if (widget.multiTracks.isNotEmpty) {
      final valid = widget.multiTracks.firstWhere(
        (t) => t.driverLat != 0.0 && t.driverLng != 0.0,
        orElse: () => widget.multiTracks.first,
      );
      if (valid.driverLat != 0.0 && valid.driverLng != 0.0) {
        target = LatLng(valid.driverLat, valid.driverLng);
      }
    } else if (widget.singleTrip != null) {
      if (widget.singleTrip!.uniqueSchools.isNotEmpty) {
        target = LatLng(widget.singleTrip!.uniqueSchools.first.lat, widget.singleTrip!.uniqueSchools.first.lng);
      } else if (widget.singleTrip!.uniqueHomeAddresses.isNotEmpty) {
        target = LatLng(widget.singleTrip!.uniqueHomeAddresses.first.lat, widget.singleTrip!.uniqueHomeAddresses.first.lng);
      }
    } else if (widget.multiTrips.isNotEmpty) {
      final firstTrip = widget.multiTrips.first;
      if (firstTrip.uniqueSchools.isNotEmpty) {
        target = LatLng(firstTrip.uniqueSchools.first.lat, firstTrip.uniqueSchools.first.lng);
      } else if (firstTrip.uniqueHomeAddresses.isNotEmpty) {
        target = LatLng(firstTrip.uniqueHomeAddresses.first.lat, firstTrip.uniqueHomeAddresses.first.lng);
      }
    }

    // الحافلة المرسومة متأخرة شوية على موقعها الحقيقي — نتمركز عليها هي
    final drawnBus = _followTripId != null ? _motions[_followTripId]?.position : null;
    if (drawnBus != null) target = drawnBus;

    debugPrint('🎯 [MAP RE-CENTER] Moving camera to Lat: ${target.latitude}, Lng: ${target.longitude}');
    widget.mapController.move(target, widget.isMultiMode ? 13.5 : 15.0);
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    List<Polyline> polylines = [];
    LatLng initialCenter = defaultLocation;

    // Build effective tracking list for MultiMode
    // الرحلات اللي ما وصلهاش موقع من Firestore تاخذ آخر موقع للسائق من الباك
    // (trip.driver.lat/lng)، ولو ما فيش يقعد (0,0) = "موقع غير معروف":
    // تنرسم وجهاتها بدون حافلة وهمية عند المدرسة
    final List<LiveTrackingModel> effectiveMultiTracks = List.of(widget.multiTracks);
    if (widget.isMultiMode) {
      for (final trip in widget.multiTrips) {
        if (!effectiveMultiTracks.any((t) => t.tripId == trip.tripId)) {
          effectiveMultiTracks.add(
            LiveTrackingModel(
              tripId: trip.tripId,
              status: trip.status,
              driverLat: trip.driver.lat,
              driverLng: trip.driver.lng,
              driverName: trip.driver.name,
              lastUpdated: 'من الباك إند',
            ),
          );
        }
      }
    }

    // Build effective single track
    // لو Firestore ما بعتش موقع، ناخذوا آخر موقع للسائق من الباك فقط —
    // بدون ما نحطوا الحافلة عند البيت أو المدرسة كأنها موقع حقيقي
    LiveTrackingModel? effectiveSingleTrack = widget.singleTrack;
    if (!widget.isMultiMode &&
        (effectiveSingleTrack == null ||
            !_hasLocation(effectiveSingleTrack.driverLat, effectiveSingleTrack.driverLng)) &&
        widget.singleTrip != null) {
      final trip = widget.singleTrip!;
      if (effectiveSingleTrack == null) {
        effectiveSingleTrack = LiveTrackingModel(
          tripId: trip.tripId,
          status: trip.status,
          driverLat: trip.driver.lat,
          driverLng: trip.driver.lng,
          driverName: trip.driver.name,
          lastUpdated: 'من الباك إند',
        );
      } else if (_hasLocation(trip.driver.lat, trip.driver.lng)) {
        effectiveSingleTrack = effectiveSingleTrack.copyWith(
          driverLat: trip.driver.lat,
          driverLng: trip.driver.lng,
        );
      }
    }

    bool anyDriverLocation = false;
    // أيقونات الحافلات تنرسم في طبقة منفصلة تتحرك بسلاسة (فوق باقي العلامات)
    final List<_BusMarker> busMarkers = [];

    if (!widget.isMultiMode && effectiveSingleTrack != null) {
      final hasDriverLocation =
          _hasLocation(effectiveSingleTrack.driverLat, effectiveSingleTrack.driverLng);
      anyDriverLocation = hasDriverLocation;
      final driverLatLng = LatLng(effectiveSingleTrack.driverLat, effectiveSingleTrack.driverLng);
      initialCenter = hasDriverLocation
          ? driverLatLng
          : (_tripAnchor(widget.singleTrip) ?? defaultLocation);

      // Destination / Schools / Home markers with Name Tag above
      // رحلة البديل ترجّع مدارس الأطفال بدون إحداثيات بـ trips/active، فناخذوها من /track
      final List<ChildSchoolModel> uniqueSchools = _nonEmptyOr(
        widget.singleTrip?.uniqueSchools,
        effectiveSingleTrack.uniqueSchools,
      );
      final List<ChildAddressModel> uniqueHomes = _nonEmptyOr(
        widget.singleTrip?.uniqueHomeAddresses,
        effectiveSingleTrack.uniqueHomeAddresses,
      );

      // Render Unique Schools (Deduplicated)
      for (final school in uniqueSchools) {
        final schoolLatLng = LatLng(school.lat, school.lng);
        markers.add(
          Marker(
            point: schoolLatLng,
            width: 110.w,
            height: 75.h,
            child: _buildDestinationMarker(
              context,
              Icons.school_rounded,
              school.name,
            ),
          ),
        );

        if (hasDriverLocation) {
          polylines.add(
            Polyline(
              points: _getPolylinePoints(effectiveSingleTrack.tripId, driverLatLng, schoolLatLng),
              strokeWidth: 5.0,
              color: context.primaryColor,
            ),
          );
        }
      }

      // Render Unique Home Addresses (Deduplicated)
      for (final home in uniqueHomes) {
        final homeLatLng = LatLng(home.lat, home.lng);
        markers.add(
          Marker(
            point: homeLatLng,
            width: 110.w,
            height: 75.h,
            child: _buildDestinationMarker(
              context,
              Icons.home_rounded,
              home.title.isNotEmpty ? home.title : 'المنزل',
            ),
          ),
        );

        if (hasDriverLocation) {
          polylines.add(
            Polyline(
              points: _getPolylinePoints(effectiveSingleTrack.tripId, driverLatLng, homeLatLng),
              strokeWidth: 5.0,
              color: AppColors.accentPurple,
            ),
          );
        }
      }

      // Fallback for destination if unique arrays are empty
      if (uniqueSchools.isEmpty && uniqueHomes.isEmpty) {
        final destName = widget.singleTrip?.destination.name ?? effectiveSingleTrack.destination?.name;
        final destType = widget.singleTrip?.destination.type ?? effectiveSingleTrack.destination?.type ?? 'school';
        final destLat = widget.singleTrip?.destination.lat ?? effectiveSingleTrack.destination?.lat;
        final destLng = widget.singleTrip?.destination.lng ?? effectiveSingleTrack.destination?.lng;

        if (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0) {
          final destLatLng = LatLng(destLat, destLng);
          final isHomeDest = destType.toLowerCase() == 'home';

          markers.add(
            Marker(
              point: destLatLng,
              width: 110.w,
              height: 75.h,
              child: _buildDestinationMarker(
                context,
                isHomeDest ? Icons.home_rounded : Icons.school_rounded,
                (destName != null && destName.isNotEmpty)
                    ? destName
                    : (isHomeDest ? 'المنزل (الوجهة)' : 'المدرسة (الوجهة)'),
              ),
            ),
          );

          if (hasDriverLocation) {
            polylines.add(
              Polyline(
                points: _getPolylinePoints(effectiveSingleTrack.tripId, driverLatLng, destLatLng),
                strokeWidth: 5.0,
                color: isHomeDest ? AppColors.accentPurple : context.primaryColor,
              ),
            );
          }
        }
      }

      // 🌟 DRIVER MARKER ADDED LAST (To render ON TOP of destination/home markers Z-Index)
      // فقط لو موقع السائق الحقيقي متوفر
      if (hasDriverLocation) {
        busMarkers.add(
          _BusMarker(
            tripId: effectiveSingleTrack.tripId,
            target: driverLatLng,
            width: 75.w,
            height: 75.h,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'السائق: ${widget.singleTrip?.driverName ?? effectiveSingleTrack?.driverName ?? "السائق"}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: _buildDriverBusMarker(
                context,
                context.primaryColor,
                widget.singleTrip?.driverName ?? effectiveSingleTrack.driverName ?? 'السائق',
              ),
            ),
          ),
        );
      }
    } else if (widget.isMultiMode && effectiveMultiTracks.isNotEmpty) {
      LatLng? firstLive;
      for (final t in effectiveMultiTracks) {
        if (_hasLocation(t.driverLat, t.driverLng)) {
          firstLive = LatLng(t.driverLat, t.driverLng);
          break;
        }
      }
      anyDriverLocation = firstLive != null;
      initialCenter = firstLive ??
          (widget.multiTrips.isNotEmpty ? _tripAnchor(widget.multiTrips.first) : null) ??
          defaultLocation;

      for (int i = 0; i < effectiveMultiTracks.length; i++) {
        final track = effectiveMultiTracks[i];
        final color = _paletteColors[i % _paletteColors.length];
        final hasDriverLocation = _hasLocation(track.driverLat, track.driverLng);
        final driverLatLng = LatLng(track.driverLat, track.driverLng);

        ActiveTripModel? tripMatch;
        try {
          tripMatch = widget.multiTrips.firstWhere(
            (t) => t.tripId == track.tripId,
          );
        } catch (_) {}

        // Driver Marker — فقط لو موقع السائق الحقيقي متوفر
        if (hasDriverLocation) {
          busMarkers.add(
            _BusMarker(
              tripId: track.tripId,
              target: driverLatLng,
              width: 70.w,
              height: 70.h,
              child: GestureDetector(
                onTap: () {
                  if (widget.onSelectTrip != null) {
                    widget.onSelectTrip!(track.tripId);
                  }
                },
                child: _buildDriverBusMarker(
                  context,
                  color,
                  tripMatch?.driverName ?? track.driverName ?? 'حافلة ${i + 1}',
                ),
              ),
            ),
          );
        }

        // Destination Markers (Deduplicated across tripMatch or track)
        final List<ChildSchoolModel> uniqueSchools = _nonEmptyOr(tripMatch?.uniqueSchools, track.uniqueSchools);
        final List<ChildAddressModel> uniqueHomes =
            _nonEmptyOr(tripMatch?.uniqueHomeAddresses, track.uniqueHomeAddresses);

        if (uniqueSchools.isNotEmpty) {
          for (final school in uniqueSchools) {
            final schoolLatLng = LatLng(school.lat, school.lng);
            markers.add(
              Marker(
                point: schoolLatLng,
                width: 110.w,
                height: 75.h,
                child: _buildDestinationMarker(
                  context,
                  Icons.school_rounded,
                  school.name,
                ),
              ),
            );
            if (hasDriverLocation) {
              polylines.add(
                Polyline(
                  points: _getPolylinePoints(track.tripId, driverLatLng, schoolLatLng),
                  strokeWidth: 5.0,
                  color: color,
                ),
              );
            }
          }
        }

        if (uniqueHomes.isNotEmpty) {
          for (final home in uniqueHomes) {
            final homeLatLng = LatLng(home.lat, home.lng);
            markers.add(
              Marker(
                point: homeLatLng,
                width: 110.w,
                height: 75.h,
                child: _buildDestinationMarker(
                  context,
                  Icons.home_rounded,
                  home.title.isNotEmpty ? home.title : 'المنزل',
                ),
              ),
            );
            if (hasDriverLocation) {
              polylines.add(
                Polyline(
                  points: _getPolylinePoints(track.tripId, driverLatLng, homeLatLng),
                  strokeWidth: 5.0,
                  color: color,
                ),
              );
            }
          }
        }

        if (uniqueSchools.isEmpty && uniqueHomes.isEmpty) {
          final destName = tripMatch?.destination.name ?? track.destination?.name;
          final destType = tripMatch?.destination.type ?? track.destination?.type ?? 'school';
          final destLat = tripMatch?.destination.lat ?? track.destination?.lat;
          final destLng = tripMatch?.destination.lng ?? track.destination?.lng;

          if (destLat != null && destLng != null && destLat != 0.0 && destLng != 0.0) {
            final destLatLng = LatLng(destLat, destLng);
            final isHomeDest = destType.toLowerCase() == 'home';

            markers.add(
              Marker(
                point: destLatLng,
                width: 110.w,
                height: 75.h,
                child: _buildDestinationMarker(
                  context,
                  isHomeDest ? Icons.home_rounded : Icons.school_rounded,
                  (destName != null && destName.isNotEmpty)
                      ? destName
                      : (isHomeDest ? 'المنزل' : 'المدرسة'),
                ),
              ),
            );

            if (hasDriverLocation) {
              polylines.add(
                Polyline(
                  points: _getPolylinePoints(track.tripId, driverLatLng, destLatLng),
                  strokeWidth: 5.0,
                  color: color,
                ),
              );
            }
          }
        }
      }
    }

    debugPrint(
      '\n🗺️ ==================== [MAP RENDER DEBUG] ====================\n'
      'Mode: ${widget.isMultiMode ? "Multi (All Trips)" : "Single (One Child)"}\n'
      'SingleTrack Driver Lat: ${widget.singleTrack?.driverLat}, Lng: ${widget.singleTrack?.driverLng}\n'
      'Effective Single Driver Lat: ${effectiveSingleTrack?.driverLat}, Lng: ${effectiveSingleTrack?.driverLng}\n'
      'Firebase MultiTracks Count: ${widget.multiTracks.length}\n'
      'Effective MultiTracks Count: ${effectiveMultiTracks.length}\n'
      'Total Generated Markers: ${markers.length} | Polylines: ${polylines.length}\n'
      '=================================================================\n',
    );

    // نبدأ الحركة بعد الفريم (تشغيل الأنيميشن أثناء build غير مسموح)
    final busTargets = {for (final bus in busMarkers) bus.tripId: bus.target};
    final followTripId = busMarkers.isNotEmpty ? busMarkers.first.tripId : null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMotions(busTargets, followTripId));

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: widget.isMultiMode ? 13.0 : 15.0,
            // تحريك الخريطة باليد يوقف التتبع التلقائي لين يضغط زر التوسيط
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) _followDriver = false;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.kids_transport.app',
            ),
            // المسار اللي مازال ما وصلش من الشوارع ما ينرسمش (بدل خط مستقيم)
            PolylineLayer(
              polylines: polylines.where((p) => p.points.length >= 2).toList(),
            ),
            MarkerLayer(markers: markers),
            if (busMarkers.isNotEmpty)
              AnimatedBuilder(
                animation: Listenable.merge([
                  for (final bus in busMarkers) _motionFor(bus.tripId).controller,
                ]),
                builder: (context, _) => MarkerLayer(
                  markers: [
                    for (final bus in busMarkers)
                      Marker(
                        point: _motions[bus.tripId]?.position ?? bus.target,
                        width: bus.width,
                        height: bus.height,
                        child: bus.child,
                      ),
                  ],
                ),
              ),
          ],
        ),

        // Live ETA & Distance Overlay Banner for Parents
        if (anyDriverLocation && widget.locationErrorMessage == null && _routeTrackers.isNotEmpty) ...[
          Builder(
            builder: (context) {
              // المسافة والوقت المتبقيين من مسار الحافلة المتتبَّعة (يتحدّثوا مع حركتها)
              final followPrefix = '$followTripId->';
              RouteResult? validResult;
              for (final entry in _routeTrackers.entries) {
                final remaining = entry.value.remaining;
                if (remaining == null || remaining.distanceMeters <= 0) continue;
                if (entry.key.startsWith(followPrefix)) {
                  validResult = remaining;
                  break;
                }
                validResult ??= remaining;
              }
              if (validResult == null) return const SizedBox.shrink();
              final destTitle = widget.singleTrip?.destination.name ??
                  widget.singleTrack?.destination?.name ??
                  'المحطة المستهدفة';
              return Positioned(
                top: 16.h,
                right: 16.w,
                left: 75.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: context.isDarkMode
                          ? AppColors.grey700
                          : AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.directions_bus_filled_rounded,
                          color: AppColors.primaryLight,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'الوصول المتوقع إلى $destTitle',
                              style: AppTextStyles.style(
                                fontSize: 11.sp,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${validResult.formattedDuration} (${validResult.formattedDistance})',
                              style: AppTextStyles.style(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],

        // بانر بدل الحافلة الوهمية: موقع السائق مازال ما وصلش أو فشل جلبه
        if (widget.locationErrorMessage != null ||
            (!anyDriverLocation && (widget.singleTrip != null || widget.multiTrips.isNotEmpty)))
          Positioned(
            top: 16.h,
            right: 16.w,
            left: 75.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: context.isDarkMode ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: widget.locationErrorMessage != null
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.primaryLight.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.locationErrorMessage != null
                        ? Icons.location_off_rounded
                        : Icons.hourglass_bottom_rounded,
                    color: widget.locationErrorMessage != null ? AppColors.error : AppColors.primaryLight,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.locationErrorMessage ?? 'بانتظار موقع السائق…',
                      style: AppTextStyles.style(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: widget.locationErrorMessage != null
                            ? AppColors.error
                            : context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Re-arranged Floating Buttons: 📍 Locate -> 🧭 Navigation -> ➕ Zoom In -> ➖ Zoom Out
        Positioned(
          left: 16.w,
          top: 16.h,
          child: Column(
            children: [
              _buildFloatingBtn(
                icon: Icons.my_location_rounded,
                tooltip: 'إعادة التوسيط ومتابعة موقع الحافلة',
                onPressed: _centerDriver,
              ),
              SizedBox(height: 10.h),
              _buildFloatingBtn(
                icon: Icons.near_me_rounded,
                tooltip: 'فتح المسار في Google Maps',
                color: AppColors.green,
                iconColor: AppColors.white,
                onPressed: () {
                  if (widget.singleTrack != null) {
                    _openGoogleMaps(
                      widget.singleTrack!.driverLat,
                      widget.singleTrack!.driverLng,
                    );
                  } else if (widget.multiTracks.isNotEmpty) {
                    _openGoogleMaps(
                      widget.multiTracks.first.driverLat,
                      widget.multiTracks.first.driverLng,
                    );
                  }
                },
              ),
              SizedBox(height: 10.h),
              _buildFloatingBtn(
                icon: Icons.add_rounded,
                tooltip: 'تكبير الخريطة',
                onPressed: _zoomIn,
              ),
              SizedBox(height: 10.h),
              _buildFloatingBtn(
                icon: Icons.remove_rounded,
                tooltip: 'تصغير الخريطة',
                onPressed: _zoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverBusMarker(
    BuildContext context,
    Color color,
    String driverName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus_filled_rounded,
            color: AppColors.white,
            size: 24.r,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationMarker(
    BuildContext context,
    IconData icon,
    String destinationName,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Destination Label Pill
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: context.isDarkMode ? context.cardSurface : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.red, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            destinationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.style(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: const BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.white, size: 18.r),
        ),
      ],
    );
  }

  Widget _buildFloatingBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    Color? iconColor,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        color: color ?? (isDark ? context.cardSurface : AppColors.white),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: 22.r,
            color: iconColor ?? (isDark ? AppColors.white : AppColors.textDark),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// بيانات أيقونة حافلة: موقعها الحقيقي الأخير وشكلها — الموقع المرسوم فعلياً
/// يجي من SmoothMarkerMotion
class _BusMarker {
  final int tripId;
  final LatLng target;
  final double width;
  final double height;
  final Widget child;

  const _BusMarker({
    required this.tripId,
    required this.target,
    required this.width,
    required this.height,
    required this.child,
  });
}
