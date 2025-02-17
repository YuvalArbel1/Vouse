import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';

import '../../../core/resources/data_state.dart';
import '../../providers/auth/firebase_auth_notifier.dart';
import '../post/create_post_screen.dart';

/// A sample Home screen with an AppBar, "Add post" icon, and a "Logout" button.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Remove the splash after the first frame has rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  Future<void> _handleLogout() async {
    // 1) Call signOut on the notifier
    await ref.read(firebaseAuthNotifierProvider.notifier).signOut();

    // 2) Check final state from the notifier
    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      // If success => navigate to SignIn screen (and remove Home from stack)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false, // remove all previous
      );
    } else if (authState is DataFailed<void>) {
      // If failed => show error or toast
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
        // We add a "Logout" button on the right side in the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Center(
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
