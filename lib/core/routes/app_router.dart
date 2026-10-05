import 'package:kids_transport/features/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kids_transport/features/app_entry/presentation/screens/onboarding_screen.dart';
import 'package:kids_transport/features/app_entry/presentation/screens/splash_screen.dart';
import 'package:kids_transport/features/auth/login/presentation/screens/forgot_password_screen.dart';
import 'package:kids_transport/features/auth/login/presentation/screens/login_screen.dart';
import 'package:kids_transport/features/auth/login/presentation/screens/reset_password_screen.dart';
import 'package:kids_transport/features/auth/login/presentation/screens/verify_otp_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/select_role_screen.dart';
import 'package:kids_transport/features/auth/change_password/presentation/screens/change_password_screen.dart';
import 'package:kids_transport/features/auth/change_password/logic/change_password_cubit.dart';

import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_avatar_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_basic_info_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_docs_stage_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_location_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_otp_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_vehicle_stage_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/driver/driver_waiting_screen.dart';

import 'package:kids_transport/features/auth/registration/presentation/screens/parent/parent_avatar_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/parent/parent_basic_info_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/parent/parent_email_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/parent/parent_location_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/parent/parent_add_first_child_screen.dart';
import 'package:kids_transport/features/parent/children/presentation/screens/add_child_screen.dart';
import 'package:kids_transport/features/auth/registration/presentation/screens/parent/parent_otp_screen.dart';

import 'package:kids_transport/features/driver/dashboard/presentation/screens/driver_main_wrapper.dart';
import 'package:kids_transport/features/driver/home/presentation/screens/driver_home_screen.dart';
import 'package:kids_transport/features/driver/profile/presentation/screens/driver_profile_screen.dart';
import 'package:kids_transport/features/driver/vehicles/presentation/screens/driver_primary_vehicle_screen.dart';
import 'package:kids_transport/features/driver/vehicles/logic/vehicle_cubit.dart';

import 'package:kids_transport/features/driver/profile/logic/cubit/driver_profile_cubit.dart';
import 'package:kids_transport/features/driver/shared/di/driver_injection.dart';
import 'package:kids_transport/features/driver/driver_preferences/logic/driver_preferences_cubit.dart';
import 'package:kids_transport/features/driver/driver_preferences/presentation/screens/driver_preferences_screen.dart';
import 'package:kids_transport/features/driver/subscriptions/presentation/screens/driver_subscription_details_screen.dart';
import 'package:kids_transport/features/driver/subscriptions/logic/driver_subscriptions_cubit.dart';

// Driver Trips Feature
import 'package:kids_transport/features/driver/trips/presentation/screens/trip_details_screen.dart'
    as driver_trips;
import 'package:kids_transport/features/driver/trips/presentation/screens/live_trip_screen.dart';
import 'package:kids_transport/features/driver/trips/presentation/screens/trip_history_screen.dart'
    as driver_trips;
import 'package:kids_transport/features/driver/trips/presentation/screens/trip_history_details_screen.dart';
import 'package:kids_transport/features/driver/trips/presentation/screens/driver_absence_screen.dart';
import 'package:kids_transport/features/driver/trips/logic/driver_trips_cubit/driver_trips_cubit.dart';
import 'package:kids_transport/features/driver/trips/logic/live_trip_cubit/live_trip_cubit.dart';
import 'package:kids_transport/features/driver/trips/logic/driver_trips_history_cubit/driver_trips_history_cubit.dart';
import 'package:kids_transport/features/driver/trips/logic/driver_absence_cubit/driver_absence_cubit.dart';
import 'package:kids_transport/features/driver/statistics/presentation/screen/driver_statistics_screen.dart';
import 'package:kids_transport/features/driver/statistics/logic/cubit/driver_statistics_cubit.dart';
import 'package:kids_transport/features/driver/requests/presentation/screens/driver_requests_screen.dart';
import 'package:kids_transport/features/driver/requests/presentation/screens/driver_request_details_screen.dart';
import 'package:kids_transport/features/driver/requests/logic/driver_requests_cubit.dart';
import 'package:kids_transport/features/driver/requests/presentation/screens/driver_location_change_requests_screen.dart';
import 'package:kids_transport/features/driver/requests/logic/driver_location_change_cubit.dart';
import 'package:kids_transport/features/driver/trips/presentation/screens/driver_emergency_dispatches_screen.dart';
import 'package:kids_transport/features/driver/trips/presentation/screens/emergency_dispatch_details_screen.dart';
import 'package:kids_transport/features/driver/trips/logic/driver_emergency_cubit/driver_emergency_cubit.dart';

