import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

class CitizenPage extends StatefulWidget {
  const CitizenPage({super.key});

  @override
  State<CitizenPage> createState() => _CitizenPageState();
}

class _CitizenPageState extends State<CitizenPage> {
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  LatLng? citizenLocation;
  String? _latestVehicleId;
  LatLng? _latestVehicleLocation;
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
              _latestVehicleId = key.toString();
              _latestVehicleLocation = LatLng(lat, lng);
            });
            _evaluateProximity();
          }
        });
      }
    });
  }

  void _evaluateProximity() {
    if (citizenLocation == null || _latestVehicleLocation == null) {
      return;
    }

    final distance = _calculateDistance(
      citizenLocation!.latitude,
      citizenLocation!.longitude,
      _latestVehicleLocation!.latitude,
      _latestVehicleLocation!.longitude,
    );

    if (distance <= 0.3) {
      if (!notificationSent && _latestVehicleId != null) {
        _showNotification(_latestVehicleId!, distance);
        notificationSent = true;
      }
    } else if (notificationSent) {
      notificationSent = false;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
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
      'Truck $vehicleId is ${(distance * 1000).toStringAsFixed(0)} meters away!',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen Page"),
      ),
      body: Center(
        child: citizenLocation == null
            ? const CircularProgressIndicator()
            : Text(
                "Citizen Location: ${citizenLocation!.latitude}, ${citizenLocation!.longitude}\n"
                "Vehicle Location: ${_latestVehicleLocation?.latitude}, ${_latestVehicleLocation?.longitude}",
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}
