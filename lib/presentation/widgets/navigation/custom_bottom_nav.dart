// lib/presentation/widgets/navigation/custom_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/util/colors.dart';

/// Provides the currently selected bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// A custom animated bottom navigation bar with a floating center button.
///
/// Features:
/// - Smooth selection animations
/// - Elevated center button for post creation
/// - Accent color theme
/// - Tab selection state management via Riverpod
/// - Proper respect for system navigation insets
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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

              // Profile tab
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                index: 3,
                currentIndex: currentIndex,
                onTap: () => _handleTabTap(ref, 3),
              ),
            ],
          ),

          // Centered floating button
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

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with scale effect
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(isSelected ? 8 : 0),
              decoration: BoxDecoration(
                color: isSelected ? vAccentColor.withAlpha(26) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (value * 0.2),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      color: isSelected ? vAccentColor : Colors.grey,
                      size: 24,
                    ),
                  );
                },
              ),
            ),

            // Label text with slide-up animation
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, isSelected ? 0 : 4, 0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? vAccentColor : Colors.grey,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the elevated center button for post creation
  Widget _buildCenterButton() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: GestureDetector(
        onTap: onCreatePostPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: vAccentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: vAccentColor.withAlpha(77),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Handles tab selection
  void _handleTabTap(WidgetRef ref, int index) {
    ref.read(bottomNavIndexProvider.notifier).state = index;
    onTabSelected(index);
  }
}