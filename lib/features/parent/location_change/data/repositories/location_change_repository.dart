import 'package:dio/dio.dart';
import '../datasources/location_change_remote_data_source.dart';
import '../models/location_change_available_trips_model.dart';
import '../models/location_change_options_model.dart';
import '../models/location_change_preview_model.dart';
import '../models/location_change_request_model.dart';

class LocationChangeRepository {
  final LocationChangeRemoteDataSource _remoteDataSource;

  LocationChangeRepository(this._remoteDataSource);

  Future<LocationChangeOptionsModel> getOptions() async {
    return await _remoteDataSource.getOptions();
  }

  Future<List<ChildAvailableTripsModel>> getAvailableTrips({
    required List<int> childIds,
    required String date,
  }) async {
    return await _remoteDataSource.getAvailableTrips(
      childIds: childIds,
      date: date,
    );
  }

  Future<(LocationChangePreviewModel?, String?)> previewRequest({
    required String pointType,
    required String date,
    required List<Map<String, dynamic>> selections,
    int? addressId,
    double? lat,
    double? lng,
    String? label,
  }) async {
    final body = <String, dynamic>{
      'point_type': pointType,
      'date': date,
      'selections': selections,
      'address_id': ?addressId,
      if (addressId == null && lat != null && lng != null) ...{
        'lat': lat,
        'lng': lng,
      },
      if (label != null && label.isNotEmpty) 'label': label,
    };

    try {
      final preview = await _remoteDataSource.previewRequest(body);
      return (preview, null);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : 'حدث خطأ في حساب المعاينة';
      return (null, msg);
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<(List<LocationChangeRequestModel>?, String?)> createRequest({
    required String pointType,
    required String date,
    required List<Map<String, dynamic>> selections,
    int? addressId,
    double? lat,
    double? lng,
    String? label,
  }) async {
    final body = <String, dynamic>{
      'point_type': pointType,
      'date': date,
      'selections': selections,
      'address_id': ?addressId,
      if (addressId == null && lat != null && lng != null) ...{
        'lat': lat,
        'lng': lng,
      },
      if (label != null && label.isNotEmpty) 'label': label,
    };

    try {
      final requests = await _remoteDataSource.createRequest(body);
      return (requests, null);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : 'حدث خطأ في إرسال طلب التغيير';
      return (null, msg);
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<List<LocationChangeRequestModel>> getRequests({String? status}) async {
    return await _remoteDataSource.getRequests(status: status);
  }

  Future<(bool, String?)> cancelRequest(int id) async {
    try {
      final res = await _remoteDataSource.cancelRequest(id);
      final msg = res['message']?.toString() ?? 'تم إلغاء الطلب بنجاح.';
      return (true, msg);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : 'لا يمكن إلغاء الطلب حالياً.';
      return (false, msg);
    } catch (e) {
      return (false, e.toString());
    }
  }
}
