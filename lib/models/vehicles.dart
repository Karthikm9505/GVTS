class Vehicle {
  final String id;
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final int? ts;


  Vehicle({
    required this.id,
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.ts,
  });


  factory Vehicle.fromMap(String id, Map data) {
    return Vehicle(
      id: id,
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      speed: data['speed'] == null ? null : (data['speed'] as num).toDouble(),
      heading: data['heading'] == null ? null : (data['heading'] as num).toDouble(),
      ts: data['ts'] as int?,
    );
  }
}