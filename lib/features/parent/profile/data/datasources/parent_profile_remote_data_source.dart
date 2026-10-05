import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_transport/core/models/email_verification_info.dart';
import 'package:kids_transport/core/network/api_client.dart';
import 'package:kids_transport/core/network/api_endpoints.dart';
import 'package:kids_transport/core/network/api_exception.dart';
import 'package:kids_transport/core/services/storage_service.dart';
import 'package:kids_transport/core/utils/app_image_helper.dart';
import '../models/parent_model.dart';

class ParentProfileRemoteDataSource {
  final ApiClient _client;

  ParentProfileRemoteDataSource(this._client);

  Map<String, dynamic> get _authHeader {
    final token = StorageService.getAuthorizationHeader();
    if (token == null || token.isEmpty) return {};
    return {'Authorization': token};
  }

  void _checkSuccess(dynamic data, String fallbackMessage) {
    if (data is Map) {
      final success = data['success'] ?? data['status'];
      if (success == false) {
        final serverMessage = ApiException.extractMessage(data);
        throw ApiException(serverMessage ?? fallbackMessage);
      }
    }
  }

  /// GET /api/parent/profile
  Future<ParentModel> getParentProfile() async {
    final response = await _client.get(
      ApiEndpoints.parentProfile,
      headers: _authHeader,
    );
    final data = response.data;
    debugPrint('📥 [ProfileAPI] GET /profile => $data');
    _checkSuccess(data, 'تعذر تحميل ملف ولي الأمر.');

    final payload = data is Map ? (data['data'] ?? data) : data;
    if (payload is! Map<String, dynamic>) {
      throw ApiException('استجابة غير متوقعة من السيرفر عند جلب الملف الشخصي.');
    }
    // بعض APIs تحط البيانات داخل مفتاح 'user' (نفس صيغة login/register)
    final userData = (payload['user'] is Map)
        ? Map<String, dynamic>.from(payload['user'] as Map)
        : payload;
    return ParentModel.fromJson(userData);
  }

  /// POST /api/parent/profile/update
  Future<ProfileUpdateResult<ParentModel>> updateParentProfile({
    required String fullName,
    required String phoneNumber,
    String? email,
    String? alternativePhone,
    dynamic avatarFile,
  }) async {
    debugPrint(
      '📤 [ProfileAPI] تحديث الملف: name=$fullName phone=$phoneNumber '
      'email=$email avatar=$avatarFile',
    );

    // الحقول الاختيارية نرسلها فقط إذا رغب المستخدم في تعديلها
    final fields = <String, dynamic>{
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email': ?email,
      'alternative_phone':
          alternativePhone, // ترسل null لحذفه كما طلبت الباك إند
    };

    final dynamic requestBody;
    if (avatarFile != null) {
      final multipart = await AppImageHelper.createMultipartFile(
        avatarFile,
        defaultFilename: 'avatar.jpg',
      );
      requestBody = FormData.fromMap({
        ...fields,
        'avatar': ?multipart,
      });
    } else {
      requestBody = fields;
    }

    final response = await _client.post(
      ApiEndpoints.parentProfileUpdate,
      headers: _authHeader,
      data: requestBody,
    );

    final data = response.data;
    debugPrint('📥 [ProfileAPI] POST /profile/update => $data');
    _checkSuccess(data, 'تعذر تحديث الملف الشخصي.');

    EmailVerificationInfo? emailVerification;
    if (data is Map &&
        data['data'] is Map &&
        data['data']['email_verification'] is Map) {
      emailVerification = EmailVerificationInfo.fromJson(
        Map<String, dynamic>.from(data['data']['email_verification'] as Map),
      );
    }

    final payload = data is Map ? data['data'] : null;
    ParentModel parent;
    if (payload is Map<String, dynamic>) {
      parent = ParentModel.fromJson(payload);
    } else {
      debugPrint(
        '⚠️ [ProfileAPI] رد التحديث ما فيه كائن profile كامل، '
        'رح أجيب البيانات الطازجة من GET /profile بدل ما أفشل.',
      );
      parent = await getParentProfile();
    }

    final serverMessage = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : 'تم تحديث الملف الشخصي بنجاح';

    return ProfileUpdateResult<ParentModel>(
      profile: parent,
      emailVerification: emailVerification,
      message: serverMessage,
    );
  }

  /// POST /api/parent/profile/email-change/cancel
  Future<void> cancelEmailChange() async {
    final response = await _client.post(
      ApiEndpoints.parentCancelEmailChange,
      headers: _authHeader,
    );
    final data = response.data;
    debugPrint('📥 [ProfileAPI] POST /email-change/cancel => $data');
    _checkSuccess(data, 'تعذر إلغاء تغيير البريد الإلكتروني.');
  }

  /// GET /api/parent/profile/email-change/status
  Future<String> getEmailChangeStatus() async {
    final response = await _client.get(
      ApiEndpoints.parentEmailChangeStatus,
      headers: _authHeader,
    );
    final data = response.data;
    debugPrint('📥 [ProfileAPI] GET /email-change/status => $data');
    _checkSuccess(data, 'تعذر فحص حالة تغيير البريد الإلكتروني.');
    if (data is Map && data['data'] is Map) {
      return (data['data']['status'] ?? '').toString();
    }
    return '';
  }
}
