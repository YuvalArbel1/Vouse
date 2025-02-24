// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import '../../../core/resources/data_state.dart';
import '../../providers/auth/firebase/firebase_auth_notifier.dart';
import '../post/create_post_screen.dart';

/// A sample Home screen that displays an AppBar with a "Logout" button and
/// a centered "Add post" icon.
///
/// When the "Logout" button is pressed, it attempts to sign the user out
/// using [firebaseAuthNotifierProvider] and navigates to the [SignInScreen]
/// on success. Pressing the "Add post" icon navigates to the [CreatePostScreen].
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Remove the native splash screen after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Handles the logout process.
  ///
  /// Calls [signOut] on the [firebaseAuthNotifierProvider]. If logout succeeds,
  /// navigates to the [SignInScreen] by removing all previous routes.
  /// Otherwise, displays a SnackBar with the error message.
  Future<void> _handleLogout() async {
    // Sign out asynchronously.
    await ref.read(firebaseAuthNotifierProvider.notifier).signOut();
    // Ensure widget is still mounted before using BuildContext.
    if (!mounted) return;

    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
      );
    } else if (authState is DataFailed<void>) {
      final errorMsg = authState.error?.error ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $errorMsg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        // Logout button in the AppBar.
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
        // "Add post" icon navigates to the CreatePostScreen.
        child: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            );
          },
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
