import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math' as math;

class OfficerPage extends StatefulWidget {
  const OfficerPage({super.key});

  @override
  State<OfficerPage> createState() => _OfficerPageState();
}

class _OfficerPageState extends State<OfficerPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("vehicles");
  Map<String, Map<String, dynamic>> vehiclesData = {};

  @override
  void initState() {
    super.initState();

    dbRef.onValue.listen((event) {
      final vehicles = event.snapshot.value as Map<dynamic, dynamic>?;
      if (vehicles != null && vehicles.isNotEmpty) {
        final updated = <String, Map<String, dynamic>>{};
        vehicles.forEach((key, value) {
          final vData = (value as Map)["location"];
          if (vData != null &&
              vData["lat"] != null &&
              vData["lng"] != null) {
            updated[key.toString()] = {
              "lat": (vData["lat"] as num).toDouble(),
              "lng": (vData["lng"] as num).toDouble(),
              "speed": vData["speed"] ?? 0,
              "heading": vData["heading"] ?? 0,
              "ts": vData["ts"] ?? 0,
            };
          }
        });

        setState(() {
          vehiclesData = updated;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Officer Dashboard")),
      body: vehiclesData.isEmpty
          ? const Center(child: Text("No vehicle data found"))
          : Column(
        children: [
          // Map view with all trucks
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: vehiclesData.isNotEmpty
                    ? LatLng(
                  vehiclesData.values.first["lat"],
                  vehiclesData.values.first["lng"],
                )
                    : const LatLng(0, 0),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.gvts_fixed',
                ),
                MarkerLayer(
                  markers: vehiclesData.entries.map((entry) {
                    final data = entry.value;

                    // Choose color based on speed
                    final isMoving = (data["speed"] as num) > 0;
                    final color = isMoving ? Colors.green : Colors.red;

                    // Convert heading (degrees) to radians for rotation
                    final heading = (data["heading"] as num).toDouble();
                    final rotation = heading * math.pi / 180;

                    return Marker(
                      width: 70,
                      height: 70,
                      point: LatLng(data["lat"], data["lng"]),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Column(
                          children: [
                            Icon(Icons.local_shipping,
                                color: color, size: 35),
                            Text(
                              "${entry.key}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Vehicle details list
          Expanded(
            flex: 1,
            child: ListView(
              children: vehiclesData.entries.map((entry) {
                final data = entry.value;
                return ListTile(
                  leading: Icon(Icons.local_shipping,
                      color:
                      (data["speed"] as num) > 0 ? Colors.green : Colors.red),
                  title: Text("Vehicle: ${entry.key}"),
                  subtitle: Text(
                    "Lat: ${data["lat"]}, Lng: ${data["lng"]}\n"
                        "Speed: ${data["speed"]} m/s, Heading: ${data["heading"]}°",
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
