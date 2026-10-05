import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/location_change_available_trips_model.dart';
import '../../data/models/location_change_options_model.dart';
import '../../data/models/location_change_preview_model.dart';
import '../../data/models/location_change_request_model.dart';
import '../../data/repositories/location_change_repository.dart';

abstract class LocationChangeState {}

class LocationChangeInitial extends LocationChangeState {}

class LocationChangeLoading extends LocationChangeState {}

class LocationChangeOptionsLoaded extends LocationChangeState {
  final LocationChangeOptionsModel options;
  final Set<int> selectedChildIds;
  final List<ChildAvailableTripsModel> availableTrips;
  final Map<int, int?> selectedTripForChild; // child_id -> trip_id
  final SavedAddressModel? selectedAddress;
  final double? customLat;
  final double? customLng;
  final String? customLabel;
  final String pointType; // 'pickup' or 'dropoff'
  final DateTime changeDate;
  final LocationChangePreviewModel? previewData;
  final bool isAvailableTripsLoading;
  final bool isPreviewLoading;
  final bool isSubmitting;
  final bool submitSuccess;
  final String? submitMessage;
  final String? error;

  LocationChangeOptionsLoaded({
    required this.options,
    required this.selectedChildIds,
    this.availableTrips = const [],
    this.selectedTripForChild = const {},
    this.selectedAddress,
    this.customLat,
    this.customLng,
    this.customLabel,
    required this.pointType,
    required this.changeDate,
    this.previewData,
    this.isAvailableTripsLoading = false,
    this.isPreviewLoading = false,
    this.isSubmitting = false,
    this.submitSuccess = false,
    this.submitMessage,
    this.error,
  });

