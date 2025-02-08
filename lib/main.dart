import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vouse_flutter/presentation/providers/home/local_user_providers.dart';

// The screens we might show
import 'core/resources/data_state.dart';
import 'domain/usecases/home/get_user_usecase.dart';
import 'presentation/screens/auth/signin.dart';
import 'presentation/screens/home/edit_profile_screen.dart';
import 'presentation/screens/home/home_screen.dart';

// Our local user usecases
import 'domain/entities/user_entity.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: App()));
}

/// The root of our app. We do the "authStateChanges" check, then see
/// if we have a local user record in DB. If not, show edit profile.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // We use a StreamBuilder to watch FirebaseAuth user changes
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          // 1) If the stream is still loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2) If no user is logged in, go to SignInScreen
          final firebaseUser = snapshot.data;
          if (firebaseUser == null) {
            return const SignInScreen();
          }

          // 3) If we do have a user, check local DB for their profile
          return FutureBuilder<DataState<UserEntity?>>(
            future: ref
                .read(getUserUseCaseProvider)
                .call(params: GetUserParams(firebaseUser.uid)),
            builder: (ctx, snap) {
              if (!snap.hasData ||
                  snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final dataState = snap.data;
              if (dataState is DataSuccess<UserEntity?>) {
                final userEntity = dataState.data; // might be null
                if (userEntity == null) {
                  // Not found => show EditProfileScreen
                  return const EditProfileScreen();
                } else {
                  // Found => show HomeScreen
                  return const HomeScreen();
                }
              } else if (dataState is DataFailed<UserEntity?>) {
                // Some error occurred
                return Scaffold(
                  body: Center(
                    child: Text(
                      'Error loading profile: ${dataState.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              // fallback
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        },
      ),
    );
  }
}
