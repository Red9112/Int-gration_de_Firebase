# Notifications Popup (Heads-up) sur Android

## ✅ Configuration terminée

Les notifications FCM s'affichent maintenant comme des **popups (heads-up notifications)** sur Android, que l'application soit en foreground, background ou terminée.

## 🔧 Modifications apportées

### 1. Canal de notification Android
- **Importance** : `Importance.max` (au lieu de `Importance.high`)
- **Priorité** : `Priority.max` (au lieu de `Priority.high`)
- Ces paramètres garantissent que les notifications s'affichent comme des popups

### 2. Service Android personnalisé
- Création de `MyFirebaseMessagingService.kt` pour gérer les notifications en background
- Configuration avec `PRIORITY_MAX` pour les popups
- Création automatique du canal avec `IMPORTANCE_HIGH`

### 3. Notifications en foreground
- Configuration avec `Importance.max` et `Priority.max`
- Style `BigTextStyleInformation` pour afficher le texte complet
- Vibration et son activés

## 📱 Comportement des notifications

### App en foreground (ouverte)
- Les notifications s'affichent comme des **popups en haut de l'écran**
- Le popup disparaît automatiquement après quelques secondes
- La notification reste dans la barre de notifications

### App en background (minimisée)
- Les notifications s'affichent comme des **popups en haut de l'écran**
- Le popup disparaît automatiquement après quelques secondes
- La notification reste dans la barre de notifications

### App terminée (fermée)
- Les notifications s'affichent comme des **popups en haut de l'écran**
- Le popup disparaît automatiquement après quelques secondes
- La notification reste dans la barre de notifications

## 🧪 Test des notifications popup

### 1. Prérequis
- L'application doit être installée sur l'émulateur ou l'appareil
- Les permissions de notification doivent être accordées
- Le token FCM doit être obtenu (visible dans les logs)

### 2. Test depuis Firebase Console

1. **Ouvrez Firebase Console** > **Cloud Messaging** > **Envoyer votre premier message**
2. **Remplissez les champs** :
   - **Titre de la notification** : "Test Popup"
   - **Texte de la notification** : "Ceci est un test de notification popup"
3. **Ciblez votre appareil** :
   - Sélectionnez "Cibler un appareil unique"
   - Collez le token FCM de votre appareil
4. **Envoyez la notification**

### 3. Test avec l'app en différents états

#### A. App en foreground
1. Ouvrez l'application
2. Envoyez une notification depuis Firebase Console
3. **Résultat attendu** : Un popup apparaît en haut de l'écran avec le titre et le texte

#### B. App en background
1. Ouvrez l'application
2. Appuyez sur le bouton **Home** pour minimiser l'app
3. Envoyez une notification depuis Firebase Console
4. **Résultat attendu** : Un popup apparaît en haut de l'écran avec le titre et le texte

#### C. App terminée
1. Fermez complètement l'application (swipe depuis les apps récentes)
2. Envoyez une notification depuis Firebase Console
3. **Résultat attendu** : Un popup apparaît en haut de l'écran avec le titre et le texte

## 🔍 Vérification des logs

### Logs attendus au démarrage
```
✅ Android notification channel created: high_importance_channel (heads-up enabled)
FCM Token: [votre_token]
```

### Logs attendus lors de la réception d'une notification

#### En foreground
```
🔔 [Foreground] Got a message whilst in the foreground!
🔔 [Foreground] Notification title: [titre]
🔔 [Foreground] Notification body: [corps]
✅ [Foreground] Local notification displayed
```

#### En background
```
🔔 [Background Handler] Received message: [messageId]
🔔 [Background Handler] Title: [titre]
🔔 [Background Handler] Body: [corps]
```

## ⚙️ Configuration avancée

### Modifier le style du popup

Dans `lib/features/messaging/fcm_service.dart`, vous pouvez modifier :

```dart
fullScreenIntent: true, // Pour un popup plein écran (au lieu de false)
```

### Modifier la couleur du popup

Dans `lib/features/messaging/fcm_service.dart`, modifiez :

```dart
color: const Color(0xFF6750A4), // Changez cette couleur
```

### Modifier le son de notification

Dans `android/app/src/main/kotlin/com/example/projet_flutter/MyFirebaseMessagingService.kt`, modifiez :

```kotlin
val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
// Ou utilisez un son personnalisé :
// val defaultSoundUri = Uri.parse("android.resource://${packageName}/${R.raw.notification_sound}")
```

## 🚨 Dépannage

### Le popup n'apparaît pas

1. **Vérifiez les permissions** :
   - Paramètres > Applications > projet_flutter > Notifications
   - Assurez-vous que les notifications sont activées

2. **Vérifiez le format du payload** :
   - Le payload doit contenir le champ `notification` (pas seulement `data`)
   - Exemple :
     ```json
     {
       "notification": {
         "title": "Titre",
         "body": "Corps"
       }
     }
     ```

3. **Vérifiez les logs** :
   - Cherchez `✅ Android notification channel created`
   - Cherchez `🔔 [Foreground]` ou `🔔 [Background Handler]`

4. **Testez sur un appareil physique** :
   - Certains émulateurs peuvent avoir des problèmes avec les popups

### Le popup apparaît mais disparaît trop vite

C'est le comportement normal d'Android. Le popup disparaît automatiquement après quelques secondes, mais la notification reste dans la barre de notifications.

### Le popup n'a pas de son

1. Vérifiez que le volume de l'appareil n'est pas en mode silencieux
2. Vérifiez les paramètres de notification de l'application
3. Vérifiez que `playSound: true` est configuré dans le code

## 📝 Notes importantes

- Les popups (heads-up notifications) nécessitent Android 5.0+ (API 21+)
- Sur Android 8.0+ (API 26+), le canal de notification doit être créé avec `Importance.max` ou `Importance.high`
- Les notifications avec `Importance.max` ou `Priority.max` s'affichent toujours comme des popups
- Les utilisateurs peuvent désactiver les popups dans les paramètres de notification de l'application, mais la notification apparaîtra toujours dans la barre de notifications

## 🎯 Résultat final

Maintenant, toutes les notifications FCM s'affichent comme des **popups en haut de l'écran** sur Android, offrant une meilleure expérience utilisateur avec une visibilité immédiate des notifications importantes.


