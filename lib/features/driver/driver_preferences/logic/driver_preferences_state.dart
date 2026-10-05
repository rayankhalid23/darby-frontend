import '../data/models/driver_preferences_model.dart';
import '../data/models/preference_defaults_model.dart';

abstract class DriverPreferencesState {
  const DriverPreferencesState();
}

class DriverPreferencesInitial extends DriverPreferencesState {}

class PreferenceDefaultsLoading extends DriverPreferencesState {}

class PreferenceDefaultsLoaded extends DriverPreferencesState {
  final PreferenceDefaultsModel defaults;

  const PreferenceDefaultsLoaded(this.defaults);
}

class PreferenceDefaultsError extends DriverPreferencesState {
  final String message;

  const PreferenceDefaultsError(this.message);
}

class DriverPreferencesLoading extends DriverPreferencesState {}

class DriverPreferencesLoaded extends DriverPreferencesState {
  final DriverPreferencesModel? preferences;
  final PreferenceDefaultsModel? defaults;

  const DriverPreferencesLoaded({
    this.preferences,
    this.defaults,
  });
}

class DriverPreferencesError extends DriverPreferencesState {
  final String message;

  const DriverPreferencesError(this.message);
}

class UpdatingPreferences extends DriverPreferencesState {}

class UpdatePreferencesSuccess extends DriverPreferencesState {}

class UpdatePreferencesError extends DriverPreferencesState {
  final String message;

  const UpdatePreferencesError(this.message);
}
