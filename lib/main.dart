import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    print('🔥 Starting Firebase initialization...');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    initError = e.toString();
    print('❌ FIREBASE INIT FAILED: $e');
  }

  runApp(RescuerApp(initError: initError));
}

class RescuerApp extends StatelessWidget {
  final String? initError;
  const RescuerApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DisasTrack Rescuer',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: initError != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text('Firebase Initialization Failed',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.red)),
                      const SizedBox(height: 12),
                      Text(initError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            )
          : StreamBuilder(
              stream: AuthService.instance.authChanges,
              builder: (context, authSnap) {
                if (authSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }

                final user = authSnap.data;

                // 1. If no user is logged in, show Login Screen
                if (user == null) {
                  return const LoginScreen();
                }

                // 2. User IS logged in. Ensure their profile is loaded (fixes hot restart bug).
                return FutureBuilder<UserProfile?>(
                  future: AuthService.instance.ensureProfileLoaded(),
                  builder: (context, profileSnap) {
                    if (profileSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading user profile...',
                                  style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                      );
                    }

                    // 3. If profile failed to load, sign them out to force a clean login
                    if (profileSnap.hasError || profileSnap.data == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        AuthService.instance.signOut();
                      });
                      return const Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.orange, size: 48),
                              SizedBox(height: 16),
                              Text('Profile not found. Please log in again.',
                                  style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                      );
                    }

                    // 4. Profile is loaded successfully! Show the Dashboard.
                    return const DashboardScreen();
                  },
                );
              },
            ),
    );
  }
}
