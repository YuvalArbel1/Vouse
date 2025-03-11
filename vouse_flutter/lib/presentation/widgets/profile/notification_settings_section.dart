// lib/presentation/widgets/profile/notification_settings_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/data/notification/notification_service.dart';
import 'package:vouse_flutter/presentation/providers/notification/notification_provider.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_section_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_tile_widget.dart';

/// A widget that displays notification settings in the profile screen.
class NotificationSettingsSection extends ConsumerStatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  ConsumerState<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends ConsumerState<NotificationSettingsSection> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  /// Check the current notification status
  Future<void> _checkNotificationStatus() async {
    try {
      setState(() => _isLoading = true);

      // Read the notification status from preferences
      await ref.read(notificationStatusProvider.notifier).checkStatus();

      // Also check actual device permission status
      final notificationService = NotificationService();
      final areEnabled = await notificationService.areNotificationsEnabled();

      // If permissions are actually enabled but our state says disabled, update it
      if (areEnabled && !ref.read(notificationStatusProvider)) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final token = await notificationService.getToken();
          if (token != null) {
            await ref
                .read(notificationStatusProvider.notifier)
                .enableNotifications(userId, token);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking notification status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Toggle notifications (enable/disable)
  Future<void> _toggleNotifications() async {
    final currentStatus = ref.read(notificationStatusProvider);
    final notificationService = NotificationService();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      if (currentStatus) {
        // Disable notifications
        await ref
            .read(notificationStatusProvider.notifier)
            .disableNotifications(userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications disabled'),
            backgroundColor: Colors.grey,
          ),
        );
      } else {
        // Enable notifications
        await notificationService.initialize();
        final token = await notificationService.getToken();

        if (token != null) {
          await ref
              .read(notificationStatusProvider.notifier)
              .enableNotifications(userId, token);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications enabled'),
                backgroundColor: vAccentColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch notification status
    final notificationStatus = ref.watch(notificationStatusProvider);

    return SettingsSectionWidget(
      title: 'Notifications',
      children: [
        // Status card at the top
        if (notificationStatus) ...[
          // Connected state
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vAccentColor.withAlpha(30),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  size: 28,
                  color: vAccentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications Enabled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: vAccentColor,
                        ),
                      ),
                      const Text(
                        'You will receive updates about your posts',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vAccentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          SettingsTileWidget(
            title: 'Disable Notifications',
            icon: Icons.notifications_off,
            iconColor: Colors.red,
            onTap: _toggleNotifications,
            isLoading: _isLoading,
            isDestructive: true,
          ),
        ] else ...[
          // Disconnected state
          SettingsTileWidget(
            title: 'Enable Notifications',
            icon: Icons.notifications,
            iconColor: vAccentColor,
            onTap: _toggleNotifications,
            isLoading: _isLoading,
          ),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vPrimaryColor.withAlpha(20),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: vPrimaryColor, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Enable notifications to get updates when your posts are published and receive engagement summaries.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