import 'package:kids_transport/features/parent/addresses/presentation/screens/saved_addresses_screen.dart';
import 'package:kids_transport/features/parent/children/data/models/child_model.dart';
import 'package:kids_transport/features/parent/subscriptions/data/models/active_subscription_model.dart';
import 'package:kids_transport/features/parent/children/presentation/screens/child_data_details_screen.dart';
import 'package:kids_transport/features/parent/children/presentation/screens/my_children_screen.dart';
import 'package:kids_transport/features/parent/children/presentation/screens/transport_details_screen.dart';
import 'package:kids_transport/features/parent/dashboard/presentation/screens/parent_main_wrapper.dart';
import 'package:kids_transport/features/parent/home/presentation/screens/parent_home_screen.dart';
import 'package:kids_transport/features/parent/profile/presentation/screens/parent_profile_screen.dart';
import 'package:kids_transport/features/parent/subscriptions/presentation/screens/subscription_details_screen.dart';
import 'package:kids_transport/features/parent/subscriptions/logic/subscriptions_cubit/subscriptions_cubit.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/features/parent/profile/logic/cubit/parent_profile_cubit.dart';

// Wallet & Finance
import 'package:kids_transport/features/parent/wallet/presentation/screens/wallet_screen.dart';
import 'package:kids_transport/features/parent/wallet/presentation/screens/recharge_screen.dart';
import 'package:kids_transport/features/parent/wallet/presentation/screens/recharge_confirmation_screen.dart';
import 'package:kids_transport/features/parent/wallet/data/models/recharge_response_model.dart';
import 'package:kids_transport/features/parent/wallet/presentation/screens/invoices_screen.dart';
import 'package:kids_transport/features/parent/wallet/presentation/screens/invoice_details_screen.dart';
import 'package:kids_transport/features/parent/wallet/logic/wallet_cubit/wallet_cubit.dart';

// Trips & Live Tracking
import 'package:kids_transport/features/parent/trips/data/models/active_trip_model.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/trips_home_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/trip_tracking_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/child_tracking_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/child_details_in_trip_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/full_tracking_map_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/upcoming_trips_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/trip_history_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/trip_details_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/trip_timeline_screen.dart';
import 'package:kids_transport/features/parent/trips/presentation/screens/child_trips_screen.dart';
import 'package:kids_transport/features/parent/location_change/presentation/screens/parent_location_change_screen.dart';
import 'package:kids_transport/features/parent/location_change/presentation/screens/location_change_history_screen.dart';

// Complaints
import 'package:kids_transport/features/parent/complaints/presentation/screens/complaints_list_screen.dart';
import 'package:kids_transport/features/parent/complaints/presentation/screens/create_complaint_screen.dart';
import 'package:kids_transport/features/parent/complaints/presentation/screens/complaint_details_screen.dart';

