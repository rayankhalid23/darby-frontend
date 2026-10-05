import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  bool get _isDriver {
    final role = StorageService.getRoleName()?.toLowerCase().trim();
    return role == 'driver';
  }

  bool get _isParent {
    final role = StorageService.getRoleName()?.toLowerCase().trim();
    return role == 'parent' || role == 'guardian';
  }

  String get _notificationsEndpoint {
    if (_isDriver) return ApiEndpoints.driverNotifications;
    if (_isParent) return ApiEndpoints.parentNotifications;
    return ApiEndpoints.notifications;
  }

  String get _unreadCountEndpoint {
    if (_isDriver) return ApiEndpoints.driverNotificationsUnreadCount;
    if (_isParent) return ApiEndpoints.parentNotificationsUnreadCount;
    return ApiEndpoints.notificationsUnreadCount;
  }

  String _markReadEndpoint(String id) {
    if (_isDriver) return ApiEndpoints.driverMarkNotificationRead(id);
    if (_isParent) return ApiEndpoints.parentMarkNotificationRead(id);
    return ApiEndpoints.markNotificationRead(id);
  }

  String get _markAllReadEndpoint {
    if (_isDriver) return ApiEndpoints.driverMarkAllNotificationsRead;
    if (_isParent) return ApiEndpoints.parentMarkAllNotificationsRead;
    return ApiEndpoints.markAllNotificationsRead;
  }

  Map<String, dynamic> get _authHeader {
    final auth = StorageService.getAuthorizationHeader();
    if (auth == null || auth.isEmpty) return {};
    return {'Authorization': auth};
  }

  Future<Response<dynamic>> getNotifications({
    int page = 1,
    int? perPage,
    bool? unreadOnly,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': ?perPage,
      'unread_only': ?unreadOnly,
      if (type != null && type.isNotEmpty) 'type': type,
    };

    final primaryEndpoint = _notificationsEndpoint;

    try {
      return await _apiClient.get(
        primaryEndpoint,
        queryParameters: queryParams,
        headers: _authHeader,
      );
    } on DioException catch (e) {
      if (primaryEndpoint != ApiEndpoints.notifications &&
          e.response?.statusCode == 404) {
        return await _apiClient.get(
          ApiEndpoints.notifications,
          queryParameters: queryParams,
          headers: _authHeader,
        );
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> getUnreadCount() async {
    final primaryEndpoint = _unreadCountEndpoint;

    try {
      return await _apiClient.get(
        primaryEndpoint,
        headers: _authHeader,
      );
    } on DioException catch (e) {
      if (primaryEndpoint != ApiEndpoints.notificationsUnreadCount &&
          e.response?.statusCode == 404) {
        return await _apiClient.get(
          ApiEndpoints.notificationsUnreadCount,
          headers: _authHeader,
        );
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> markAsRead(String id) async {
    final primaryEndpoint = _markReadEndpoint(id);

    try {
      return await _apiClient.post(
        primaryEndpoint,
        headers: _authHeader,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 405 || e.response?.statusCode == 404) {
        try {
          return await _apiClient.patch(
            primaryEndpoint,
            headers: _authHeader,
          );
        } on DioException catch (e2) {
          if (primaryEndpoint != ApiEndpoints.markNotificationRead(id) &&
              e2.response?.statusCode == 404) {
            return await _apiClient.post(
              ApiEndpoints.markNotificationRead(id),
              headers: _authHeader,
            );
          }
          rethrow;
        }
      }
      if (primaryEndpoint != ApiEndpoints.markNotificationRead(id) &&
          e.response?.statusCode == 404) {
        return await _apiClient.post(
          ApiEndpoints.markNotificationRead(id),
          headers: _authHeader,
        );
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> markAllAsRead() async {
    final primaryEndpoint = _markAllReadEndpoint;

    try {
      return await _apiClient.post(
        primaryEndpoint,
        headers: _authHeader,
      );
    } on DioException catch (e) {
      if (primaryEndpoint != ApiEndpoints.markAllNotificationsRead &&
          e.response?.statusCode == 404) {
        return await _apiClient.post(
          ApiEndpoints.markAllNotificationsRead,
          headers: _authHeader,
        );
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> deleteNotification(String id) async {
    return await _apiClient.delete(
      ApiEndpoints.deleteNotification(id),
      headers: _authHeader,
    );
  }

  Future<Response<dynamic>> registerDeviceToken(Map<String, dynamic> body) async {
    return await _apiClient.post(
      ApiEndpoints.registerDeviceToken,
      data: body,
      headers: _authHeader,
    );
  }

  Future<Response<dynamic>> removeDeviceToken(String deviceId) async {
    return await _apiClient.delete(
      ApiEndpoints.deleteDeviceToken,
      data: {'device_id': deviceId},
      headers: _authHeader,
    );
  }

  Future<Response<dynamic>> logoutAllDevices() async {
    return await _apiClient.post(
      ApiEndpoints.logoutAllDevices,
      headers: _authHeader,
    );
  }
}

