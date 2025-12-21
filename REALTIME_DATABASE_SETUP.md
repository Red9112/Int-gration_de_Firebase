# Configuration Firebase Realtime Database

## Vue d'ensemble

Firebase Realtime Database est maintenant intégré au projet. Il coexiste avec Firestore et peut être utilisé selon les besoins spécifiques de votre application.

## Différences entre Firestore et Realtime Database

### Quand utiliser Realtime Database :
- Synchronisation en temps réel avec faible latence
- Données simples (JSON)
- Applications collaboratives (chat, jeux multi-joueurs)
- Synchronisation hors ligne simple
- Structure de données plate ou arborescente simple

### Quand utiliser Firestore :
- Requêtes complexes
- Données structurées avec relations
- Scalabilité à grande échelle
- Transactions complexes
- Indexation avancée

## Configuration dans Firebase Console

### Étape 1 : Activer Realtime Database

1. Allez dans [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Dans le menu de gauche, cliquez sur **Realtime Database**
4. Cliquez sur **Créer une base de données**
5. Choisissez l'emplacement (recommandé : même région que Firestore)
6. Choisissez le mode de sécurité :
   - **Mode test** : Accès libre pendant 30 jours (pour développement)
   - **Mode verrouillé** : Règles de sécurité strictes (pour production)

### Étape 2 : Configurer les règles de sécurité

Dans Firebase Console > Realtime Database > Règles :

#### Règles par défaut (mode test - 30 jours) :
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

#### Règles recommandées (production) :
```json
{
  "rules": {
    "users": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid"
      }
    },
    "public": {
      ".read": true,
      ".write": "auth != null"
    }
  }
}
```

### Étape 3 : Activer la persistance hors ligne (optionnel)

La persistance hors ligne est activée par défaut dans le package Flutter. Les données sont automatiquement mises en cache localement.

## Utilisation du service

### Import

```dart
import 'package:projet_flutter/features/database/realtime_database_service.dart';
```

### Initialisation

```dart
final realtimeDb = RealtimeDatabaseService();
```

## Exemples d'utilisation

### 1. Écrire des données

#### Écrire une valeur simple
```dart
await realtimeDb.setValue(
  path: 'users/user123',
  value: {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
);
```

#### Ajouter à une liste (push)
```dart
final ref = await realtimeDb.push(
  path: 'messages',
  value: {
    'text': 'Hello!',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  },
);
print('Message ID: ${ref.key}');
```

#### Mettre à jour plusieurs valeurs atomiquement
```dart
await realtimeDb.update(updates: {
  'users/user123/name': 'Jane Doe',
  'users/user123/email': 'jane@example.com',
  'users/user123/updatedAt': DateTime.now().millisecondsSinceEpoch,
});
```

### 2. Lire des données

#### Lire une valeur une fois
```dart
final snapshot = await realtimeDb.getValue(path: 'users/user123');
if (snapshot.exists) {
  final data = snapshot.value as Map<dynamic, dynamic>;
  print('User name: ${data['name']}');
}
```

#### Lire avec une requête
```dart
final query = realtimeDb
    .orderByChild('timestamp')
    .limitToLast(10);
final snapshot = await query.get();
```

### 3. Écouter les changements en temps réel

#### Écouter les changements de valeur
```dart
realtimeDb.onValue(path: 'users/user123').listen((event) {
  final data = event.snapshot.value;
  print('User data changed: $data');
});
```

#### Écouter l'ajout d'enfants (pour les listes)
```dart
realtimeDb.onChildAdded(path: 'messages').listen((event) {
  final message = event.snapshot.value as Map<dynamic, dynamic>;
  print('New message: ${message['text']}');
});
```

#### Écouter les modifications d'enfants
```dart
realtimeDb.onChildChanged(path: 'messages').listen((event) {
  final message = event.snapshot.value as Map<dynamic, dynamic>;
  print('Message updated: ${message['text']}');
});
```

#### Écouter la suppression d'enfants
```dart
realtimeDb.onChildRemoved(path: 'messages').listen((event) {
  print('Message deleted: ${event.snapshot.key}');
});
```

### 4. Gestion des données utilisateur

#### Créer/mettre à jour les données utilisateur
```dart
await realtimeDb.setUserData(
  userId: 'user123',
  data: {
    'name': 'John Doe',
    'email': 'john@example.com',
    'createdAt': DateTime.now().millisecondsSinceEpoch,
  },
);
```

#### Récupérer les données utilisateur
```dart
final snapshot = await realtimeDb.getUserData(userId: 'user123');
if (snapshot.exists) {
  final userData = snapshot.value as Map<dynamic, dynamic>;
  print('User: ${userData['name']}');
}
```

#### Écouter les changements de données utilisateur en temps réel
```dart
realtimeDb.listenToUserData(userId: 'user123').listen((event) {
  final userData = event.snapshot.value as Map<dynamic, dynamic>;
  print('User data updated: ${userData['name']}');
});
```

### 5. Transactions

```dart
final result = await realtimeDb.runTransaction(
  path: 'counter',
  handler: (current) {
    final currentValue = (current.value as int?) ?? 0;
    return Transaction.success(currentValue + 1);
  },
);
```

### 6. Requêtes avancées

#### Trier et limiter
```dart
final query = realtimeDb
    .orderByChild('timestamp')
    .limitToLast(10);
final snapshot = await query.get();
```

#### Filtrer par valeur
```dart
final query = realtimeDb
    .orderByChild('status')
    .equalTo('active');
final snapshot = await query.get();
```

#### Plage de valeurs
```dart
final query = realtimeDb
    .orderByChild('age')
    .startAt(18)
    .endAt(65);
final snapshot = await query.get();
```

### 7. Contrôle de la connexion

#### Activer la synchronisation hors ligne
```dart
await realtimeDb.keepSynced(path: 'importantData', synced: true);
```

#### Désactiver la synchronisation hors ligne
```dart
await realtimeDb.keepSynced(path: 'importantData', synced: false);
```

#### Déconnecter manuellement (rarement nécessaire)
```dart
await realtimeDb.goOffline();
```

#### Reconnecter manuellement
```dart
await realtimeDb.goOnline();
```

## Structure de données recommandée

### Structure plate (recommandée)
```
users/
  user123/
    name: "John Doe"
    email: "john@example.com"
messages/
  message1/
    text: "Hello"
    timestamp: 1234567890
```

### Structure arborescente (à éviter si possible)
```
users/
  user123/
    profile/
      name: "John Doe"
      email: "john@example.com"
```

## Bonnes pratiques

1. **Utiliser des chemins plats** : Évitez les structures trop profondes
2. **Indexer les données** : Utilisez `orderByChild()` pour les requêtes fréquentes
3. **Limiter les données** : Utilisez `limitToFirst()` ou `limitToLast()`
4. **Gérer les listeners** : Annulez les abonnements quand vous n'en avez plus besoin
5. **Utiliser les transactions** : Pour les opérations critiques (compteurs, votes)
6. **Sécuriser les données** : Configurez les règles de sécurité appropriées

## Gestion des erreurs

Toutes les méthodes du service gèrent automatiquement les erreurs et les enregistrent dans Crashlytics :

```dart
try {
  await realtimeDb.setValue(path: 'data', value: {'key': 'value'});
} catch (e) {
  // L'erreur est déjà enregistrée dans Crashlytics
  print('Erreur: $e');
}
```

## Intégration avec l'authentification

Le service peut être utilisé avec Firebase Auth pour sécuriser les données :

```dart
// Les règles de sécurité dans Firebase Console vérifient auth.uid
// Exemple de règle :
// "users": {
//   "$userId": {
//     ".read": "$userId === auth.uid",
//     ".write": "$userId === auth.uid"
//   }
// }
```

## Comparaison avec Firestore

| Fonctionnalité | Realtime Database | Firestore |
|----------------|-------------------|-----------|
| Structure | JSON arborescent | Documents/Collections |
| Requêtes | Limitées | Avancées |
| Latence | Très faible | Faible |
| Scalabilité | Moyenne | Très élevée |
| Transactions | Oui | Oui |
| Indexation | Automatique | Configurable |
| Coût | Par GB transféré | Par opération |

## Dépannage

### Les données ne se synchronisent pas
- Vérifiez les règles de sécurité dans Firebase Console
- Vérifiez que l'utilisateur est authentifié si nécessaire
- Vérifiez la connexion Internet

### Erreur de permissions
- Vérifiez les règles de sécurité
- Assurez-vous que l'utilisateur est authentifié
- Vérifiez que le chemin correspond aux règles

### Les listeners ne se déclenchent pas
- Vérifiez que le listener est bien actif (pas annulé)
- Vérifiez que les données existent au chemin spécifié
- Vérifiez les règles de sécurité pour `.read`

## Ressources

- [Documentation officielle Firebase Realtime Database](https://firebase.google.com/docs/database)
- [Règles de sécurité](https://firebase.google.com/docs/database/security)
- [Guide de structure des données](https://firebase.google.com/docs/database/web/structure-data)