  LocationChangeOptionsLoaded copyWith({
    LocationChangeOptionsModel? options,
    Set<int>? selectedChildIds,
    List<ChildAvailableTripsModel>? availableTrips,
    Map<int, int?>? selectedTripForChild,
    SavedAddressModel? selectedAddress,
    bool clearSelectedAddress = false,
    double? customLat,
    double? customLng,
    String? customLabel,
    String? pointType,
    DateTime? changeDate,
    LocationChangePreviewModel? previewData,
    bool clearPreview = false,
    bool? isAvailableTripsLoading,
    bool? isPreviewLoading,
    bool? isSubmitting,
    bool? submitSuccess,
    String? submitMessage,
    String? error,
    bool clearError = false,
  }) {
    return LocationChangeOptionsLoaded(
      options: options ?? this.options,
      selectedChildIds: selectedChildIds ?? this.selectedChildIds,
      availableTrips: availableTrips ?? this.availableTrips,
      selectedTripForChild: selectedTripForChild ?? this.selectedTripForChild,
      selectedAddress: clearSelectedAddress ? null : (selectedAddress ?? this.selectedAddress),
      customLat: customLat ?? this.customLat,
      customLng: customLng ?? this.customLng,
      customLabel: customLabel ?? this.customLabel,
      pointType: pointType ?? this.pointType,
      changeDate: changeDate ?? this.changeDate,
      previewData: clearPreview ? null : (previewData ?? this.previewData),
      isAvailableTripsLoading: isAvailableTripsLoading ?? this.isAvailableTripsLoading,
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      submitMessage: submitMessage ?? this.submitMessage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LocationChangeHistoryLoaded extends LocationChangeState {
  final List<LocationChangeRequestModel> requests;
  final String currentStatusFilter;
  final bool isCancelling;
  final String? actionMessage;

  LocationChangeHistoryLoaded(
    this.requests, {
    this.currentStatusFilter = 'all',
    this.isCancelling = false,
    this.actionMessage,
  });
}

class LocationChangeError extends LocationChangeState {
  final String message;
  LocationChangeError(this.message);
}

class LocationChangeCubit extends Cubit<LocationChangeState> {
  final LocationChangeRepository _repository;

  LocationChangeCubit(this._repository) : super(LocationChangeInitial());

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchOptions() async {
    emit(LocationChangeLoading());
    try {
      final options = await _repository.getOptions();
      final defaultAddress = options.addresses.isNotEmpty ? options.addresses.first : null;
      final initialChildIds = options.children.map((c) => c.id).toSet();

      final initialLoaded = LocationChangeOptionsLoaded(
        options: options,
        selectedChildIds: initialChildIds,
        selectedAddress: defaultAddress,
        pointType: 'pickup',
        changeDate: DateTime.now(),
      );

      emit(initialLoaded);

      if (initialChildIds.isNotEmpty) {
        await _fetchAvailableTripsInternal(initialLoaded);
      }
    } catch (e) {
      emit(LocationChangeError(e.toString()));
    }
  }

  Future<void> _fetchAvailableTripsInternal(LocationChangeOptionsLoaded currentState) async {
    if (currentState.selectedChildIds.isEmpty) {
      emit(currentState.copyWith(availableTrips: [], clearPreview: true));
      return;
    }

    emit(currentState.copyWith(isAvailableTripsLoading: true, clearError: true));

    try {
      final dateStr = _formatDate(currentState.changeDate);
      final trips = await _repository.getAvailableTrips(
        childIds: currentState.selectedChildIds.toList(),
        date: dateStr,
      );

      emit(currentState.copyWith(
        isAvailableTripsLoading: false,
        availableTrips: trips,
        clearPreview: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isAvailableTripsLoading: false,
        availableTrips: [],
        clearError: true,
      ));
    }
  }

  void clearError() {
    final currentState = state;
    if (currentState is LocationChangeOptionsLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }

  void toggleChildSelection(int childId) {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    final updated = Set<int>.from(currentState.selectedChildIds);
    if (updated.contains(childId)) {
      updated.remove(childId);
    } else {
      updated.add(childId);
    }

    final updatedState = currentState.copyWith(selectedChildIds: updated, clearPreview: true);
    emit(updatedState);
    _fetchAvailableTripsInternal(updatedState);
  }

  void selectAllChildren(bool selectAll) {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    final updated = selectAll
        ? currentState.options.children.map((c) => c.id).toSet()
        : <int>{};

    final updatedState = currentState.copyWith(selectedChildIds: updated, clearPreview: true);
    emit(updatedState);
    _fetchAvailableTripsInternal(updatedState);
  }

  void setChangeDate(DateTime date) {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    final updatedState = currentState.copyWith(changeDate: date, clearPreview: true);
    emit(updatedState);
    _fetchAvailableTripsInternal(updatedState);
  }

  void setPointType(String type) {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    emit(currentState.copyWith(pointType: type, clearPreview: true));
  }

  void selectAddress(SavedAddressModel address) {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    emit(currentState.copyWith(
      selectedAddress: address,
      customLat: null,
      customLng: null,
      customLabel: null,
      clearPreview: true,
    ));
  }

  void setCustomLocation(double lat, double lng, String label) {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    emit(currentState.copyWith(
      clearSelectedAddress: true,
      customLat: lat,
      customLng: lng,
      customLabel: label,
      clearPreview: true,
    ));
  }

  List<Map<String, dynamic>> _buildSelectionsPayload(LocationChangeOptionsLoaded currentState) {
    final selections = <Map<String, dynamic>>[];

    for (final childId in currentState.selectedChildIds) {
      final childTrips = currentState.availableTrips.firstWhere(
        (t) => t.childId == childId,
        orElse: () => ChildAvailableTripsModel(childId: childId, childName: '', availableTrips: []),
      );

      final matchingTrips = childTrips.availableTrips.where((trip) {
        if (currentState.pointType == 'pickup') return trip.direction == 'to_school';
        if (currentState.pointType == 'dropoff') return trip.direction == 'to_home';
        return false;
      }).toList();

      final tripIds = <int>[];
      if (matchingTrips.isNotEmpty) {
        final activeSubId = matchingTrips.first.activeSubscriptionId;
        if (activeSubId > 0) {
          tripIds.add(activeSubId);
        } else if (matchingTrips.first.tripId > 0) {
          tripIds.add(matchingTrips.first.tripId);
        }
      }

      selections.add({
        'child_id': childId,
        'trip_ids': tripIds,
      });
    }

    return selections;
  }

  Future<void> calculatePreview() async {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    if (currentState.selectedChildIds.isEmpty) {
      emit(currentState.copyWith(error: 'يرجى اختيار طفل واحد على الأقل'));
      return;
    }

    if (currentState.selectedAddress == null &&
        (currentState.customLat == null || currentState.customLng == null)) {
      emit(currentState.copyWith(error: 'يرجى اختيار عنوان الموقع الجديد المطلوب'));
      return;
    }

    if (currentState.isAvailableTripsLoading) {
      emit(currentState.copyWith(error: 'جاري تحميل رحلات الأطفال، يرجى الانتظار'));
      return;
    }

    final selections = _buildSelectionsPayload(currentState);
    if (selections.isEmpty) {
      emit(currentState.copyWith(error: 'لا توجد رحلات للأطفال المختارين في هذا التاريخ'));
      return;
    }

    final isValid = selections.every((item) => item['trip_ids'] != null && (item['trip_ids'] as List).isNotEmpty);
    if (!isValid) {
      emit(currentState.copyWith(error: 'لا توجد رحلات مطابقة للوجهة المحددة للأطفال المختارين في هذا التاريخ'));
      return;
    }

    emit(currentState.copyWith(isPreviewLoading: true, clearError: true));

    final dateStr = _formatDate(currentState.changeDate);

    final (preview, error) = await _repository.previewRequest(
      pointType: currentState.pointType,
      date: dateStr,
      selections: selections,
      addressId: currentState.selectedAddress?.id,
      lat: currentState.customLat,
      lng: currentState.customLng,
      label: currentState.customLabel ?? currentState.selectedAddress?.label,
    );

    if (preview != null) {
      emit(currentState.copyWith(
        isPreviewLoading: false,
        previewData: preview,
      ));
    } else {
      emit(currentState.copyWith(
        isPreviewLoading: false,
        error: error ?? 'تعذر معاينة التكلفة',
      ));
    }
  }

  Future<void> submitRequests() async {
    final currentState = state;
    if (currentState is! LocationChangeOptionsLoaded) return;

    if (currentState.selectedChildIds.isEmpty) {
      emit(currentState.copyWith(error: 'يرجى اختيار طفل واحد على الأقل'));
      return;
    }

    if (currentState.isAvailableTripsLoading) {
      emit(currentState.copyWith(error: 'جاري تحميل رحلات الأطفال، يرجى الانتظار'));
      return;
    }

    final selections = _buildSelectionsPayload(currentState);
    if (selections.isEmpty) {
      emit(currentState.copyWith(error: 'لا توجد رحلات للأطفال المختارين في هذا التاريخ'));
      return;
    }

    final isValid = selections.every((item) => item['trip_ids'] != null && (item['trip_ids'] as List).isNotEmpty);
    if (!isValid) {
      emit(currentState.copyWith(error: 'لا توجد رحلات مطابقة للوجهة المحددة للأطفال المختارين في هذا التاريخ'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    final dateStr = _formatDate(currentState.changeDate);

    final (createdRequests, error) = await _repository.createRequest(
      pointType: currentState.pointType,
      date: dateStr,
      selections: selections,
      addressId: currentState.selectedAddress?.id,
      lat: currentState.customLat,
      lng: currentState.customLng,
      label: currentState.customLabel ?? currentState.selectedAddress?.label,
    );

    if (createdRequests != null && createdRequests.isNotEmpty) {
      final count = createdRequests.length;
      final msg = count == 1
          ? 'تم إرسال طلب تغيير الموقع للسائق المعني بنجاح 🚀'
          : 'تم إرسال $count طلبات تغيير موقع للسائقين المعنيين بنجاح 🚀';

      emit(currentState.copyWith(
        isSubmitting: false,
        submitSuccess: true,
        submitMessage: msg,
      ));
    } else {
      emit(currentState.copyWith(
        isSubmitting: false,
        error: error ?? 'تعذر إرسال الطلب',
      ));
    }
  }

  Future<void> fetchHistory({String status = 'all'}) async {
    emit(LocationChangeLoading());
    try {
      final requests = await _repository.getRequests(status: status);
      emit(LocationChangeHistoryLoaded(requests, currentStatusFilter: status));
    } catch (e) {
      emit(LocationChangeError(e.toString()));
    }
  }

  Future<void> cancelRequest(int requestId) async {
    final currentState = state;
    if (currentState is! LocationChangeHistoryLoaded) return;

    emit(LocationChangeHistoryLoaded(
      currentState.requests,
      currentStatusFilter: currentState.currentStatusFilter,
      isCancelling: true,
    ));

    final (success, msg) = await _repository.cancelRequest(requestId);

    if (success) {
      final updatedRequests = await _repository.getRequests(status: currentState.currentStatusFilter);
      emit(LocationChangeHistoryLoaded(
        updatedRequests,
        currentStatusFilter: currentState.currentStatusFilter,
        isCancelling: false,
        actionMessage: msg ?? 'تم إلغاء الطلب بنجاح.',
      ));
    } else {
      emit(LocationChangeHistoryLoaded(
        currentState.requests,
        currentStatusFilter: currentState.currentStatusFilter,
        isCancelling: false,
        actionMessage: msg ?? 'تعذر إلغاء الطلب.',
      ));
    }
  }
}
