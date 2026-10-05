import 'package:flutter/material.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/features/auth/login/data/repositories/session_repository.dart';
import 'package:kids_transport/main.dart' show navigatorKey;
import 'app_router.dart';

class NotificationNavigationHandler {
  static Map<String, dynamic>? _pendingNotification;

  static Map<String, dynamic>? get pendingNotification => _pendingNotification;

  static void clearPending() {
    _pendingNotification = null;
  }

  static void handleNotificationTap(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    final state = navigatorKey.currentState;

    if (state == null || context == null) {
      _pendingNotification = data;
      return;
    }

    final sessionRepo = getIt<SessionRepository>();
    if (!sessionRepo.hasValidSession()) {
      _pendingNotification = data;
      return;
    }

    _pendingNotification = null;
    _executeNavigation(state, data, sessionRepo.getRoleName());
  }

  static void handlePendingNotification() {
    final state = navigatorKey.currentState;
    if (state == null || _pendingNotification == null) return;

    final sessionRepo = getIt<SessionRepository>();
    if (!sessionRepo.hasValidSession()) return;

    final data = _pendingNotification!;
    _pendingNotification = null;
    _executeNavigation(state, data, sessionRepo.getRoleName());
  }

  static void _executeNavigation(NavigatorState state, Map<String, dynamic> data, String? role) {
    final String screen = (data['screen']?.toString() ?? '').toUpperCase();
    final String entityIdStr = data['entity_id']?.toString() ??
        data['trip_id']?.toString() ??
        data['subscription_id']?.toString() ??
        data['id']?.toString() ??
        '';
    final int? entityId = int.tryParse(entityIdStr);

    final bool isDriver = role?.toLowerCase() == 'driver';
    final bool isParent = !isDriver;

    if (isParent) {
      switch (screen) {
        case 'TRIP_DETAILS':
        case 'TRIP_TRACKING':
          if (entityId != null) {
            state.pushNamed(
              AppRoutes.parentTripDetails,
              arguments: entityId,
            );
          }
          break;

        case 'INVOICE_DETAILS':
          if (entityId != null) {
            state.pushNamed(AppRoutes.parentInvoiceDetails, arguments: entityId);
          }
          break;
        case 'WALLET':
          state.pushNamed(AppRoutes.parentWallet);
          break;
        case 'SUBSCRIPTION_DETAILS':
          if (entityId != null) {
            state.pushNamed(AppRoutes.subscriptionDetails, arguments: entityId);
          }
          break;
        default:
          state.pushNamed(AppRoutes.parentHome);
          break;
      }
    } else if (isDriver) {
      switch (screen) {
        case 'DRIVER_TRIP_DETAILS':
        case 'TRIP_DETAILS':
          if (entityId != null) {
            state.pushNamed(AppRoutes.driverTripDetails, arguments: entityId);
          }
          break;
        case 'DRIVER_LIVE_TRIP':
        case 'LIVE_TRIP':
          if (entityId != null) {
            state.pushNamed(AppRoutes.driverLiveTrip, arguments: entityId);
          }
          break;
        case 'DRIVER_SUBSCRIPTION_DETAILS':
        case 'SUBSCRIPTION_DETAILS':
          if (entityId != null) {
            state.pushNamed(AppRoutes.driverSubscriptionDetails, arguments: entityId);
          }
          break;
        // نداء إنقاذ لسائق بديل: entity_id هو رقم المهمة (dispatch_id)
        case 'EMERGENCY_DISPATCH':
          final dispatchId = int.tryParse(data['dispatch_id']?.toString() ?? '') ?? entityId;
          if (dispatchId != null) {
            state.pushNamed(AppRoutes.driverEmergencyDispatchDetails, arguments: dispatchId);
          } else {
            state.pushNamed(AppRoutes.driverEmergencyDispatches);
          }
          break;
        default:
          state.pushNamed(AppRoutes.driverHome);
          break;
      }
    }
  }
}
