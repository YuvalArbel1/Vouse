import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vouse_flutter/presentation/screens/splash/app_wrapper.dart';
import 'core/util/ui_settings.dart';
import 'firebase_options.dart';

/// The main entry point of the Vouse app.
///
/// This function performs the following steps:
/// 1. Ensures that the widget binding is initialized.
/// 2. Preserves the native splash screen to be removed manually later.
/// 3. Initializes Firebase with platform-specific options.
/// 4. Runs the app wrapped in a [ProviderScope] to enable Riverpod state management.
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen so that it can be manually removed later.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Apply edge-to-edge UI immediately at app start
  UiSettings.applyEdgeToEdgeUI();

  // Initialize Firebase with the current platform's configuration.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app inside a ProviderScope for Riverpod support.
  runApp(const ProviderScope(child: App()));
}

/// The root widget of the Vouse app.
///
/// This widget sets up the [MaterialApp] and defines [AppWrapper] as the home screen.
class App extends StatelessWidget {
  /// Creates an [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppWrapper(),
    );
  }
}
