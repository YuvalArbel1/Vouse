// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vouse_flutter/presentation/theme/app_theme.dart';
import 'package:vouse_flutter/presentation/screens/splash/app_wrapper.dart';
import 'firebase_options.dart';

/// The main entry point of the Vouse app.
///
/// This function performs the following steps:
/// 1. Ensures that the widget binding is initialized.
/// 2. Configures native splash screen to persist during initialization.
/// 3. Initializes Firebase with platform-specific options.
/// 4. Runs the app wrapped in a [ProviderScope] to enable Riverpod state management.
void main() async {
  // Ensure Flutter binding is initialized
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen so it remains visible during initialization
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // Initialize Firebase with the current platform's configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Run the app inside a ProviderScope for Riverpod support
    runApp(const ProviderScope(child: App()));
  } catch (e) {
    // If Firebase initialization fails, log the error and remove splash
    if (kDebugMode) {
      print('Firebase Initialization Error: $e');
    }
    FlutterNativeSplash.remove();

    // Optionally, run with error handling
    runApp(ErrorApp());
  }
}

/// The root widget of the Vouse app.
///
/// This widget sets up the [MaterialApp] and defines [AppWrapper] as the home screen.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get theme from provider
    final appTheme = ref.watch(appThemeProvider);
    final themeData = ref.watch(themeDataProvider);

    // Configure edge-to-edge display and system UI
    appTheme.configureEdgeToEdge();
    appTheme.configureSystemUI();

    return MaterialApp(
      title: 'Vouse Social',
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: const AppWrapper(),
    );
  }
}

/// An error app to display when initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'App Initialization Failed. Please restart the app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}