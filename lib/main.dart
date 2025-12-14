import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/firebase/firebase_service.dart';
import 'features/auth/auth_provider.dart' as auth;
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/messaging/fcm_service.dart' show FCMService, firebaseMessagingBackgroundHandler;
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await FirebaseService.initialize();
    
    // Initialize FCM (non-blocking)
    FCMService.initialize().catchError((error) {
      debugPrint('FCM initialization error: $error');
    });
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Log app start in Analytics (non-blocking)
    AnalyticsService.logEvent(name: 'app_start').catchError((error) {
      debugPrint('Analytics error: $error');
    });
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue even if Firebase fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => auth.AuthProvider(),
      child: MaterialApp(
        title: 'Projet Flutter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Firebase is already initialized in main(), so we can show UI immediately
    // Use microtask to avoid blocking the UI thread
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            )
          : Consumer<auth.AuthProvider>(
              builder: (context, authProvider, _) {
                // Debug logs
                debugPrint('🔍 [AuthWrapper] isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}, user: ${authProvider.user?.email ?? "null"}');

                // Show loading screen while checking auth state
                if (authProvider.isLoading && authProvider.user == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Navigate based on authentication state
                // Vérifier directement depuis Firebase Auth aussi (pour Android, parfois le stream prend du temps)
                final providerUser = authProvider.user;
                final firebaseAuth = FirebaseAuth.instance;
                final directFirebaseUser = firebaseAuth.currentUser;
                
                debugPrint('🔍 [AuthWrapper] Provider user: ${providerUser?.email ?? "null"}');
                debugPrint('🔍 [AuthWrapper] Direct Firebase user: ${directFirebaseUser?.email ?? "null"}');
                
                // Utiliser l'utilisateur du provider OU directement depuis Firebase Auth
                final user = providerUser ?? directFirebaseUser;
                
                if (user != null || authProvider.isAuthenticated) {
                  debugPrint('✅ [AuthWrapper] Navigation vers HomeScreen - User: ${user?.email ?? "via isAuthenticated"}');
                  // Log screen view (non-blocking)
                  AnalyticsService.logScreenView(screenName: 'home_screen')
                      .catchError((error) => debugPrint('Analytics error: $error'));
                  return const HomeScreen();
                } else {
                  debugPrint('❌ [AuthWrapper] Navigation vers LoginScreen - Aucun utilisateur trouvé');
                  // Log screen view (non-blocking)
                  AnalyticsService.logScreenView(screenName: 'login_screen')
                      .catchError((error) => debugPrint('Analytics error: $error'));
                  return const LoginScreen();
                }
              },
            ),
    );
  }
}
