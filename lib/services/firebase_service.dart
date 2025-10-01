import 'package:firebase_database/firebase_database.dart';
import '../models/vehicle.dart';

class FirebaseService {
  final _db = FirebaseDatabase.instance;

  Stream<Vehicle> vehicleStream(String vehicleId) {
    final ref = _db.ref('vehicles/$vehicleId/location');
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final map = (data ?? {}).map((k, v) => MapEntry(k.toString(), v));
      return Vehicle.fromMap(vehicleId, map);
    });
  }

  Stream<Map<String, Vehicle>> allVehiclesStream() {
    final ref = _db.ref('vehicles');
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final result = <String, Vehicle>{};
      if (data != null) {
        data.forEach((vid, vdata) {
          final m = (vdata as Map)['location'] as Map<dynamic, dynamic>?;
          if (m != null) {
            final map = m.map((k, v) => MapEntry(k.toString(), v));
            result[vid.toString()] = Vehicle.fromMap(vid.toString(), map);
          }
        });
      }
      return result;
    });
  }
}
