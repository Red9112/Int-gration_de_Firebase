# Configuration de la gestion de présence utilisateur

## Vue d'ensemble

Le système de présence utilisateur permet de suivre automatiquement le statut online/offline des utilisateurs en temps réel via Firebase Realtime Database. Il fonctionne automatiquement après chaque authentification réussie.

## Fonctionnement

### Lors de la connexion
- L'utilisateur est automatiquement marqué comme `online: true`
- Le `lastSeen` est mis à jour avec un timestamp serveur
- L'information `email` est enregistrée
- Un `onDisconnect()` est configuré pour mettre automatiquement `online: false` en cas de déconnexion

### Lors de la déconnexion automatique
Le système `onDisconnect()` de Firebase se déclenche automatiquement dans les cas suivants :
- Fermeture de l'application
- Perte de connexion réseau
- Crash de l'application
- Déconnexion manuelle

Dans tous ces cas, l'utilisateur est automatiquement marqué comme `online: false` et le `lastSeen` est mis à jour.

## Structure de données

Les données sont stockées dans Firebase Realtime Database sous le chemin `presence/{userId}` avec deux sections :
- `current` : État actuel de la présence
- `history` : Historique de toutes les connexions/déconnexions

```json
{
  "presence": {
    "uid_123": {
      "current": {
        "online": true,
        "lastSeen": 1766331453100,
        "lastSeenFormatted": "2024-12-21 15:30:45",
        "email": "john.doe@gmail.com"
      },
      "history": {
        "-Nabc123": {
          "online": true,
          "timestamp": 1766331453100,
          "timestampFormatted": "2024-12-21 15:30:45",
          "email": "john.doe@gmail.com"
        },
        "-Nabc456": {
          "online": false,
          "timestamp": 1766331500000,
          "timestampFormatted": "2024-12-21 15:31:40",
          "email": "john.doe@gmail.com"
        }
      }
    }
  }
}
```

**Notes importantes** :
- Chaque connexion/déconnexion crée une nouvelle entrée dans `history` (ne remplace pas les précédentes)
- Le champ `lastSeenFormatted` et `timestampFormatted` affichent la date au format `AAAA-MM-JJ HH:mm:ss` dans Firebase Console
- Pour les déconnexions automatiques (`onDisconnect`), `timestampFormatted` peut ne pas être présent immédiatement (sera calculé côté client lors de la lecture)

## Configuration Firebase Console

### Étape 1 : Activer Realtime Database

Si Realtime Database n'est pas encore activé :

