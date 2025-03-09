// lib/presentation/screens/profile/profile_twitter_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/twitter_connection_provider.dart';
import 'package:vouse_flutter/presentation/providers/auth/x/x_auth_providers.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_tile_widget.dart';
import 'package:vouse_flutter/presentation/widgets/profile/settings_section_widget.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';

/// A widget that displays and manages Twitter connection in the profile screen.
class ProfileTwitterSection extends ConsumerStatefulWidget {
  const ProfileTwitterSection({super.key});

  @override
  ConsumerState<ProfileTwitterSection> createState() =>
      _ProfileTwitterSectionState();
}

class _ProfileTwitterSectionState extends ConsumerState<ProfileTwitterSection> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check connection status on initialization
    _checkTwitterConnection();
  }

  /// Check Twitter connection status using the provider
  Future<void> _checkTwitterConnection({bool forceCheck = false}) async {
    try {
      setState(() => _isLoading = true);

      // Check Twitter connection status with force flag
      await ref
          .read(twitterConnectionProvider.notifier)
          .checkConnectionStatus(forceCheck: forceCheck);

      // Debug log the current state after check
      final connectionState =
          ref.read(twitterConnectionProvider).connectionState;
      debugPrint(
          "ProfileTwitterSection: Connection state after check: $connectionState");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Initiate Twitter OAuth flow and connect to the server
  Future<void> _connectTwitter() async {
    setState(() => _isLoading = true);

    try {
      debugPrint("ProfileTwitterSection: Starting X connection process");

      // Start the OAuth flow to get tokens
      final result = await ref.read(signInToXUseCaseProvider).call();

      if (!mounted) return;

      if (result is DataSuccess<XAuthTokens> && result.data != null) {
        debugPrint("ProfileTwitterSection: Got X tokens, connecting");

        // Connect with the obtained tokens
        final connectResult = await ref
            .read(twitterConnectionProvider.notifier)
            .connectTwitter(result.data!);

        if (!mounted) return;

        if (connectResult) {
          // Force refresh the connection status to update UI consistently
          await ref
              .read(twitterConnectionProvider.notifier)
              .checkConnectionStatus(forceCheck: true);

          debugPrint("ProfileTwitterSection: X connection successful");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text('Twitter account connected successfully'),
                ],
              ),
              backgroundColor: vAccentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          debugPrint("ProfileTwitterSection: X connection failed");
          toast('Failed to connect Twitter account');
        }
      } else if (result is DataFailed) {
        debugPrint(
            "ProfileTwitterSection: Twitter authentication failed: ${result.error?.error}");
        toast('Twitter authentication failed: ${result.error?.error}');
      }
    } catch (e) {
      debugPrint("ProfileTwitterSection: Error connecting Twitter: $e");
      toast('Error connecting Twitter: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Disconnect Twitter account
  Future<void> _disconnectTwitter() async {
    // Show confirmation dialog
    final shouldDisconnect = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disconnect X Account'),
            content: const Text(
                'Are you sure you want to disconnect your X account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Disconnect',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDisconnect) return;

    setState(() => _isLoading = true);

    try {
      debugPrint("ProfileTwitterSection: Starting X disconnection process");

      final disconnectResult = await ref
          .read(twitterConnectionProvider.notifier)
          .disconnectTwitter();

      if (!mounted) return;

      // Force refresh the connection status to update UI consistently
      await ref
          .read(twitterConnectionProvider.notifier)
          .checkConnectionStatus(forceCheck: true);

      if (disconnectResult) {
        debugPrint("ProfileTwitterSection: X disconnection successful");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Twitter account disconnected successfully'),
            backgroundColor: vBodyGrey,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        debugPrint("ProfileTwitterSection: X disconnection failed");
        toast('Failed to disconnect Twitter account');
      }
    } catch (e) {
      debugPrint("ProfileTwitterSection: Error disconnecting Twitter: $e");
      toast('Error disconnecting Twitter: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Twitter connection state
    final twitterConnection = ref.watch(twitterConnectionProvider);
    final isConnected =
        twitterConnection.connectionState == TwitterConnectionState.connected;
    final username = twitterConnection.username;

    return SettingsSectionWidget(
      title: 'X (Twitter) Integration',
      children: [
        if (isConnected) ...[
          // Connected state
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vAccentColor.withAlpha(30),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.alternate_email,
                  size: 28,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Twitter Account Connected',
                        style: boldTextStyle(size: 16),
                      ),
                      if (username != null)
                        Text(
                          '@$username',
                          style: secondaryTextStyle(),
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
                  child: Text(
                    'Active',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          SettingsTileWidget(
            title: 'Disconnect X Account',
            icon: Icons.link_off,
            iconColor: Colors.red,
            onTap: _disconnectTwitter,
            isLoading: _isLoading,
            isDestructive: true,
          ),
        ] else ...[
          // Disconnected state
          SettingsTileWidget(
            title: 'Connect X Account',
            icon: Icons.link,
            iconColor: vAccentColor,
            onTap: _connectTwitter,
            isLoading: _isLoading,
          ),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vPrimaryColor.withAlpha(20),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: vPrimaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connect your X account to schedule and publish posts directly from Vouse.',
                    style: secondaryTextStyle(color: vBodyGrey),
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
