import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
  final String citizenId; // e.g., "citizen1"
  const SettingsPage({super.key, required this.citizenId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("citizens");
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();

  Future<void> _saveLocation() async {
    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid latitude & longitude")),
      );
      return;
    }

    // Write to Firebase: citizens/citizen1/location
    await dbRef.child(widget.citizenId).child("location").set({
      "lat": lat,
      "lng": lng,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location saved successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Citizen Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter your home location",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: "Latitude",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: "Longitude",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveLocation,
              icon: const Icon(Icons.save),
              label: const Text("Save Location"),
            ),
          ],
        ),
      ),
    );
  }
}
