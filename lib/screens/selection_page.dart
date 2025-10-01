import 'package:flutter/material.dart';
import 'citizen_page.dart';
import 'officer_page.dart';

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Garbage Vehicle Tracking System"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CitizenPage(),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text("Citizen"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficerPage(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text("Officer"),
            ),
          ],
        ),
      ),
    );
  }
}
