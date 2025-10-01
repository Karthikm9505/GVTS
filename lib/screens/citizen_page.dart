import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;

import 'settings_page.dart';

class CitizenPage extends StatefulWidget {
  const CitizenPage({super.key});

  @override
  State<CitizenPage> createState() => _CitizenPageState();
}

class _CitizenPageState extends State<CitizenPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("vehicles");
  LatLng? citizenLocation; // Will be loaded from Firebase
  Map<String, LatLng> vehicleLocations = {};
  bool notificationSent = false;

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();

    // Fetch citizen location from Firebase
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
      }
    });

    // Listen to all vehicles
    dbRef.onValue.listen((event) {
      final vehicles = event.snapshot.value as Map<dynamic, dynamic>?;
      if (vehicles != null && vehicles.isNotEmpty) {
        final updatedLocations = <String, LatLng>{};

        vehicles.forEach((key, value) {
          final vData = (value as Map)["location"];
          if (vData != null &&
              vData["lat"] != null &&
              vData["lng"] != null) {
            final truckLoc = LatLng(
              (vData["lat"] as num).toDouble(),
              (vData["lng"] as num).toDouble(),
            );

            updatedLocations[key.toString()] = truckLoc;

            // Check distance for notifications
            if (citizenLocation != null) {
              final distance = _calculateDistance(
                citizenLocation!.latitude,
                citizenLocation!.longitude,
                truckLoc.latitude,
                truckLoc.longitude,
              );

              if (distance <= 0.3 && !notificationSent) {
                _showNotification(key.toString(), distance);
                notificationSent = true;
              }
            }
          }
        });

        setState(() {
          vehicleLocations = updatedLocations;
        });
      }
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('ic_stat_notify');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> _showNotification(String vehicleId, double distance) async {
    const androidDetails = AndroidNotificationDetails(
      'nearby_truck_channel',
      'Nearby Truck Alerts',
      channelDescription: 'Notifies when a truck is near the citizen location',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Garbage Truck Nearby',
      'Truck $vehicleId is only ${(distance * 1000).toStringAsFixed(0)} meters away!',
      platformDetails,
    );
  }

  // Haversine formula for distance between 2 lat/lng points (km)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Citizen View"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const SettingsPage(citizenId: "citizen1"),
                ),
              );
            },
          ),
        ],
      ),
      body: (citizenLocation == null)
          ? const Center(child: Text("Set your location in Settings"))
          : FlutterMap(
        options: MapOptions(
          initialCenter: citizenLocation!,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.gvts_fixed',
          ),
          // Citizen marker
          MarkerLayer(
            markers: [
              Marker(
                point: citizenLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.home,
                    color: Colors.blue, size: 35),
              ),
            ],
          ),
          // Vehicle markers
          MarkerLayer(
            markers: vehicleLocations.entries.map((entry) {
              return Marker(
                width: 50,
                height: 50,
                point: entry.value,
                child: Column(
                  children: [
                    const Icon(Icons.local_shipping,
                        color: Colors.green, size: 30),
                    Text(entry.key,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: vehicleLocations.isNotEmpty
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Tracking ${vehicleLocations.length} vehicles",
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      )
          : null,
    );
  }
}
