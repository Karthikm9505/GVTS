import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/firebase_service.dart';

class MapScreen extends StatefulWidget {
  final bool officerMode;
  const MapScreen({super.key, required this.officerMode});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _firebase = FirebaseService();
  final String _trackedVehicleId = "G123";
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    if (widget.officerMode) {
      _firebase.allVehiclesStream().listen((vehicles) {
        setState(() {
          markers = vehicles.values.map((v) => Marker(
            point: LatLng(v.lat, v.lng),
            width: 40,
            height: 40,
            child: const Icon(Icons.delete, color: Colors.green, size: 32),
          )).toList();
        });
      });
    } else {
      _firebase.vehicleStream(_trackedVehicleId).listen((v) {
        setState(() {
          markers = [
            Marker(
              point: LatLng(v.lat, v.lng),
              width: 40,
              height: 40,
              child: const Icon(Icons.delete, color: Colors.red, size: 32),
            )
          ];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.officerMode ? "Officer Mode" : "Citizen Mode")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(16.5062, 80.6480),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.gvts',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
