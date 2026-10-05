import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/emergency_dispatch_model.dart';
import '../../data/repositories/driver_emergency_repository.dart';

abstract class DriverEmergencyState {}

class DriverEmergencyInitial extends DriverEmergencyState {}

class DriverEmergencyLoading extends DriverEmergencyState {}

class DriverEmergencyLoaded extends DriverEmergencyState {
  final List<EmergencyDispatchModel> dispatches;
  final int availableCount;

  DriverEmergencyLoaded({
    required this.dispatches,
    required this.availableCount,
  });
}

class DriverEmergencyDetailsLoaded extends DriverEmergencyState {
  final EmergencyDispatchModel dispatch;
  DriverEmergencyDetailsLoaded(this.dispatch);
}

class DriverEmergencyActionLoading extends DriverEmergencyState {
  final int dispatchId;
  DriverEmergencyActionLoading(this.dispatchId);
}

class DriverEmergencyActionSuccess extends DriverEmergencyState {
  final String message;
  final int? substituteTripId;

  DriverEmergencyActionSuccess(this.message, {this.substituteTripId});
}

class DriverEmergencyError extends DriverEmergencyState {
  final String message;
  DriverEmergencyError(this.message);
}

class DriverEmergencyCubit extends Cubit<DriverEmergencyState> {
  final DriverEmergencyRepository _repository;

  DriverEmergencyCubit(this._repository) : super(DriverEmergencyInitial());

  int _availableCount = 0;
  int get availableCount => _availableCount;

  /// جلب عدد المهام الطارئة المتاحة سريعا (من أجل Badge العداد في الواجهة الرئيسية)
  Future<int> fetchAvailableCount() async {
    try {
      final list = await _repository.getAvailableDispatches();
      _availableCount = list.length;
      return _availableCount;
    } catch (_) {
      return _availableCount;
    }
  }

  /// تحميل المهام الطارئة المتاحة للسائق البديل
  Future<void> loadAvailableDispatches() async {
    emit(DriverEmergencyLoading());
    try {
      final dispatches = await _repository.getAvailableDispatches();
      _availableCount = dispatches.length;
      emit(DriverEmergencyLoaded(
        dispatches: dispatches,
        availableCount: _availableCount,
      ));
    } catch (e) {
      emit(DriverEmergencyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// جلب تفاصيل مهمة طارئة واحدة
  Future<void> loadDispatchDetails(int dispatchId) async {
    emit(DriverEmergencyLoading());
    try {
      final dispatch = await _repository.getDispatchDetails(dispatchId);
      emit(DriverEmergencyDetailsLoaded(dispatch));
    } catch (e) {
      emit(DriverEmergencyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// قبول مهمة إنقاذ طارئة
  Future<void> acceptDispatch(int dispatchId) async {
    emit(DriverEmergencyActionLoading(dispatchId));
    try {
      final res = await _repository.acceptDispatch(dispatchId);
      final message = res['message']?.toString() ??
          'تم قبول مهمة الاستبدال بنجاح وتعيينك لنقل الطلاب.';

      // الباك يرجّع substitute_trip_id بأول مستوى بالرد، و data احتياط
      // لو تغيّر شكل الرد. ممكن تكون رحلة البديل نفسها (مدموجة) أو رحلة إنقاذ جديدة
      int? substituteTripId = int.tryParse(res['substitute_trip_id']?.toString() ?? '');
      if (substituteTripId == null && res['data'] is Map) {
        substituteTripId = int.tryParse(
          res['data']['substitute_trip_id']?.toString() ?? '',
        );
      }

      emit(DriverEmergencyActionSuccess(
        message,
        substituteTripId: substituteTripId,
      ));

      await loadAvailableDispatches();
    } catch (e) {
      emit(DriverEmergencyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// رفض مهمة طارئة
  Future<void> rejectDispatch(int dispatchId) async {
    emit(DriverEmergencyActionLoading(dispatchId));
    try {
      final res = await _repository.rejectDispatch(dispatchId);
      final message = res['message']?.toString() ??
          'تم استبعادك من قائمة المرشحين لهذه المهمة الطارئة.';

      emit(DriverEmergencyActionSuccess(message));
      await loadAvailableDispatches();
    } catch (e) {
      emit(DriverEmergencyError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
