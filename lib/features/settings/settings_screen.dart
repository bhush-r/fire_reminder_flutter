import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("App Lock"),
            subtitle: Text("PIN / Biometric (coming soon)"),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Reminders"),
            subtitle: Text("Payment notifications"),
          ),
          ListTile(
            leading: Icon(Icons.backup),
            title: Text("Backup & Restore"),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text("About App"),
          ),
        ],
      ),
    );
  }
}
