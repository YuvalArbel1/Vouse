// lib/presentation/widgets/navigation/custom_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/colors.dart';

/// Provides the currently selected bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// A custom animated bottom navigation bar with a floating app logo button.
///
/// Features:
/// - Smooth selection animations with scale and slide effects
/// - Elevated center button with app logo
/// - Custom accent color theming
/// - Tab selection state management via Riverpod
/// - Proper handling of system navigation bar insets
/// - Beautiful ripple effects and transitions
class CustomBottomNavBar extends ConsumerWidget {
  /// Function to handle when a tab is selected
  final Function(int) onTabSelected;

  /// Function to handle when the create post button is pressed
  final VoidCallback onCreatePostPressed;

  /// Creates a [CustomBottomNavBar] with required callbacks
  const CustomBottomNavBar({
    super.key,
    required this.onTabSelected,
    required this.onCreatePostPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        // Add rounded top corners for better visual separation
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Main navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home tab
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: () => _handleTabTap(ref, 0),
              ),

              // Post History tab
              _buildNavItem(
                context: context,
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: 'Posts',
                index: 1,
                currentIndex: currentIndex,
                onTap: () => _handleTabTap(ref, 1),
              ),

              // Empty space for center button
              const SizedBox(width: 60),

              // Scheduled Posts tab
              _buildNavItem(
                context: context,
                icon: Icons.schedule_outlined,
                selectedIcon: Icons.schedule,
                label: 'Scheduled',
                index: 2,
                currentIndex: currentIndex,
                onTap: () => _handleTabTap(ref, 2),
              ),

              // Settings tab (was Profile)
              _buildNavItem(
                context: context,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
                index: 3,
                currentIndex: currentIndex,
                onTap: () => _handleTabTap(ref, 3),
              ),
            ],
          ),

          // Centered floating button with app logo
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildCenterButton(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an individual navigation item with animation
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;

    // Define colors based on selection state
    final Color iconColor = isSelected ? vAccentColor : Colors.grey;
    final Color textColor = isSelected ? vAccentColor : Colors.grey;
    final Color bgColor = isSelected ? vAccentColor.withAlpha(26) : Colors.transparent;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: vAccentColor.withAlpha(40),
          highlightColor: vAccentColor.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container with scale and background
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(isSelected ? 10 : 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1.0 + (value * 0.2),
                      child: Icon(
                        isSelected ? selectedIcon : icon,
                        color: iconColor,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),

              // Label text with slide and opacity transitions
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: textColor,
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedPadding(
                    padding: EdgeInsets.only(top: isSelected ? 4 : 6),
                    duration: const Duration(milliseconds: 200),
                    child: Text(label),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the elevated center button with app logo
  Widget _buildCenterButton() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCreatePostPressed,
          customBorder: const CircleBorder(),
          splashColor: vAccentColor.withAlpha(40),
          highlightColor: vAccentColor.withAlpha(20),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: vPrimaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: vPrimaryColor.withAlpha(77),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              // Ensure perfect centering with explicit sizing and alignment
              child: SizedBox(
                width: 30,
                height: 30,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset(
                    'assets/images/vouse_app_logo_white.png',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles tab selection
  void _handleTabTap(WidgetRef ref, int index) {
    // Add haptic feedback (optional)
    // HapticFeedback.lightImpact();

    // Update the provider state
    ref.read(bottomNavIndexProvider.notifier).state = index;

    // Call the callback
    onTabSelected(index);
  }
}