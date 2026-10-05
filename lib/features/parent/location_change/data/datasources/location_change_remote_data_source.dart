import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/services/storage_service.dart';
import '../models/location_change_available_trips_model.dart';
import '../models/location_change_options_model.dart';
import '../models/location_change_preview_model.dart';
import '../models/location_change_request_model.dart';

class LocationChangeRemoteDataSource {
  final ApiClient _apiClient;

  LocationChangeRemoteDataSource(this._apiClient);

  Map<String, dynamic> get _authHeader {
    final auth = StorageService.getAuthorizationHeader();
    if (auth == null || auth.isEmpty) return {};
    return {'Authorization': auth};
  }

  /// 1. جلب خيارات أطفال ولي الأمر وعناوينه المحفوظة
  Future<LocationChangeOptionsModel> getOptions() async {
    final response = await _apiClient.get(
      ApiEndpoints.parentLocationChangeOptions,
      headers: _authHeader,
    );
    return LocationChangeOptionsModel.fromJson(response.data);
  }

  /// 2. استعلام الرحلات المتاحة للأطفال في تاريخ معين
  Future<List<ChildAvailableTripsModel>> getAvailableTrips({
    required List<int> childIds,
    required String date,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentLocationChangeAvailableTrips,
      data: {
        'child_ids': childIds,
        'date': date,
      },
      headers: _authHeader,
    );
    final data = response.data['data'] ?? response.data;
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map && data['children'] is List) {
      rawList = data['children'] as List;
    } else if (data is Map) {
      rawList = data.values.toList();
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => ChildAvailableTripsModel.fromJson(e))
        .toList();
  }

  /// 3. معاينة السعر وفرق المسافة قبل الإرسال (Preview Quote)
  Future<LocationChangePreviewModel> previewRequest(Map<String, dynamic> body) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentLocationChangePreview,
      data: body,
      headers: _authHeader,
    );
    return LocationChangePreviewModel.fromJson(response.data);
  }

  /// 4. إرسال طلب التغيير رسمياً (Store Location Change)
  Future<List<LocationChangeRequestModel>> createRequest(Map<String, dynamic> body) async {
    final response = await _apiClient.post(
      ApiEndpoints.parentLocationChangeRequests,
      data: body,
      headers: _authHeader,
    );
    final data = response.data['data'];
    final createdList = data is Map && data['created_requests'] is List
        ? data['created_requests'] as List
        : (data is List ? data : [data]);

    return createdList
        .whereType<Map<String, dynamic>>()
        .map((e) => LocationChangeRequestModel.fromJson(e))
        .toList();
  }

  /// 5. عرض قائمة طلبات تغيير الموقع لولي الأمر
  Future<List<LocationChangeRequestModel>> getRequests({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.parentLocationChangeRequests,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      headers: _authHeader,
    );
    final data = response.data['data'];
    final List<dynamic> list = data is List ? data : (response.data is List ? response.data as List : []);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => LocationChangeRequestModel.fromJson(e))
        .toList();
  }

  /// 6. إلغاء طلب التغيير قبل رد السائق
  Future<Map<String, dynamic>> cancelRequest(int id) async {
    final response = await _apiClient.delete(
      ApiEndpoints.parentLocationChangeCancel(id),
      headers: _authHeader,
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : {'success': true};
  }
}
