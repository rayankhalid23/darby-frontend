import 'package:dio/dio.dart';
import 'package:kids_transport/core/network/api_client.dart';
import 'package:kids_transport/core/network/api_endpoints.dart';
import 'package:kids_transport/core/network/api_exception.dart';
import 'package:kids_transport/core/utils/app_image_helper.dart';
import '../models/parent_register_request.dart';

class ParentRemoteDataSource {
  final ApiClient _apiClient;

  ParentRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// POST /api/parent/send-otp
  /// يُستخدم لإرسال الـ OTP وأيضاً لإعادة إرسال الـ OTP (نفس الـ endpoint)
  Future<Map<String, dynamic>> sendOtp(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentSendOtp,
      data: {'email': email},
    );
    return _mapResponse(response.data);
  }

  /// POST /api/parent/register
  /// التسجيل النهائي - يحتوي على OTP + avatar (multipart إن وجد)
  Future<Map<String, dynamic>> register(ParentRegisterRequest request) async {
    final dynamic data;
    final hasAvatar = request.avatar != null;

    if (hasAvatar) {
      final multipart = await AppImageHelper.createMultipartFile(
        request.avatar,
        defaultFilename: 'avatar.jpg',
      );
      data = FormData.fromMap({
        ...request.toJson(),
        'avatar': ?multipart,
      });
    } else {
      data = request.toJson();
    }

    final response = await _apiClient.post(
      ApiEndpoints.parentRegister,
      data: data,
    );
    return _mapResponse(response.data);
  }

  /// POST /api/parent/addresses  (requires Bearer token)
  Future<Map<String, dynamic>> addAddress({
    required String token,
    required String label,
    required double lat,
    required double lng,
    required bool isDefault,
    int? zoneId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentAddresses,
      data: {
        'label': label,
        'lat': lat,
        'lng': lng,
        'zone_id': ?zoneId,
        'is_default': isDefault,
      },
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return _mapResponse(response.data);
  }

  Map<String, dynamic> _mapResponse(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('استجابة الخادم غير مفهومة.');
  }
}
