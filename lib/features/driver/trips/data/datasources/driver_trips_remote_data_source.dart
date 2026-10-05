import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kids_transport/core/network/api_client.dart';
import 'package:kids_transport/core/network/api_endpoints.dart';
import 'package:kids_transport/core/network/api_exception.dart';
import 'package:kids_transport/core/services/storage_service.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_absence_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_details_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_history_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_live_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/driver_trip_stop_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/proximity_alert_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/trip_action_result_model.dart';
import 'package:kids_transport/features/driver/trips/data/models/vehicle_breakdown_model.dart';

/// مصدر بيانات الرحلات الخاص بالسائق — مرتبط 100% بالـ Backend الحقيقي
class DriverTripsRemoteDataSource {
  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;

  DriverTripsRemoteDataSource(this._apiClient, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Map<String, dynamic> get _authHeader {
    final token = StorageService.getAuthorizationHeader();
    return {'Authorization': token ?? ''};
  }

  /// يتحقق من غلاف الاستجابة {"status": "success"|"error", ...} ويرمي استثناء عند الفشل
  Map<String, dynamic> _unwrap(dynamic raw, String fallbackMessage) {
    if (raw is! Map) {
      throw ApiException(fallbackMessage);
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['status'] == 'error') {
      final msg = ApiException.extractMessage(map) ?? fallbackMessage;
      throw ApiException(msg, errorCode: map['error_code']?.toString());
    }
    return map;
  }

  Future<List<DriverTripModel>> fetchTripsToday({String? date}) async {
    final localTodayDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final response = await _apiClient.get(
      ApiEndpoints.driverTripsToday,
      queryParameters: {
        'date': localTodayDate,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحميل رحلات اليوم.');
    final responseModel = DriverTripsTodayResponseModel.fromJson(map);
    return responseModel.trips;
  }

  Future<DriverTripDetailsModel> fetchTripDetails(int tripId) async {
    final response = await _apiClient.get(
      ApiEndpoints.driverTripDetails(tripId),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحميل تفاصيل الرحلة.');
    final data = map['data'];
    if (data is Map) {
      return DriverTripDetailsModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('تعذر تحميل تفاصيل الرحلة.');
  }

  Future<TripStartResultModel> startTrip(
    int tripId, {
    double? latitude,
    double? longitude,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripStart(tripId),
      data: {
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر بدء الرحلة.');
    final data = map['data'];
    if (data is Map) {
      return TripStartResultModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('تعذر بدء الرحلة.');
  }

  Future<DriverTripLiveModel> fetchTripLive(int tripId) async {
    final response = await _apiClient.get(
      ApiEndpoints.driverTripLive(tripId),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحميل بيانات الرحلة الحية.');
    final data = map['data'];
    if (data is Map) {
      return DriverTripLiveModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('تعذر تحميل بيانات الرحلة الحية.');
  }

  /// يرسل الموقع ويرجّع تنبيهات الاقتراب (proximity.alerts) إن وُجدت
  Future<List<ProximityAlertModel>> updateLocation(
    int tripId, {
    required double latitude,
    required double longitude,
    double? speed,
    double? accuracy,
    double? heading,
    String? recordedAt,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripLocation(tripId),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'speed': ?speed,
        'accuracy': ?accuracy,
        'heading': ?heading,
        'recorded_at': ?recordedAt,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحديث الموقع.');
    // الكتابة في Firestore تتم من LiveTripCubit بالتوازي مع هذا الطلب (بحالة الرحلة
    // الحقيقية)، فما نكرروهاش هنا — التكرار كان يقلّب status بين active وin_progress

    try {
      return ProximityAlertModel.listFromLocationResponse(map);
    } catch (_) {
      // شكل غير متوقع للتنبيهات لا يجب أن يُفشل إرسال الموقع نفسه
      return const [];
    }
  }

  Future<void> updateGeneralDriverLocation({
    required int tripId,
    required double driverLat,
    required double driverLng,
    double? heading,
    bool? isOnline,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverGeneralUpdateLocation,
      data: {
        'trip_id': tripId,
        'driver_lat': driverLat,
        'driver_lng': driverLng,
        'heading': ?heading,
        'is_online': ?isOnline,
      },
      headers: _authHeader,
    );
    _unwrap(response.data, 'تعذر تحديث موقع السائق العام.');
  }

  /// 🌟 يكتب موقع السائق الحي مباشرة في Firebase Firestore: trips_tracking/{tripId}
  /// حتى تستقبل شاشة تتبع ولي الأمر (trackTripLiveStream) التحديث لحظياً دون انتظار Backend.
  Future<void> pushLiveTrackingToFirestore(
    int tripId, {
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? status,
    int? driverId,
    String? driverName,
  }) async {
    try {
      await _firestore.collection('trips_tracking').doc(tripId.toString()).set(
        {
          'trip_id': tripId,
          'driver_lat': latitude,
          'driver_lng': longitude,
          'heading': ?heading,
          'speed': ?speed,
          'status': ?status,
          'driver_id': ?driverId,
          'driver_name': ?driverName,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // لا نكسر واجهة السائق أثناء القيادة، لكن نطبع السبب (غالباً قواعد Firestore)
      debugPrint('❌ [Firestore] فشل كتابة موقع السائق في trips_tracking/$tripId: $e');
    }
  }

  /// يحدّث فقط حالة الرحلة في Firestore (مثلاً عند التعطل أو الاستئناف أو الإنهاء)
  /// دون الحاجة لموقع جديد.
  Future<void> updateFirestoreTripStatus(int tripId, String status) async {
    try {
      await _firestore.collection('trips_tracking').doc(tripId.toString()).set(
        {
          'trip_id': tripId,
          'status': status,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('❌ [Firestore] فشل تحديث حالة الرحلة في trips_tracking/$tripId: $e');
    }
  }

  Future<DriverTripStopsResponseModel> fetchStops(int tripId) async {
    final response = await _apiClient.get(
      ApiEndpoints.driverTripStops(tripId),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحميل محطات الرحلة.');
    final data = map['data'];
    if (data is Map) {
      return DriverTripStopsResponseModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('تعذر تحميل محطات الرحلة.');
  }

  Future<ChildStatusActionResultModel> pickupChild(
    int tripId,
    int tripChildId, {
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripPickup(tripId),
      data: {
        'trip_child_id': tripChildId,
        'latitude': latitude,
        'longitude': longitude,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تأكيد صعود الطفل.');
    return ChildStatusActionResultModel.fromJson(map);
  }

  Future<ChildStatusActionResultModel> dropoffChild(
    int tripId,
    int tripChildId, {
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripDropoff(tripId),
      data: {
        'trip_child_id': tripChildId,
        'latitude': latitude,
        'longitude': longitude,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تأكيد نزول الطفل.');
    return ChildStatusActionResultModel.fromJson(map);
  }

  Future<ChildStatusActionResultModel> updateChildStatus(
    int tripId,
    int tripChildId, {
    required String action,
    required double latitude,
    required double longitude,
  }) async {
    if (action == 'pickup' || action == 'onboard') {
      return pickupChild(tripId, tripChildId, latitude: latitude, longitude: longitude);
    } else if (action == 'dropoff' || action == 'dropped') {
      return dropoffChild(tripId, tripChildId, latitude: latitude, longitude: longitude);
    }
    final response = await _apiClient.post(
      ApiEndpoints.driverTripChildStatus(tripId, tripChildId),
      data: {
        'action': action,
        'latitude': latitude,
        'longitude': longitude,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحديث حالة الطفل.');
    return ChildStatusActionResultModel.fromJson(map);
  }

  Future<ChildStatusActionResultModel> skipChild(int tripId, int tripChildId) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripSkipChild(tripId, tripChildId),
      data: const {'action': 'skip'},
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تجاوز المحطة.');
    return ChildStatusActionResultModel.fromJson(map);
  }

  Future<ChildStatusActionResultModel> verifyQr(
    int tripId,
    int tripChildId, {
    required String qrCodeToken,
    String? stage,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripVerifyQr(tripId, tripChildId),
      data: {
        'qr_code_token': qrCodeToken,
        'stage': ?stage,
      },
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر التحقق من رمز QR.');
    return ChildStatusActionResultModel.fromJson(map);
  }

  Future<TripCompleteSummaryModel> completeTrip(int tripId) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripComplete(tripId),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر إنهاء الرحلة.');
    final summary = map['summary'];
    if (summary is Map) {
      return TripCompleteSummaryModel.fromJson(Map<String, dynamic>.from(summary));
    }
    throw const ApiException('تعذر إنهاء الرحلة.');
  }

  Future<DriverTripHistoryResponseModel> fetchHistory({String? date}) async {
    final query = <String, dynamic>{};
    if (date != null && date.isNotEmpty) query['date'] = date;

    final response = await _apiClient.get(
      ApiEndpoints.driverTripsHistory,
      queryParameters: query.isNotEmpty ? query : null,
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحميل سجل الرحلات.');
    return DriverTripHistoryResponseModel.fromJson(map);
  }

  Future<DriverTripHistoryDetailsModel> fetchHistoryDetails(int tripId) async {
    final response = await _apiClient.get(
      ApiEndpoints.driverTripHistoryDetails(tripId),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تحميل تفاصيل الرحلة.');
    final data = map['data'];
    if (data is Map) {
      return DriverTripHistoryDetailsModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('تعذر تحميل تفاصيل الرحلة.');
  }

  Future<List<UpcomingAbsenceTripModel>> fetchUpcomingTripsForAbsence() async {
    final response = await _apiClient.get(
      ApiEndpoints.driverTripsUpcomingForAbsence,
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر جلب الرحلات القادمة للغياب.');
    final rawList = map['data'];
    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((e) => UpcomingAbsenceTripModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<DriverRegisterAbsenceResponseModel> registerAbsenceWithTrips(
    DriverRegisterAbsenceRequestModel request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripsRegisterAbsence,
      data: request.toJson(),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تسجيل الغياب.');
    return DriverRegisterAbsenceResponseModel.fromJson(map);
  }

  Future<void> registerAbsence(List<String> dates) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripsRegisterAbsence,
      data: {'dates': dates},
      headers: _authHeader,
    );
    _unwrap(response.data, 'تعذر تسجيل الغياب.');
  }

  Future<VehicleBreakdownResponseModel> reportBreakdown(
    int tripId,
    VehicleBreakdownRequestModel request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripReportBreakdown(tripId),
      data: request.toJson(),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر تسجيل بلاغ طوارئ التعطل.');
    return VehicleBreakdownResponseModel.fromJson(map);
  }

  Future<TripStatusChangeResultModel> resumeTrip(int tripId) async {
    final response = await _apiClient.post(
      ApiEndpoints.driverTripResume(tripId),
      headers: _authHeader,
    );
    final map = _unwrap(response.data, 'تعذر استئناف الرحلة.');
    final data = map['data'];
    if (data is Map) {
      return TripStatusChangeResultModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException('تعذر استئناف الرحلة.');
  }
}
