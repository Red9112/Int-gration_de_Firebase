import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'data/auth_repository.dart';
import '../../services/analytics_service.dart';
import '../../services/crashlytics_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Initialize with current user if already authenticated
    _user = _authRepository.currentUser;
    if (_user != null) {
      CrashlyticsService.setUserIdentifier(_user!.uid);
      AnalyticsService.setUserId(_user!.uid);
    }

    // Listen to auth state changes
    // Ce stream se déclenche automatiquement quand Firebase Auth change
    _authRepository.authStateChanges.listen((User? user) {
      debugPrint('🔄 [AuthProvider] authStateChanges: ${user != null ? "User connecté: ${user.email} (${user.uid})" : "User déconnecté"}');
      
      // Mettre à jour l'utilisateur seulement si c'est différent
      if (_user?.uid != user?.uid) {
        _user = user;
        
        if (user != null) {
          // Set user identifier for Crashlytics and Analytics
          CrashlyticsService.setUserIdentifier(user.uid);
          AnalyticsService.setUserId(user.uid);
        } else {
          // User déconnecté
          _user = null;
        }
        
        // Toujours notifier les listeners pour mettre à jour l'UI
        debugPrint('🔄 [AuthProvider] Notifiant les listeners après authStateChanges');
        notifyListeners();
      } else {
        debugPrint('🔄 [AuthProvider] authStateChanges: utilisateur identique, pas de mise à jour');
      }
    });
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await AnalyticsService.logLogin(loginMethod: 'email');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register with email and password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      await AnalyticsService.logSignUp(signUpMethod: 'email');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  /// Cette méthode appelle signInWithCredential qui connecte Google à Firebase
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔵 [AuthProvider] Début Google Sign-In...');

      // Appeler signInWithGoogle qui fait :
      // 1. Google Sign-In
      // 2. Créer credential Firebase
      // 3. FirebaseAuth.instance.signInWithCredential(credential) ← ÉTAPE CRITIQUE
      final userCredential = await _authRepository.signInWithGoogle();

      debugPrint('🔵 [AuthProvider] signInWithGoogle terminé, vérification de l\'utilisateur...');

      // Vérifier que l'authentification a réussi
      if (userCredential.user == null) {
        debugPrint('❌ [AuthProvider] userCredential.user est null');
        throw Exception('Échec de l\'authentification avec Google');
      }

      // CRITIQUE: Vérifier directement depuis Firebase Auth
      // Sur Android, le stream peut prendre du temps, on force la vérification
      User? currentUser = _authRepository.currentUser;
      
      // Si currentUser est null, attendre un peu et réessayer (sur Android, il peut y avoir un délai)
      if (currentUser == null) {
        debugPrint('⚠️ [AuthProvider] currentUser est null, attente de 200ms...');
        await Future.delayed(const Duration(milliseconds: 200));
        currentUser = _authRepository.currentUser;
      }

      if (currentUser == null) {
        debugPrint('❌ [AuthProvider] ERREUR: Firebase Auth user est toujours null après délai');
        throw Exception('Firebase Auth n\'a pas enregistré l\'utilisateur');
      }

      // Mettre à jour l'état immédiatement avec l'utilisateur de Firebase Auth
      _user = currentUser;
      
      debugPrint('✅ [AuthProvider] Google Sign-In réussi. User ID: ${_user?.uid}');
      debugPrint('✅ [AuthProvider] Email: ${_user?.email}');
      
      // Notifier immédiatement pour mettre à jour l'UI
      _isLoading = false;
      notifyListeners();
      
      // Attendre un peu pour que le stream se déclenche aussi (pour la cohérence)
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Vérifier à nouveau et notifier si nécessaire (au cas où le stream a changé l'état)
      final finalUser = _authRepository.currentUser;
      if (finalUser != null && _user?.uid != finalUser.uid) {
        _user = finalUser;
        notifyListeners();
      }
      
      await AnalyticsService.logLogin(loginMethod: 'google');
      
      return true;
    } catch (e) {
      debugPrint('❌ [AuthProvider] Erreur Google Sign-In: $e');
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      _user = null; // S'assurer que l'utilisateur est null en cas d'erreur
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authRepository.signOut();
      _user = null;

      await AnalyticsService.logEvent(name: 'logout');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé.';
        case 'invalid-email':
          return 'Email invalide.';
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'user-disabled':
          return 'Ce compte utilisateur a été désactivé.';
        case 'too-many-requests':
          return 'Trop de tentatives. Veuillez réessayer plus tard.';
        case 'operation-not-allowed':
          return 'Cette opération n\'est pas autorisée.';
        case 'configuration-not-found':
          return 'L\'authentification Firebase n\'est pas activée. Veuillez l\'activer dans Firebase Console.';
        default:
          return error.message ?? 'Une erreur est survenue.';
      }
    }
    // Check for configuration error in string
    if (error.toString().contains('configuration-not-found')) {
      return 'L\'authentification Firebase n\'est pas activée. Veuillez l\'activer dans Firebase Console.';
    }
    // Check for People API error
    if (error.toString().contains('People API') || 
        error.toString().contains('people.googleapis.com')) {
      return 'People API n\'est pas activée. Activez-la dans Google Cloud Console pour utiliser Google Sign-In.';
    }
    return error.toString();
  }
}

