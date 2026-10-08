import 'package:flutter_test/flutter_test.dart';
import 'package:kids_transport/features/parent/trips/data/models/active_trip_model.dart';

void main() {
  group('ActiveTripModel - رحلة السائق البديل', () {
    test('رحلة عادية: is_substitute = false والحقول الجديدة فاضية', () {
      final trip = ActiveTripModel.fromJson({
        'trip_id': 850,
        'trip_type': 'Morning',
        'status': 'in_progress',
        'is_substitute': false,
        'original_trip_id': null,
        'dispatch_id': null,
        'driver': {'id': 908, 'name': 'ريان خالد المريمي', 'phone': '0916466628'},
        'vehicle': {'info': 'Ford Coaster (ط ط 2013)'},
        'children': [
          {
            'child_id': 45,
            'child_name': 'عمر خالد الككلي',
            'child_status': 'picked_up',
            'school': {'id': 3, 'name': 'مدرسة بن عاشور', 'lat': 32.874, 'lng': 13.190},
          },
        ],
      });

      expect(trip.isSubstitute, isFalse);
      expect(trip.originalTripId, isNull);
      expect(trip.dispatchId, isNull);
      expect(trip.uniqueSchools, hasLength(1));
    });

    test('رحلة بديل: تقرا original_trip_id و dispatch_id، والمدرسة النصية ما تنرسمش', () {
      final trip = ActiveTripModel.fromJson({
        'trip_id': 851,
        'trip_type': 'Morning',
        'status': 'in_progress',
        'is_substitute': true,
        'original_trip_id': 850,
        'dispatch_id': 14,
        'driver': {'id': 12, 'name': 'محمد علي الشريف', 'phone': '0912345678'},
        'vehicle': {'info': 'Toyota Hiace (5-12345)'},
        'children': [
          {
            'child_id': 45,
            'child_name': 'عمر خالد الككلي',
            'child_status': 'waiting',
            'school_name': 'مدرسة بن عاشور',
            'home_address': 'حي دمشق',
            'school_address': 'بن عاشور',
          },
        ],
      });

      expect(trip.isSubstitute, isTrue);
      expect(trip.originalTripId, 850);
      expect(trip.dispatchId, 14);
      expect(trip.driver.name, 'محمد علي الشريف');
      // الاسم يقعد للعرض، لكن بدون إحداثيات ما تطلعش علامة في (0, 0)
      expect(trip.children.first.school?.name, 'مدرسة بن عاشور');
      expect(trip.uniqueSchools, isEmpty);
      expect(trip.uniqueHomeAddresses, isEmpty);
    });
  });
}
