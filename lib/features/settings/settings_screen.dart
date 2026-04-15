import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text("Settings"),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: (user?.photoURL != null)
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: (user?.photoURL == null)
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? "Guest User",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.email ?? "Sign in to sync data",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: auth.isLoading
                              ? null
                              : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                          icon: auth.isLoading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSection(theme, "PREFERENCES", [
                    _settingsTile(
                      theme,
                      Icons.notifications_active_outlined,
                      "Notifications",
                      "Alerts for upcoming dues",
                      hasSwitch: true,
                    ),
                    _settingsTile(
                      theme,
                      Icons.fingerprint_rounded,
                      "Biometric Lock",
                      "Secure your financial data",
                      hasSwitch: false,
                    ),
                    _settingsTile(
                      theme,
                      Icons.translate_rounded,
                      "Language",
                      "English (Default)",
                      hasSwitch: false,
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSection(theme, "SUPPORT", [
                    _settingsTile(
                      theme,
                      Icons.cloud_done_outlined,
                      "Cloud Backup",
                      "Automatic sync enabled",
                      hasSwitch: true,
                    ),
                    _settingsTile(
                      theme,
                      Icons.contact_support_outlined,
                      "Support Hub",
                      "Chat with our specialists",
                      hasSwitch: false,
                    ),
                    _settingsTile(
                      theme,
                      Icons.verified_user_outlined,
                      "Privacy",
                      "Data encryption details",
                      hasSwitch: false,
                    ),
                  ]),
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      "VERSION 1.2.0 • BUILD 2024",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _settingsTile(
      ThemeData theme,
      IconData icon,
      String title,
      String sub, {
        required bool hasSwitch,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: hasSwitch
            ? Switch(value: true, onChanged: (v) {})
            : const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}