// Absence
import 'package:kids_transport/features/parent/absence/presentation/screens/absence_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgotPassword';
  static const String verifyOtp = '/verifyOtp';
  static const String resetPassword = '/resetPassword';
  static const String selectRole = '/selectRole';
  static const String notifications = '/notifications';
  static const String changePassword = '/changePassword';

  static const String adminLogin = '/adminLogin';
  static const String adminDashboard = '/admin/dashboard';

  static const String parentHome = '/parentHome';
  static const String parentHomeLegacy = '/home';
  static const String parentMainWrapper = '/parentMainWrapper';
  static const String parentProfile = '/parentProfile';
  static const String parentSubscriptions = '/parent-subscriptions';
  static const String savedAddresses = '/savedAddresses';
  static const String myChildren = '/my-children';
  static const String addChild = '/add-child';

  // Parent Wallet & Finance Routes
  static const String parentWallet = '/parent-wallet';
  static const String parentRecharge = '/parent-recharge';
  static const String parentRechargeConfirmation =
      '/parent-recharge-confirmation';
  static const String parentInvoices = '/parent-invoices';
  static const String parentInvoiceDetails = '/parent-invoice-details';

  // Parent Trips & Live Tracking Routes
  static const String parentTripsHome = '/parent-trips-home';
  static const String parentTrips = '/parent-trips';
  static const String parentTripTracking = '/parent-trip-tracking';
  static const String parentTracking = '/parent-tracking';
  static const String parentChildTracking = '/parent-child-tracking';
  static const String parentChildDetailsInTrip =
      '/parent-child-details-in-trip';
  static const String parentFullTrackingMap = '/parent-full-tracking-map';
  static const String parentUpcomingTrips = '/parent-upcoming-trips';
  static const String parentTripHistory = '/parent-trip-history';
  static const String parentTripDetails = '/parent-trip-details';
  static const String parentTripTimeline = '/parent-trip-timeline';
  static const String parentChildTrips = '/parent-child-trips';
  static const String parentLocationChange = '/parent-location-change';
  static const String parentLocationChangeHistory =
      '/parent-location-change-history';

  // Parent Complaints Routes
  static const String parentComplaints = '/parent-complaints';
  static const String createComplaint = '/create-complaint';
  static const String complaintDetails = '/complaint-details';

  // Parent Absence Route
  static const String parentAbsence = '/parent-absence';

  // ===== Driver Features =====
  static const String addChildStep1 = '/children/add/step1';
  static const String addChildStep2 = '/children/add/step2';
  static const String childDetail = '/childDetail';
  static const String childDataDetails = '/children/data';
  static const String childPass = '/children/pass';
  static const String transportDetails = '/children/transport';
  static const String subscriptionDetails = '/parent/subscriptionDetails';

  static const String parentEmail = '/parentEmail';
  static const String parentOtp = '/parentOtp';
  static const String parentBasicInfo = '/parentBasicInfo';
  static const String parentAvatar = '/parentAvatar';
  static const String parentAlternativePhone = '/parentAlternativePhone';
  static const String parentLocation = '/parentLocation';
  static const String parentAddFirstChild = '/parentAddFirstChild';

  static const String driverHome = '/driverHome';
  static const String driverMainWrapper = '/driverMainWrapper';
  static const String driverBackupVehicle = '/driverBackupVehicle';
  static const String driverProfile = '/driverProfile';
  static const String driverPrimaryVehicle = '/driverPrimaryVehicle';
  static const String driverPreferences = '/driverPreferences';

  static const String driverBasicInfo = '/driverBasicInfo';
  static const String driverAvatar = '/driverAvatar';
  static const String driverAlternativePhone = '/driverAlternativePhone';
  static const String driverOtp = '/driverOtp';
  static const String driverNationalInfo = '/driverNationalInfo';
  static const String driverVehicleStage = '/driverVehicleStage';
  static const String driverDocsStage = '/driverDocsStage';
  static const String driverLocation = '/driverLocation';
  static const String driverWaiting = '/driverWaiting';
  static const String driverSubscriptionDetails = '/driverSubscriptionDetails';

  // Driver Trips Routes
  static const String driverTripDetails = '/driverTripDetails';
  static const String driverLiveTrip = '/driverLiveTrip';
  static const String driverTripsHistory = '/driverTripsHistory';
  static const String driverTripHistoryDetails = '/driverTripHistoryDetails';
  static const String driverAbsence = '/driverAbsence';
  static const String driverStatistics = '/driverStatistics';
  static const String driverLocationChangeRequests =
      '/driver-location-change-requests';
  static const String driverEmergencyDispatches =
      '/driver-emergency-dispatches';
  static const String driverEmergencyDispatchDetails =
      '/driver-emergency-dispatch-details';
  static const String driverRequests = '/driver-requests';
  static const String driverRequestDetails = '/driver-request-details';

  static String getInitialRoute() {
    return splash;
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final entryRoute = _buildEntryAndAuthRoutes(settings);
    if (entryRoute != null) return entryRoute;

    final parentRoute = _buildParentRoutes(settings);
    if (parentRoute != null) return parentRoute;

    final driverRoute = _buildDriverRoutes(settings);
    if (driverRoute != null) return driverRoute;

    return _errorRoute('الشاشة غير موجودة!');
  }

  static Route<dynamic>? _buildEntryAndAuthRoutes(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _route(settings, const SplashScreen());
      case onboarding:
        return _route(settings, const OnboardingScreen());
      case login:
        return _route(settings, const LoginScreen());
      case forgotPassword:
        return _route(settings, const ForgotPasswordScreen());
      case verifyOtp:
        final email = settings.arguments as String;
        return _route(settings, VerifyOtpScreen(email: email));
      case resetPassword:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(
          settings,
          ResetPasswordScreen(email: args['email'] as String),
        );
      case selectRole:
        return _route(settings, const SelectRoleScreen());
      case notifications:
        return _route(settings, const NotificationsScreen());
      case changePassword:
        final isDriver = settings.arguments as bool?;
        return _route(
          settings,
          BlocProvider(
            create: (_) => getIt<ChangePasswordCubit>(),
            child: ChangePasswordScreen(isDriver: isDriver),
          ),
        );
      default:
        return null;
    }
  }

  static Route<dynamic>? _buildParentRoutes(RouteSettings settings) {
    switch (settings.name) {
      case parentHome:
      case parentMainWrapper:
        final initialTab = settings.arguments as int? ?? 0;
        return _route(
          settings,
          BlocProvider.value(
            value: getIt<ParentProfileCubit>()..fetchProfile(),
            child: ParentMainWrapper(initialIndex: initialTab),
          ),
        );
      case parentHomeLegacy:
        return _route(settings, const ParentHomeScreen());
      case parentProfile:
        return _route(
          settings,
          BlocProvider.value(
            value: getIt<ParentProfileCubit>(),
            child: const ParentProfileScreen(),
          ),
        );
      case savedAddresses:
        return _route(settings, const SavedAddressesScreen());
      case myChildren:
        return _route(settings, const MyChildrenScreen());
      case addChild:
      case addChildStep1:
      case addChildStep2:
        final childArg = settings.arguments is ChildModel
            ? settings.arguments as ChildModel
            : null;
        return _route(settings, AddChildScreen(childToEdit: childArg));
      case childDetail:
      case childDataDetails:
        return _childRoute(
          settings,
          (child) => ChildDataDetailsScreen(child: child),
        );

      case transportDetails:
        return _childRoute(
          settings,
          (child) => TransportDetailsScreen(child: child),
        );
      case subscriptionDetails:
        final args = settings.arguments;
        if (args is ActiveSubscriptionModel) {
          return _route(
            settings,
            BlocProvider(
              create: (_) => getIt<SubscriptionsCubit>(),
              child: SubscriptionDetailsScreen(subscription: args),
            ),
          );
        }
        final subscriptionId = args as int? ?? 0;
        return _route(
          settings,
          BlocProvider(
            create: (_) => getIt<SubscriptionsCubit>(),
            child: SubscriptionDetailsScreen(subscriptionId: subscriptionId),
          ),
        );

      // --- Wallet & Finance ---
      case parentWallet:
        return _route(settings, const WalletScreen());
      case parentRecharge:
        final walletCubit = settings.arguments as WalletCubit;
        return _route(
          settings,
          BlocProvider.value(value: walletCubit, child: const RechargeScreen()),
        );
      case parentRechargeConfirmation:
        final args = settings.arguments as Map<String, dynamic>;
        final walletCubit = args['cubit'] as WalletCubit;
        final initData = args['initData'] as RechargeInitiateResponseModel;
        return _route(
          settings,
          BlocProvider.value(
            value: walletCubit,
            child: RechargeConfirmationScreen(initData: initData),
          ),
        );
      case parentInvoices:
        return _route(settings, const InvoicesScreen());
      case parentInvoiceDetails:
        final id = settings.arguments as int;
        return _route(settings, InvoiceDetailsScreen(invoiceId: id));

      // --- Trips & Live Tracking ---
      case parentTripsHome:
      case parentTrips:
        return _route(settings, const TripsHomeScreen());
      case parentTripTracking:
      case parentTracking:
        ActiveTripModel? tripArg;
        List<ActiveTripModel> allTripsArg = [];
        if (settings.arguments is ActiveTripModel) {
          tripArg = settings.arguments as ActiveTripModel;
        } else if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          tripArg = args['trip'] as ActiveTripModel?;
          if (args['allTrips'] is List<ActiveTripModel>) {
            allTripsArg = args['allTrips'] as List<ActiveTripModel>;
          }
        }
        return _route(
          settings,
          TripTrackingScreen(trip: tripArg, allActiveTrips: allTripsArg),
        );
      case parentUpcomingTrips:
        return _route(settings, const UpcomingTripsScreen());
      case parentTripHistory:
        return _route(settings, const TripHistoryScreen());
      case parentTripDetails:
        final tripId = settings.arguments;
        return _route(settings, TripDetailsScreen(tripId: tripId));
      case parentTripTimeline:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(
          settings,
          TripTimelineScreen(
            tripTitle: args['title']?.toString() ?? 'الرحلة',
            timelineItems: args['timeline'] ?? [],
          ),
        );
      case parentChildTrips:
        final childId = settings.arguments;
        return _route(settings, ChildTripsScreen(childId: childId));
      case parentLocationChange:
        return _route(settings, const ParentLocationChangeScreen());
      case parentLocationChangeHistory:
        return _route(settings, const LocationChangeHistoryScreen());
      case parentChildTracking:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(
          settings,
          ChildTrackingScreen(
            childId: args['childId'] as int,
            childName: args['childName'] as String,
            childPhoto: args['childPhoto'] as String?,
            trip: args['trip'] as ActiveTripModel,
          ),
        );
      case parentChildDetailsInTrip:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(
          settings,
          ChildDetailsInTripScreen(
            trip: args['trip'] as ActiveTripModel,
            child: args['child'] as TripChildInfo,
          ),
        );
      case parentFullTrackingMap:
        final args = settings.arguments as Map<String, dynamic>?;
        return _route(
          settings,
          FullTrackingMapScreen(
            selectedTrip: args?['selectedTrip'] as ActiveTripModel?,
            allTrips: (args?['allTrips'] as List<ActiveTripModel>?) ?? const [],
          ),
        );

      // --- Complaints ---
      case parentComplaints:
        return _route(settings, const ComplaintsListScreen());
      case createComplaint:
        final args = settings.arguments as Map<String, dynamic>?;
        return _route(
          settings,
          CreateComplaintScreen(
            driverId: args?['driverId'] as int?,
            driverName: args?['driverName'] as String?,
            driverAvatar: args?['driverAvatar'] as String?,
          ),
        );
      case complaintDetails:
        final id = settings.arguments as int;
        return _route(settings, ComplaintDetailsScreen(complaintId: id));

      // --- Absence ---
      case parentAbsence:
        final args = settings.arguments as Map<String, dynamic>?;
        return _route(
          settings,
          AbsenceScreen(
            initialChildId: args?['childId'] as int?,
            initialChildName: args?['childName'] as String?,
          ),
        );

      case parentEmail:
        return _route(settings, const ParentEmailScreen());
      case parentOtp:
        final email = settings.arguments as String;
        return _route(settings, ParentOtpScreen(email: email));
      case parentBasicInfo:
        return _route(settings, const ParentBasicInfoScreen());
      case parentAvatar:
        return _route(settings, const ParentAvatarScreen());
      case parentLocation:
        return _route(settings, const ParentLocationScreen());
      case parentAddFirstChild:
        return _route(settings, const ParentAddFirstChildScreen());
      default:
        return null;
    }
  }

  static Route<dynamic>? _buildDriverRoutes(RouteSettings settings) {
    switch (settings.name) {
      case driverHome:
        return _route(settings, const DriverHomeScreen());
      case driverMainWrapper:
        return _route(settings, const DriverMainWrapper());
      /*case driverBackupVehicle:
        return _route(settings, const DriverBackupVehicleScreen());*/
      case driverPrimaryVehicle:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<VehicleCubit>(),
            child: const DriverPrimaryVehicleScreen(),
          ),
        );
      case driverProfile:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverProfileCubit>(),
            child: const DriverProfileScreen(),
          ),
        );
      case driverBasicInfo:
        return _route(settings, const DriverBasicInfoScreen());
      case driverAvatar:
        return _route(settings, const DriverAvatarScreen());

      case driverOtp:
        return _route(settings, const DriverOtpScreen());
      case driverVehicleStage:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _route(settings, DriverVehicleStageScreen(collectedData: args));
      case driverDocsStage:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _route(settings, DriverDocsStageScreen(finalData: args));
      case driverLocation:
        return _route(settings, const DriverLocationScreen());
      case driverWaiting:
        return _route(settings, const DriverWaitingScreen());
      case driverPreferences:
        final isMandatory = settings.arguments as bool? ?? false;
        return _route(
          settings,
          BlocProvider(
            create: (context) => driverSl<DriverPreferencesCubit>(),
            child: DriverPreferencesScreen(isMandatory: isMandatory),
          ),
        );
      case driverSubscriptionDetails:
        final subscriptionId = settings.arguments as int;
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverSubscriptionsCubit>(),
            child: DriverSubscriptionDetailsScreen(
              subscriptionId: subscriptionId,
            ),
          ),
        );
      case driverTripDetails:
        final tripId = settings.arguments as int;
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverTripsCubit>(),
            child: driver_trips.TripDetailsScreen(tripId: tripId),
          ),
        );
      case driverLiveTrip:
        final tripId = settings.arguments as int;
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<LiveTripCubit>(),
            child: LiveTripScreen(tripId: tripId),
          ),
        );
      case driverTripsHistory:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverTripsHistoryCubit>(),
            child: const driver_trips.TripHistoryScreen(),
          ),
        );
      case driverTripHistoryDetails:
        final tripId = settings.arguments as int;
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverTripsHistoryCubit>(),
            child: TripHistoryDetailsScreen(tripId: tripId),
          ),
        );
      case driverAbsence:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverAbsenceCubit>(),
            child: const DriverAbsenceScreen(),
          ),
        );
      case driverStatistics:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverStatisticsCubit>()..loadStatistics(),
            child: const DriverStatisticsScreen(),
          ),
        );
      case driverLocationChangeRequests:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverLocationChangeCubit>(),
            child: const DriverLocationChangeRequestsScreen(),
          ),
        );
      case driverEmergencyDispatches:
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverEmergencyCubit>(),
            child: const DriverEmergencyDispatchesScreen(),
          ),
        );
      case driverEmergencyDispatchDetails:
        final dispatchId = settings.arguments as int;
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverEmergencyCubit>(),
            child: EmergencyDispatchDetailsScreen(dispatchId: dispatchId),
          ),
        );
      case driverRequests:
        return _route(
          settings,
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => driverSl<DriverRequestsCubit>()..loadRequests(),
              ),
              BlocProvider(
                create: (_) => driverSl<DriverSubscriptionsCubit>(),
              ),
            ],
            child: const DriverRequestsScreen(),
          ),
        );
      case driverRequestDetails:
        final requestId = settings.arguments as int;
        return _route(
          settings,
          BlocProvider(
            create: (_) => driverSl<DriverRequestsCubit>(),
            child: DriverRequestDetailsScreen(requestId: requestId),
          ),
        );

      default:
        return null;
    }
  }

  static MaterialPageRoute<dynamic> _route(
    RouteSettings settings,
    Widget screen,
  ) {
    return MaterialPageRoute(settings: settings, builder: (_) => screen);
  }

  static Route<dynamic> _childRoute(
    RouteSettings settings,
    Widget Function(ChildModel child) builder,
  ) {
    final child = settings.arguments;
    if (child is! ChildModel) {
      return _errorRoute('بيانات الطفل غير موجودة.');
    }

    return _route(settings, builder(child));
  }

  static MaterialPageRoute<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(body: Center(child: Text(message))),
    );
  }
}
