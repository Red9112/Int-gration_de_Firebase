import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'crashlytics_service.dart';

/// Service de gestion de présence utilisateur en temps réel
/// Utilise Firebase Realtime Database pour suivre le statut online/offline
class PresenceService {
  // URL de la base de données Realtime Database
  // IMPORTANT: Remplacez cette URL par l'URL réelle de votre base de données
  // Pour trouver l'URL:
  // 1. Allez dans Firebase Console > Realtime Database
  // 2. L'URL est affichée en haut de la page (ex: https://flutterproject-72994-default-rtdb.firebaseio.com)
  // Formats possibles:
  // - Ancien: https://{projectId}-default-rtdb.firebaseio.com
  // - Nouveau: https://{projectId}-default-rtdb.{region}.firebasedatabase.app
  static FirebaseDatabase get _databaseInstance {
    try {
      // URL de votre base de données Realtime Database
      // Remplacez par l'URL exacte depuis Firebase Console
      const databaseURL = 'https://flutterproject-72994-default-rtdb.firebaseio.com';
      
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseURL,
      );
    } catch (e) {
      // Fallback vers l'instance par défaut si l'URL spécifique échoue
      if (kDebugMode) {
        debugPrint('⚠️ [PresenceService] Erreur avec URL spécifique, utilisation de l\'instance par défaut: $e');
        debugPrint('⚠️ [PresenceService] Vérifiez que l\'URL de la base de données est correcte dans Firebase Console');
      }
      return FirebaseDatabase.instance;
    }
  }
  
  static DatabaseReference get _database => _databaseInstance.ref();
  static DatabaseReference? _currentPresenceRef;
  static OnDisconnect? _onDisconnect;

  /// Initialiser la présence pour un utilisateur
  /// Appelé automatiquement après authentification réussie
  static Future<void> initializePresence(User user) async {
    try {
      if (kDebugMode) {
        debugPrint('🟢 [PresenceService] Initialisation de la présence pour: ${user.uid}');
      }

      // Nettoyer toute présence précédente si elle existe
      await cleanupPresence();

      // Définir la référence de présence pour cet utilisateur
      _currentPresenceRef = _database.child('presence').child(user.uid);

      // Configurer onDisconnect pour mettre automatiquement offline
      // Cela se déclenche automatiquement en cas de :
      // - Déconnexion réseau
      // - Fermeture de l'application
      // - Crash de l'application
      _onDisconnect = _currentPresenceRef!.onDisconnect();
      
      // Générer une clé pour l'historique avant la déconnexion
      final historyKey = _currentPresenceRef!.child('history').push().key;
      
      // Récupérer l'email depuis les données actuelles pour l'historique
      final currentSnapshot = await _currentPresenceRef!.child('current').get();
      String email = '';
      if (currentSnapshot.exists) {
        final currentData = currentSnapshot.value as Map<dynamic, dynamic>?;
        email = currentData?['email']?.toString() ?? user.email ?? '';
      } else {
        email = user.email ?? '';
      }
      
      // Pour onDisconnect, on ne peut pas utiliser de valeurs calculées côté client
      // On stocke seulement le timestamp dans current et history
      // La date formatée sera calculée côté client lors de la lecture ou via Cloud Function
      await _onDisconnect!.update({
        'current/online': false,
        'current/lastSeen': ServerValue.timestamp,
        // Ajouter une entrée dans l'historique
        'history/$historyKey/online': false,
        'history/$historyKey/timestamp': ServerValue.timestamp,
        'history/$historyKey/email': email,
        // Note: timestampFormatted sera calculé côté client lors de la lecture
        // ou peut être ajouté via une Cloud Function qui écoute les changements
      });

      if (kDebugMode) {
        debugPrint('✅ [PresenceService] onDisconnect configuré pour: ${user.uid}');
      }

      // Marquer l'utilisateur comme online
      await setUserOnline(user);
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      if (kDebugMode) {
        debugPrint('❌ [PresenceService] Erreur lors de l\'initialisation: $e');
      }
      rethrow;
    }
  }

  /// Marquer l'utilisateur comme online
  /// Met à jour online: true et lastSeen avec timestamp serveur
  /// Ajoute une entrée dans l'historique
  static Future<void> setUserOnline(User user) async {
    try {
      _currentPresenceRef ??= _database.child('presence').child(user.uid);

      // Obtenir le timestamp actuel (approximatif côté client)
      final now = DateTime.now();
      final timestampMs = now.millisecondsSinceEpoch;
      final formattedDate = _formatTimestamp(timestampMs);

      // Données actuelles
      final currentData = {
        'online': true,
        'lastSeen': ServerValue.timestamp,
        'lastSeenFormatted': formattedDate,
        'email': user.email ?? '',
      };

      // Mettre à jour les données actuelles
      await _currentPresenceRef!.child('current').set(currentData);

      // Ajouter une entrée dans l'historique
      final historyRef = _currentPresenceRef!.child('history').push();
      await historyRef.set({
        'online': true,
        'timestamp': ServerValue.timestamp,
        'timestampFormatted': formattedDate,
        'email': user.email ?? '',
      });

      if (kDebugMode) {
        debugPrint('✅ [PresenceService] Utilisateur marqué comme online: ${user.uid}');
        debugPrint('   Email: ${user.email}');
        debugPrint('   Date: $formattedDate');
      }

      await CrashlyticsService.log('User presence set to online: ${user.uid}');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      if (kDebugMode) {
        debugPrint('❌ [PresenceService] Erreur lors de la mise en ligne: $e');
      }
      rethrow;
    }
  }

  /// Marquer l'utilisateur comme offline (déconnexion manuelle)
  /// Met à jour online: false et lastSeen avec timestamp serveur
  /// Ajoute une entrée dans l'historique
  static Future<void> setUserOffline(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔴 [PresenceService] Marquer utilisateur comme offline: $userId');
      }

      // Annuler onDisconnect car on gère manuellement
      await cleanupPresence();

      // Obtenir le timestamp formaté
      final now = DateTime.now();
      final timestampMs = now.millisecondsSinceEpoch;
      final formattedDate = _formatTimestamp(timestampMs);

      // Récupérer l'email depuis les données actuelles
      final currentSnapshot = await _database.child('presence').child(userId).child('current').get();
      String email = '';
      if (currentSnapshot.exists) {
        final currentData = currentSnapshot.value as Map<dynamic, dynamic>?;
        email = currentData?['email']?.toString() ?? '';
      }

      // Mettre à jour les données actuelles
      final presenceRef = _database.child('presence').child(userId);
      await presenceRef.child('current').update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'lastSeenFormatted': formattedDate,
      });

      // Ajouter une entrée dans l'historique
      final historyRef = presenceRef.child('history').push();
      await historyRef.set({
        'online': false,
        'timestamp': ServerValue.timestamp,
        'timestampFormatted': formattedDate,
        'email': email,
      });

      if (kDebugMode) {
        debugPrint('✅ [PresenceService] Utilisateur marqué comme offline: $userId');
        debugPrint('   Date: $formattedDate');
      }

      await CrashlyticsService.log('User presence set to offline: $userId');
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      if (kDebugMode) {
        debugPrint('❌ [PresenceService] Erreur lors de la mise hors ligne: $e');
      }
      rethrow;
    }
  }

  /// Nettoyer les listeners et onDisconnect
  /// Appelé lors de la déconnexion manuelle ou du changement d'utilisateur
  static Future<void> cleanupPresence() async {
    try {
      if (_onDisconnect != null) {
        await _onDisconnect!.cancel();
        _onDisconnect = null;
        if (kDebugMode) {
          debugPrint('🧹 [PresenceService] onDisconnect annulé');
        }
      }
      _currentPresenceRef = null;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      if (kDebugMode) {
        debugPrint('❌ [PresenceService] Erreur lors du nettoyage: $e');
      }
    }
  }

  /// Récupérer la présence actuelle d'un utilisateur
  static Future<DataSnapshot?> getUserPresence(String userId) async {
    try {
      final snapshot = await _database.child('presence').child(userId).child('current').get();
      if (snapshot.exists) {
        return snapshot;
      }
      return null;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      return null;
    }
  }

  /// Récupérer l'historique de présence d'un utilisateur
  static Future<DataSnapshot?> getUserPresenceHistory(String userId) async {
    try {
      final snapshot = await _database.child('presence').child(userId).child('history').get();
      if (snapshot.exists) {
        return snapshot;
      }
      return null;
    } catch (e, stackTrace) {
      await CrashlyticsService.recordError(e, stackTrace);
      return null;
    }
  }

  /// Écouter les changements de présence d'un utilisateur en temps réel
  /// Retourne un stream qui émet DatabaseEvent à chaque changement
  static Stream<DatabaseEvent> listenToUserPresence(String userId) {
    try {
      return _database.child('presence').child(userId).child('current').onValue;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Écouter l'historique de présence d'un utilisateur en temps réel
  static Stream<DatabaseEvent> listenToUserPresenceHistory(String userId) {
    try {
      return _database.child('presence').child(userId).child('history').onValue;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Écouter tous les utilisateurs online en temps réel
  /// Retourne un stream qui émet DatabaseEvent à chaque changement
  static Stream<DatabaseEvent> listenToAllPresence() {
    try {
      return _database.child('presence').onValue;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Écouter uniquement les utilisateurs qui deviennent online
  static Stream<DatabaseEvent> listenToUsersComingOnline() {
    try {
      return _database.child('presence').onChildAdded;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Écouter uniquement les utilisateurs qui deviennent offline
  static Stream<DatabaseEvent> listenToUsersGoingOffline() {
    try {
      return _database.child('presence').onChildChanged;
    } catch (e, stackTrace) {
      CrashlyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }

  /// Formater un timestamp en date lisible (AAAA-MM-JJ HH:mm:ss)
  /// Le timestamp est en millisecondes depuis l'époque Unix
  static String formatLastSeen(dynamic timestamp) {
    try {
      if (timestamp == null) return 'N/A';
      
      // Convertir en int si c'est un double ou autre type numérique
      int timestampMs;
      if (timestamp is int) {
        timestampMs = timestamp;
      } else if (timestamp is double) {
        timestampMs = timestamp.toInt();
      } else {
        timestampMs = int.tryParse(timestamp.toString()) ?? 0;
      }

      if (timestampMs == 0) return 'N/A';

      return _formatTimestamp(timestampMs);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PresenceService] Erreur formatage date: $e');
      }
      return 'N/A';
    }
  }

  /// Formater un timestamp en date lisible (AAAA-MM-JJ HH:mm:ss)
  /// Méthode interne pour formater les timestamps
  static String _formatTimestamp(int timestampMs) {
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      
      // Format: AAAA-MM-JJ HH:mm:ss
      final year = dateTime.year.toString().padLeft(4, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      
      return '$year-$month-$day $hour:$minute:$second';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [PresenceService] Erreur formatage timestamp: $e');
      }
      return 'N/A';
    }
  }
}

