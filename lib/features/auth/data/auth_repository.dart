import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../services/crashlytics_service.dart';
import '../../database/firestore_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Enregistrer l'historique de connexion dans Firestore
      if (credential.user != null) {
        try {
          await _firestoreService.updateUserDocument(
            userId: credential.user!.uid,
            data: {
              'lastSignInAt': FieldValue.serverTimestamp(),
              'lastSignInMethod': 'email',
            },
          );
          debugPrint('✅ [AuthRepository] Historique de connexion enregistré (email)');
        } catch (firestoreError) {
          debugPrint('⚠️ [AuthRepository] Erreur enregistrement historique: $firestoreError');
        }
      }
      
      await CrashlyticsService.setUserIdentifier(credential.user?.uid ?? '');
      return credential;
    } catch (e, stackTrace) {
      // Don't log to Crashlytics if it's a configuration error
      if (e.toString().contains('configuration-not-found')) {
        // This means Firebase Auth is not enabled in Firebase Console
        rethrow;
      }
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Register with email and password
  /// Creates Firebase Auth user AND Firestore document
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Échec de la création de l\'utilisateur');
      }

      // 2. Create Firestore document for the user
      try {
        await _firestoreService.createUserDocument(
          userId: user.uid,
          email: email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          phoneNumber: user.phoneNumber,
          additionalData: {
            'signInMethod': 'email',
            'lastSignInAt': FieldValue.serverTimestamp(),
            'lastSignInMethod': 'email',
          },
        );
        debugPrint('✅ [AuthRepository] Document Firestore créé pour l\'utilisateur: ${user.uid}');
      } catch (firestoreError) {
        // Log the error but don't fail the registration
        // The user is already created in Firebase Auth
        debugPrint('⚠️ [AuthRepository] Erreur lors de la création du document Firestore: $firestoreError');
        await CrashlyticsService.recordError(
          firestoreError,
          StackTrace.current,
          reason: 'Failed to create Firestore user document after registration',
        );
        // Continue anyway - user is authenticated even if Firestore doc creation fails
      }

      await CrashlyticsService.setUserIdentifier(user.uid);
      return credential;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Sign in with Google
  /// Cette méthode fait le lien entre Google Sign-In et Firebase Auth
  /// Sur le web, gère le cas où idToken peut être null
  /// Sur mobile, utilise Google Sign-In puis Firebase credential
  Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint('🔵 [Google Sign-In] Début du processus...');
      
      // 1️⃣ Lancer Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('🔵 [Google Sign-In] Google Sign-In terminé: ${googleUser != null}');

      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      // 2️⃣ Récupérer les tokens Google
      // Sur le web, cela peut échouer si People API n'est pas activée
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (authError) {
        // Si l'erreur est liée à People API, donner un message clair
        if (authError.toString().contains('People API') || 
            authError.toString().contains('people.googleapis.com') ||
            authError.toString().contains('SERVICE_DISABLED') ||
            authError.toString().contains('403')) {
          throw Exception(
            'People API n\'est pas activée dans Google Cloud Console. '
            'Veuillez l\'activer ici: '
            'https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=276653859682\n\n'
            'Note: La People API est requise pour Google Sign-In sur le web.'
          );
        }
        rethrow;
      }
      
      debugPrint('🔵 [Google Sign-In] Tokens obtenus - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');

      // Sur le web, idToken peut être null, mais accessToken devrait être présent
      if (googleAuth.accessToken == null) {
        throw Exception('Impossible d\'obtenir le token d\'accès Google');
      }

      // 3️⃣ Créer le credential Firebase
      // Sur le web, idToken peut être null, Firebase peut fonctionner avec seulement accessToken
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken, // Peut être null sur web, c'est OK
      );

      debugPrint('🔵 [Google Sign-In] Credential créé, connexion à Firebase...');

      // 4️⃣ CONNECTER À FIREBASE (ÉTAPE CRITIQUE)
      // C'est CETTE LIGNE qui connecte Google à Firebase Auth
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('🔵 [Google Sign-In] signInWithCredential terminé - user: ${userCredential.user != null}');

      // Vérifier que l'utilisateur est bien authentifié
      if (userCredential.user == null) {
        throw Exception('Échec de l\'authentification Firebase');
      }

      // Vérifier que Firebase Auth a bien enregistré l'utilisateur
      final currentUser = _auth.currentUser;
      debugPrint('🔵 [Google Sign-In] Firebase Auth currentUser: ${currentUser != null}');
      
      if (currentUser == null) {
        throw Exception('Firebase Auth n\'a pas enregistré l\'utilisateur après signInWithCredential');
      }

      debugPrint('✅ [Google Sign-In] SUCCÈS - User ID: ${currentUser.uid}, Email: ${currentUser.email}');

      // Check if this is a new user (first time signing in with Google)
      // If user document doesn't exist in Firestore, create it
      final userExists = await _firestoreService.userDocumentExists(currentUser.uid);
      if (!userExists) {
        try {
          await _firestoreService.createUserDocument(
            userId: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName,
            photoUrl: currentUser.photoURL,
            phoneNumber: currentUser.phoneNumber,
            additionalData: {
              'signInMethod': 'google',
            },
          );
          debugPrint('✅ [AuthRepository] Document Firestore créé pour le nouvel utilisateur Google: ${currentUser.uid}');
        } catch (firestoreError) {
          // Log the error but don't fail the sign-in
          debugPrint('⚠️ [AuthRepository] Erreur lors de la création du document Firestore: $firestoreError');
          await CrashlyticsService.recordError(
            firestoreError,
            StackTrace.current,
            reason: 'Failed to create Firestore user document after Google sign-in',
          );
          // Continue anyway - user is authenticated even if Firestore doc creation fails
        }
      } else {
        // Update existing user document with latest info
        try {
          await _firestoreService.updateUserDocument(
            userId: currentUser.uid,
            data: {
              'displayName': currentUser.displayName,
              'photoUrl': currentUser.photoURL,
              'lastSignInAt': FieldValue.serverTimestamp(),
              'lastSignInMethod': 'google',
            },
          );
          debugPrint('✅ [AuthRepository] Document Firestore mis à jour pour l\'utilisateur: ${currentUser.uid}');
        } catch (firestoreError) {
          debugPrint('⚠️ [AuthRepository] Erreur lors de la mise à jour du document Firestore: $firestoreError');
        }
      }

      // Set user identifier for services
      await CrashlyticsService.setUserIdentifier(userCredential.user!.uid);
      
      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('❌ [Google Sign-In] ERREUR: $e');
      
      // Vérifier si c'est une erreur de People API (sur le web)
      if (e.toString().contains('People API') || 
          e.toString().contains('people.googleapis.com') ||
          e.toString().contains('SERVICE_DISABLED')) {
        throw Exception(
          'People API n\'est pas activée. Veuillez l\'activer dans Google Cloud Console: '
          'https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=276653859682'
        );
      }
      
      // Don't log to Crashlytics if it's a user cancellation
      if (!e.toString().contains('annulée') && 
          !e.toString().contains('canceled') &&
          !e.toString().contains('configuration-not-found')) {
        await CrashlyticsService.recordError(e, stackTrace);
      }
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}

