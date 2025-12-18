import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // USER PROFILE SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? "User Name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user?.email ?? "email@example.com", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          _sectionTitle("App Preferences"),
          _settingsTile(Icons.notifications_none_outlined, "Notification Reminders", "Manage payment alerts", true),
          _settingsTile(Icons.lock_outline, "Security Lock", "App password or Fingerprint", false),
          _settingsTile(Icons.language_outlined, "Language", "English / Hindi", false),

          const SizedBox(height: 24),

          _sectionTitle("Data & Support"),
          _settingsTile(Icons.cloud_upload_outlined, "Cloud Backup", "Sync data with your account", true),
          _settingsTile(Icons.help_outline, "Help & Support", "Contact us for issues", false),
          _settingsTile(Icons.info_outline, "Privacy Policy", "Learn how we handle data", false),

          const SizedBox(height: 40),

          Center(
            child: Text(
              "Version 1.0.0 (Stable)",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 14)),
    );
  }

  Widget _settingsTile(IconData icon, String title, String sub, bool hasSwitch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: hasSwitch
            ? Switch(value: true, onChanged: (v) {}, activeColor: AppColors.primary)
            : const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}