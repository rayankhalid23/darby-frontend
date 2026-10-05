part of 'live_trip_cubit.dart';

abstract class LiveTripState extends Equatable {
  const LiveTripState();

  @override
  List<Object?> get props => [];
}

class LiveTripInitial extends LiveTripState {}

class LiveTripLoading extends LiveTripState {}

class LiveTripError extends LiveTripState {
  final String message;

  const LiveTripError(this.message);

  @override
  List<Object?> get props => [message];
}

class LiveTripLoaded extends LiveTripState {
  final String tripStatus;
  final List<DriverTripStopModel> stops;
  final List<LiveTripChildItem> childItems;
  final TripLiveCurrentChildModel? currentChild;
  final TripProgressModel progress;
  final int? pendingActionTripChildId;
  final String? actionErrorMessage;
  final String? blockingErrorCode;
  final String? blockingErrorMessage;
  final TripCompleteSummaryModel? completedSummary;

  final VehicleBreakdownResponseModel? breakdownResult;

  /// اسم المسار (route_name) من GET /driver/trips/{tripId}.
  final String routeName;

  /// المحطة/الطفل التالي — يُعتمَد فقط من next_stop/next_child المُرجعة
  /// فعلياً ضمن استجابة آخر إجراء ناجح (Pickup/Dropoff/Absent/Skip/QR).
  /// null يعني "غير معروفة بعد" وليس بالضرورة "انتهت الرحلة".
  final NextStopModel? nextStop;
  final NextChildModel? nextChild;

  /// آخر تنبيه اقتراب/وصول من استجابة /location ووقت استلامه (لعداد الانتظار)
  final ProximityAlertModel? proximityAlert;
  final DateTime? proximityAlertReceivedAt;

  /// الباك رفض الاستئناف لأن سائق بديل قبل مهمة الإنقاذ
  /// (SUBSTITUTE_ALREADY_ACCEPTED) — الرحلة تقعد معلّقة والاستئناف مقفول
  final bool substituteAccepted;

  const LiveTripLoaded({
    required this.tripStatus,
    required this.stops,
    required this.childItems,
    required this.currentChild,
    required this.progress,
    this.pendingActionTripChildId,
    this.actionErrorMessage,
    this.blockingErrorCode,
    this.blockingErrorMessage,
    this.completedSummary,
    this.breakdownResult,
    this.routeName = '',
    this.nextStop,
    this.nextChild,
    this.proximityAlert,
    this.proximityAlertReceivedAt,
    this.substituteAccepted = false,
  });

  bool get isInProgress => tripStatus == 'in_progress';
  bool get isSuspended => tripStatus == 'suspended_breakdown';
  bool get isCompleted => tripStatus == 'completed';
  bool get canComplete => progress.remaining <= 0;

  LiveTripLoaded copyWith({
    String? tripStatus,
    List<DriverTripStopModel>? stops,
    List<LiveTripChildItem>? childItems,
    TripLiveCurrentChildModel? currentChild,
    bool clearCurrentChild = false,
    TripProgressModel? progress,
    int? pendingActionTripChildId,
    bool clearPendingAction = false,
    String? actionErrorMessage,
    bool clearActionError = false,
    String? blockingErrorCode,
    String? blockingErrorMessage,
    bool clearBlockingError = false,
    TripCompleteSummaryModel? completedSummary,
    VehicleBreakdownResponseModel? breakdownResult,
    bool clearBreakdownResult = false,
    String? routeName,
    NextStopModel? nextStop,
    bool clearNextStop = false,
    NextChildModel? nextChild,
    bool clearNextChild = false,
    ProximityAlertModel? proximityAlert,
    DateTime? proximityAlertReceivedAt,
    bool clearProximityAlert = false,
    bool? substituteAccepted,
  }) {
    return LiveTripLoaded(
      tripStatus: tripStatus ?? this.tripStatus,
      stops: stops ?? this.stops,
      childItems: childItems ?? this.childItems,
      currentChild: clearCurrentChild ? null : (currentChild ?? this.currentChild),
      progress: progress ?? this.progress,
      pendingActionTripChildId: clearPendingAction
          ? null
          : (pendingActionTripChildId ?? this.pendingActionTripChildId),
      actionErrorMessage: clearActionError ? null : (actionErrorMessage ?? this.actionErrorMessage),
      blockingErrorCode: clearBlockingError ? null : (blockingErrorCode ?? this.blockingErrorCode),
      blockingErrorMessage:
          clearBlockingError ? null : (blockingErrorMessage ?? this.blockingErrorMessage),
      completedSummary: completedSummary ?? this.completedSummary,
      breakdownResult: clearBreakdownResult ? null : (breakdownResult ?? this.breakdownResult),
      routeName: routeName ?? this.routeName,
      nextStop: clearNextStop ? null : (nextStop ?? this.nextStop),
      nextChild: clearNextChild ? null : (nextChild ?? this.nextChild),
      proximityAlert: clearProximityAlert ? null : (proximityAlert ?? this.proximityAlert),
      proximityAlertReceivedAt: clearProximityAlert
          ? null
          : (proximityAlertReceivedAt ?? this.proximityAlertReceivedAt),
      substituteAccepted: substituteAccepted ?? this.substituteAccepted,
    );
  }

  @override
  List<Object?> get props => [
        tripStatus,
        stops,
        childItems,
        currentChild,
        progress,
        pendingActionTripChildId,
        actionErrorMessage,
        blockingErrorCode,
        blockingErrorMessage,
        completedSummary,
        breakdownResult,
        routeName,
        nextStop,
        nextChild,
        proximityAlert,
        proximityAlertReceivedAt,
        substituteAccepted,
      ];
}
