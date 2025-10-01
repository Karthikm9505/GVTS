import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class CitizenPage extends StatefulWidget {
  const CitizenPage({super.key});

  @override
  State<CitizenPage> createState() => _CitizenPageState();
}

class _CitizenPageState extends State<CitizenPage> {
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  LatLng? citizenLocation;
  LatLng? vehicleLocation;
  bool notificationSent = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchCitizenLocation();
    _listenVehicleLocation();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);
  }

  void _fetchCitizenLocation() {
    FirebaseDatabase.instance
        .ref("citizens/citizen1/location")
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          citizenLocation = LatLng(
            (data["lat"] as num).toDouble(),
            (data["lng"] as num).toDouble(),
          );
        });
        _evaluateProximity();
      }
    });
  }

  void _listenVehicleLocation() {
    FirebaseDatabase.instance.ref("vehicles").onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((key, value) {
          if (value["location"] != null) {
            final lat = (value["location"]["lat"] as num).toDouble();
            final lng = (value["location"]["lng"] as num).toDouble();
            setState(() {
              vehicleLocation = LatLng(lat, lng);
            });
            _evaluateProximity(vehicleId: key.toString());
          }
        });
      }
    });
  }

  void _evaluateProximity({String? vehicleId}) {
    if (citizenLocation == null || vehicleLocation == null) {
      return;
    }

    final distance = _calculateDistance(
      citizenLocation!.latitude,
      citizenLocation!.longitude,
      vehicleLocation!.latitude,
      vehicleLocation!.longitude,
    );

    if (distance <= 100 && !notificationSent) {
      _showNotification(vehicleId ?? 'Vehicle', distance);
      notificationSent = true;
    } else if (distance > 100) {
      notificationSent = false;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<void> _showNotification(String vehicleId, double distance) async {
    const androidDetails = AndroidNotificationDetails(
      'vehicle_channel',
      'Vehicle Notifications',
      channelDescription: 'Alerts when garbage vehicle is nearby',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Garbage Truck Nearby',
      'Truck $vehicleId is ${distance.toStringAsFixed(0)} meters away!',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    final citizen = citizenLocation;
    final vehicle = vehicleLocation;
    final distance = (citizen != null && vehicle != null)
        ? _calculateDistance(
            citizen.latitude,
            citizen.longitude,
            vehicle.latitude,
            vehicle.longitude,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen Page"),
      ),
      body: citizen == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: citizen,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.gvts',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: citizen,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 36,
                            ),
                          ),
                          if (vehicle != null)
                            Marker(
                              width: 40,
                              height: 40,
                              point: vehicle,
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.green,
                                size: 36,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Citizen Location: ${citizen.latitude.toStringAsFixed(5)}, "
                        "${citizen.longitude.toStringAsFixed(5)}",
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle == null
                            ? "Waiting for vehicle location..."
                            : "Vehicle Location: ${vehicle.latitude.toStringAsFixed(5)}, "
                                "${vehicle.longitude.toStringAsFixed(5)}",
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Distance: ${distance.toStringAsFixed(0)} meters",
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
