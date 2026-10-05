import 'package:dio/dio.dart';
import '../data_sources/vehicle_remote_data_source.dart';
import '../models/vehicle_model.dart';

class VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepository(this.remoteDataSource);

  // 📥 جلب تفاصيل المركبة والوثائق معاً ودمجهم في الـ Model
  Future<VehicleModel> getVehicleDetails() async {
    try {
      final vehicleResponse = await remoteDataSource.getVehicleData();
      final vehicleData = (vehicleResponse.data is Map && vehicleResponse.data['data'] != null)
          ? vehicleResponse.data['data']
          : {};

      Map<String, dynamic> mergedData = Map<String, dynamic>.from(vehicleData as Map);

      try {
        final legalResponse = await remoteDataSource.getLegalData();
        final legalData = (legalResponse.data is Map && legalResponse.data['data'] != null)
            ? legalResponse.data['data']
            : {};
        if (legalData is Map) {
          mergedData['national_id'] = legalData['national_id'];
          mergedData['license_number'] = legalData['license_number'];
          mergedData['license_expiry'] = legalData['license_expiry'];
        }
      } catch (_) {}

      return VehicleModel.fromJson(mergedData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // 📤 تحديث تفاصيل المركبة
  Future<({String message, VehicleModel vehicle})> updateVehicle({
    required int vehicleId,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    String? color,
    String? type,
    int? capacityManual,
    bool? hasAc,
    dynamic vehicleImage,
  }) async {
    try {
      final response = await remoteDataSource.updateVehicleDetails(
        vehicleId: vehicleId,
        brand: brand,
        model: model,
        year: year,
        plateNumber: plateNumber,
        color: color,
        type: type,
        capacityManual: capacityManual,
        hasAc: hasAc,
        vehicleImage: vehicleImage,
      );
      final resMap = (response.data is Map) ? response.data as Map : {};
      final message = resMap['message']?.toString() ?? 'تم تحديث بيانات المركبة بنجاح';
      final data = resMap['data'] ?? {};
      final vehicle = VehicleModel.fromJson(Map<String, dynamic>.from(data as Map));
      return (message: message, vehicle: vehicle);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // 📤 تحديث المستندات والوثائق
  Future<String> updateLegalData({
    String? nationalId,
    String? licenseNumber,
    String? licenseExpiry,
    String? insuranceExpiry,
    dynamic docLicense,
    dynamic docLogbook,
    dynamic docInsurance,
  }) async {
    try {
      final response = await remoteDataSource.updateLegalData(
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        insuranceExpiry: insuranceExpiry,
        docLicense: docLicense,
        docLogbook: docLogbook,
        docInsurance: docInsurance,
      );
      return response.data['message'] ?? 'تم تحديث الوثائق بنجاح';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> updateLegalDocuments({
    String? nationalId,
    String? licenseNumber,
    String? licenseExpiry,
    String? insuranceExpiry,
    dynamic docLicense,
    dynamic docLogbook,
    dynamic docInsurance,
  }) =>
      updateLegalData(
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        insuranceExpiry: insuranceExpiry,
        docLicense: docLicense,
        docLogbook: docLogbook,
        docInsurance: docInsurance,
      );

  String _handleDioError(DioException e) {
    if (e.response?.data is Map) {
      final resMap = e.response!.data as Map;
      String message = '';
      if (resMap['message'] != null) {
        message = resMap['message'].toString();
      }
      if (resMap['errors'] is Map) {
        final errorsMap = resMap['errors'] as Map;
        final errorList = <String>[];
        errorsMap.forEach((key, val) {
          if (val is List) {
            errorList.addAll(val.map((e) => e.toString()));
          } else if (val != null) {
            errorList.add(val.toString());
          }
        });
        if (errorList.isNotEmpty) {
          final joined = errorList.join('\n• ');
          return message.isNotEmpty ? '$message\n• $joined' : '• $joined';
        }
      }
      if (message.isNotEmpty) return message;
    }
    if (e.response?.statusCode == 422) {
      return 'البيانات المرسلة غير مطابقة لشروط النظام.';
    }
    return 'حدث خطأ في الاتصال بالسيرفر، تأكد من اتصال الإنترنت.';
  }
}
