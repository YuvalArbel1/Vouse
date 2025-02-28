// lib/presentation/widgets/navigation/custom_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/util/colors.dart';

/// A custom animated bottom navigation bar with a floating app logo button.
///
/// Features:
/// - Smooth selection animations with scale and slide effects
/// - Elevated center button with app logo
/// - Custom accent color theming
/// - Proper handling of system navigation bar insets
/// - Beautiful ripple effects and transitions
/// - Improved edge-to-edge design
class CustomBottomNavBar extends StatelessWidget {
  /// Function to handle when a tab is selected
  final Function(int) onTabSelected;

  /// Function to handle when the create post button is pressed
  final VoidCallback onCreatePostPressed;

  /// Currently selected index
  final int currentIndex;

  /// Creates a [CustomBottomNavBar] with required callbacks
  const CustomBottomNavBar({
    super.key,
    required this.onTabSelected,
    required this.onCreatePostPressed,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 65,

      // Remove full background color and shadows for a cleaner look
      // This helps with edge-to-edge design
      decoration: BoxDecoration(
        // Subtle glass-like effect with light blur
        color: Colors.white.withAlpha(217),
        // Add minimal shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
        // Add rounded top corners for better visual separation
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Main navigation row
          Positioned(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home tab
                _buildNavItem(
                  context: context,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                  onTap: () => _handleTabTap(0),
                ),

                // Published Posts tab (renamed from Post History)
                _buildNavItem(
                  context: context,
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: 'Published',
                  index: 1,
                  onTap: () => _handleTabTap(1),
                ),

                // Empty space for center button
                const SizedBox(width: 60),

                // Upcoming Posts tab (renamed from Scheduled)
                _buildNavItem(
                  context: context,
                  icon: Icons.schedule_outlined,
                  selectedIcon: Icons.schedule,
                  label: 'Upcoming',
                  index: 2,
                  onTap: () => _handleTabTap(2),
                ),

                // Profile tab
                _buildNavItem(
                  context: context,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                  index: 3,
                  onTap: () => _handleTabTap(3),
                ),
              ],
            ),
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
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;

    // Define colors based on selection state
    final Color iconColor = isSelected ? vAccentColor : Colors.grey;
    final Color textColor = isSelected ? vAccentColor : Colors.grey;
    final Color bgColor =
        isSelected ? vAccentColor.withAlpha(26) : Colors.transparent;

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
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: iconColor,
                  size: 22, // Slightly smaller size
                ),
              ),

              // Label text with opacity transitions
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: textColor,
                  fontSize: isSelected ? 11 : 10, // Slightly smaller size
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
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
      offset: const Offset(0, -20), // Move up for emphasis
      child: GestureDetector(
        onTap: () {
          // Add haptic feedback for better user experience
          HapticFeedback.mediumImpact();
          onCreatePostPressed();
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            // Use gradient for more visual appeal
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                vAccentColor,
                vPrimaryColor,
              ],
            ),
            shape: BoxShape.circle,
            // Enhanced shadow for better visibility
            boxShadow: [
              BoxShadow(
                color: vPrimaryColor.withAlpha(100),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            // Add a pulsing animation effect
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.9, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles tab selection with optional haptic feedback
  void _handleTabTap(int index) {
    // Add haptic feedback for better user experience
    HapticFeedback.selectionClick();

    // Call the callback
    onTabSelected(index);
  }
}
