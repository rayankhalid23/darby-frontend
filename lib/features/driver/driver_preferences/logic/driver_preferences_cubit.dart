import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_transport/core/network/api_exception.dart';
import '../data/repositories/driver_preferences_repository.dart';
import 'driver_preferences_state.dart';
import '../data/models/preference_defaults_model.dart';
import '../data/models/driver_preferences_model.dart';

class DriverPreferencesCubit extends Cubit<DriverPreferencesState> {
  final DriverPreferencesRepository _repository;

  PreferenceDefaultsModel? _defaults;
  PreferenceDefaultsModel? get defaults => _defaults;

  DriverPreferencesModel? _preferences;
  DriverPreferencesModel? get preferences => _preferences;

  DriverPreferencesCubit(this._repository) : super(DriverPreferencesInitial());

  Future<void> loadPreferenceDefaults() async {
    emit(PreferenceDefaultsLoading());
    try {
      _defaults = await _repository.getPreferenceDefaults();
      emit(PreferenceDefaultsLoaded(_defaults!));
      await loadDriverPreferences();
    } on ApiException catch (e) {
      emit(PreferenceDefaultsError(e.message));
    } catch (e) {
      emit(PreferenceDefaultsError(e.toString().replaceAll('Exception:', '')));
    }
  }

  Future<void> loadDriverPreferences() async {
    emit(DriverPreferencesLoading());
    try {
      final fetchedPreferences = await _repository.getPreferences();
      _preferences = fetchedPreferences;
      emit(
        DriverPreferencesLoaded(
          preferences: fetchedPreferences,
          defaults: _defaults,
        ),
      );
    } on ApiException catch (e) {
      emit(DriverPreferencesError(e.message));
    } catch (e) {
      emit(DriverPreferencesError(e.toString().replaceAll('Exception:', '')));
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> payload) async {
    emit(UpdatingPreferences());
    try {
      final success = await _repository.updatePreferences(payload);
      if (success) {
        emit(UpdatePreferencesSuccess());
        await loadPreferenceDefaults(); // Reload all data after success
      } else {
        emit(const UpdatePreferencesError('فشل حفظ الاعدادات .'));
      }
    } on ApiException catch (e) {
      emit(UpdatePreferencesError(e.message));
    } catch (e) {
      emit(UpdatePreferencesError(e.toString().replaceAll('Exception:', '')));
    }
  }
}