1. Allez dans [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Dans le menu de gauche, cliquez sur **Realtime Database**
4. Cliquez sur **Créer une base de données**
5. Choisissez l'emplacement (recommandé : même région que Firestore)
6. Choisissez le mode de sécurité :
   - **Mode test** : Pour développement (30 jours)
   - **Mode verrouillé** : Pour production

### Étape 1.5 : Récupérer l'URL de la base de données

**IMPORTANT** : Après avoir créé la base de données, vous devez récupérer son URL :

1. Dans Firebase Console > Realtime Database
2. L'URL est affichée en haut de la page, par exemple :
   - `https://flutterproject-72994-default-rtdb.firebaseio.com` (ancien format)
   - `https://flutterproject-72994-default-rtdb.{region}.firebasedatabase.app` (nouveau format)
3. **Copiez cette URL** et mettez-la à jour dans `lib/services/presence_service.dart` :
   ```dart
   const databaseURL = 'VOTRE_URL_ICI';
   ```

### Étape 2 : Configurer les règles de sécurité

Dans Firebase Console > Realtime Database > **Règles**, configurez les règles suivantes :

#### Règles recommandées (production) :

```json
{
  "rules": {
    "presence": {
      "$uid": {
        ".read": "auth != null",
        ".write": "$uid === auth.uid"
      }
    },
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

#### Explication des règles :

- **`.read": "auth != null"`** : Tous les utilisateurs authentifiés peuvent lire la présence de tous les utilisateurs
- **`.write": "$uid === auth.uid"`** : Seul l'utilisateur peut modifier sa propre présence

#### Règles pour développement (mode test) :

Si vous êtes en mode test, les règles par défaut permettent tout :

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

⚠️ **Attention** : Le mode test expire après 30 jours. Configurez les règles de sécurité avant l'expiration.

## Utilisation dans le code

### Le service est automatiquement intégré

Le `PresenceService` est automatiquement appelé lors de :
- Connexion par email/mot de passe
- Connexion avec Google Sign-In
- Déconnexion manuelle
- Changement d'état d'authentification

**Aucune action manuelle n'est nécessaire** - tout est géré automatiquement par `AuthProvider`.

### Écouter les changements de présence

Si vous souhaitez écouter les changements de présence dans votre application :

```dart
import 'package:projet_flutter/services/presence_service.dart';

// Écouter la présence d'un utilisateur spécifique
PresenceService.listenToUserPresence('uid_123').listen((event) {
  final data = event.snapshot.value as Map<dynamic, dynamic>;
  final isOnline = data['online'] as bool;
  final lastSeen = data['lastSeen'];
  final formattedDate = PresenceService.formatLastSeen(lastSeen);
  print('Utilisateur ${isOnline ? "en ligne" : "hors ligne"}');
  print('Dernière connexion: $formattedDate'); // Format: AAAA-MM-JJ HH:mm:ss
});

// Écouter tous les utilisateurs online
PresenceService.listenToAllPresence().listen((event) {
  final allPresence = event.snapshot.value as Map<dynamic, dynamic>;
  // Traiter tous les utilisateurs
});

// Écouter uniquement les utilisateurs qui deviennent online
PresenceService.listenToUsersComingOnline().listen((event) {
  final userId = event.snapshot.key;
  print('Utilisateur $userId vient de se connecter');
});

// Écouter uniquement les utilisateurs qui deviennent offline
PresenceService.listenToUsersGoingOffline().listen((event) {
  final userId = event.snapshot.key;
  print('Utilisateur $userId vient de se déconnecter');
});
```

### Récupérer la présence d'un utilisateur

```dart
final snapshot = await PresenceService.getUserPresence('uid_123');
if (snapshot != null && snapshot.exists) {
  final data = snapshot.value as Map<dynamic, dynamic>;
  final isOnline = data['online'] as bool;
  final lastSeen = data['lastSeen'];
  final email = data['email'] as String;
  
  // Formater le timestamp en date lisible
  final formattedDate = PresenceService.formatLastSeen(lastSeen);
  // Format: AAAA-MM-JJ HH:mm:ss (ex: 2024-12-21 15:30:45)
  print('Email: $email');
  print('Statut: ${isOnline ? "En ligne" : "Hors ligne"}');
  print('Dernière connexion: $formattedDate');
}
```

## Fonctionnalités

### ✅ Gestion automatique

- ✅ Marque automatiquement les utilisateurs comme online lors de la connexion
- ✅ Marque automatiquement les utilisateurs comme offline lors de la déconnexion
- ✅ Met à jour automatiquement `lastSeen` avec un timestamp serveur
- ✅ Fonctionne avec `onDisconnect()` pour gérer les déconnexions non intentionnelles
- ✅ Compatible Android et Web

### ✅ Scénarios gérés

- ✅ Connexion par email/mot de passe
- ✅ Connexion avec Google Sign-In
- ✅ Déconnexion manuelle
- ✅ Fermeture de l'application
- ✅ Perte de connexion réseau
- ✅ Crash de l'application
- ✅ Changement d'utilisateur (déconnexion puis nouvelle connexion)

## Dépannage

### La présence n'est pas mise à jour

1. **Vérifiez que Realtime Database est activé** dans Firebase Console
2. **Vérifiez les règles de sécurité** - assurez-vous que l'utilisateur peut écrire dans `presence/{uid}`
3. **Vérifiez les logs** - cherchez les messages `[PresenceService]` dans la console
4. **Vérifiez que l'utilisateur est authentifié** - la présence nécessite une authentification

### Les utilisateurs restent online après déconnexion

- C'est normal si la déconnexion est très récente - `onDisconnect()` peut prendre quelques secondes
- Vérifiez que `onDisconnect()` est bien configuré dans les logs
- Vérifiez la connexion réseau - `onDisconnect()` nécessite une connexion active au moment de la configuration

### Erreur de permissions

- Vérifiez les règles de sécurité dans Firebase Console
- Assurez-vous que l'utilisateur est authentifié (`auth != null`)
- Assurez-vous que `$uid === auth.uid` dans les règles de sécurité

## Tests

### Test manuel

1. **Connexion** :
   - Connectez-vous avec email ou Google
   - Vérifiez dans Firebase Console > Realtime Database que `presence/{uid}` existe avec `online: true`

2. **Déconnexion** :
   - Déconnectez-vous manuellement
   - Vérifiez que `online` passe à `false` et `lastSeen` est mis à jour

3. **Fermeture de l'app** :
   - Connectez-vous
   - Fermez complètement l'application
   - Attendez quelques secondes
   - Vérifiez dans Firebase Console que `online` passe à `false`

4. **Perte de réseau** :
   - Connectez-vous
   - Désactivez le WiFi/Données
   - Attendez quelques secondes
   - Vérifiez dans Firebase Console que `online` passe à `false`

## Notes importantes

- Le système utilise `ServerValue.timestamp` pour garantir la cohérence des timestamps
- `onDisconnect()` nécessite une connexion active au moment de la configuration
- Les données de présence sont automatiquement nettoyées lors du changement d'utilisateur
- Le service gère automatiquement les erreurs et les enregistre dans Crashlytics

## Compatibilité

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Toutes les méthodes d'authentification (Email/Password, Google Sign-In)

