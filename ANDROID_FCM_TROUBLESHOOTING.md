# Dépannage FCM sur Android

## Problème : Les notifications ne s'affichent pas sur Android

Si vous recevez le token FCM mais que les notifications ne s'affichent pas, voici les solutions :

## ✅ Solutions

### 1. Vérifier les permissions Android

Sur Android 13+ (API 33+), les notifications nécessitent une permission explicite.

**Vérification :**
- Allez dans **Paramètres** de l'émulateur/appareil
- **Applications** > **projet_flutter** > **Notifications**
- Assurez-vous que les notifications sont **activées**

**Code :** La permission est déjà demandée dans `FCMService.initialize()` via `requestPermission()`.

### 2. Vérifier le format de la notification depuis Firebase Console

**IMPORTANT :** Pour que les notifications s'affichent automatiquement en background sur Android, le payload doit contenir le champ `notification` :

```json
{
  "notification": {
    "title": "Titre de la notification",
    "body": "Corps de la notification"
  },
  "data": {
    "custom_key": "custom_value"
  }
}
```

**❌ Ne fonctionne PAS (data seulement) :**
```json
{
  "data": {
    "title": "Titre",
    "body": "Corps"
  }
}
```

**✅ Fonctionne (notification + data) :**
```json
{
  "notification": {
    "title": "Titre",
    "body": "Corps"
  },
  "data": {
    "custom": "value"
  }
}
```

### 3. Vérifier le canal de notification

Le canal `high_importance_channel` est maintenant créé automatiquement dans le code.

**Vérification dans les logs :**
```
✅ Android notification channel created: high_importance_channel
```

### 4. Tester avec l'app en différents états

#### A. App en foreground (ouverte)
- Les notifications sont gérées par `_handleForegroundMessage()`
- Une notification locale est affichée via `flutter_local_notifications`
- **Logs attendus :**
  ```
  Got a message whilst in the foreground!
  Message notification: [titre]
  ```

#### B. App en background (minimisée)
- Les notifications sont gérées automatiquement par Android
- Le handler `firebaseMessagingBackgroundHandler` est appelé
- **Logs attendus :**
  ```
  🔔 [Background Handler] Received message: [messageId]
  🔔 [Background Handler] Title: [titre]
  ```

#### C. App terminée (fermée)
- Les notifications sont gérées automatiquement par Android
- Le handler `firebaseMessagingBackgroundHandler` est appelé
- La notification s'affiche dans la barre de notifications

### 5. Vérifier les logs Android

Utilisez `adb logcat` pour voir les logs détaillés :

```bash
adb logcat | grep -i "firebase\|fcm\|notification"
```

**Logs importants à chercher :**
- `FCM Token: ...` - Token obtenu
- `Got a message whilst in the foreground!` - Message reçu en foreground
- `🔔 [Background Handler]` - Message reçu en background
- `✅ Android notification channel created` - Canal créé

### 6. Vérifier la configuration Firebase

1. **Firebase Console > Cloud Messaging**
   - Vérifiez que Cloud Messaging est activé
   - Vérifiez que votre application Android est bien enregistrée

2. **Firebase Console > Project Settings > Cloud Messaging**
   - Vérifiez que la clé serveur est configurée (pour les notifications depuis un serveur)

### 7. Tester avec différents formats de payload

#### Test 1 : Notification simple (devrait fonctionner)
```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This is a test"
  }
}
```

#### Test 2 : Notification avec data (devrait fonctionner)
```json
{
  "notification": {
    "title": "Test Notification",
    "body": "This is a test"
  },
  "data": {
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "route": "/home"
  }
}
```

#### Test 3 : Data seulement (ne s'affichera PAS automatiquement)
```json
{
  "data": {
    "title": "Test",
    "body": "Test body"
  }
}
```

### 8. Vérifier l'émulateur Android

Certains émulateurs Android peuvent avoir des problèmes avec les notifications :

1. **Vérifier les paramètres de l'émulateur :**
   - Paramètres > Applications > projet_flutter > Notifications
   - Assurez-vous que les notifications sont activées

2. **Tester sur un appareil physique :**
   - Les notifications fonctionnent mieux sur de vrais appareils

3. **Vérifier la version Android :**
   - Android 8.0+ nécessite des canaux de notification (déjà géré dans le code)
   - Android 13+ nécessite une permission explicite (déjà géré dans le code)

### 9. Vérifier le service worker Android

Le service `FirebaseMessagingService` est configuré dans `AndroidManifest.xml`.

**Vérification :**
- Le service est déclaré avec l'action `com.google.firebase.MESSAGING_EVENT`
- Le canal par défaut est configuré : `high_importance_channel`

### 10. Commandes de test

#### Vérifier le token FCM
```bash
adb logcat | grep "FCM Token"
```

#### Vérifier les notifications
```bash
adb logcat | grep -i "notification\|fcm"
```

#### Vérifier les permissions
```bash
adb shell dumpsys package com.example.projet_flutter | grep permission
```

## 🔍 Checklist de diagnostic

- [ ] Le token FCM est obtenu (visible dans les logs)
- [ ] Les permissions de notification sont accordées
- [ ] Le canal de notification est créé (log: "✅ Android notification channel created")
- [ ] Le payload contient le champ `notification` (pas seulement `data`)
- [ ] L'app est testée en foreground ET en background
- [ ] Les logs montrent que le message est reçu
- [ ] Le service `FirebaseMessagingService` est configuré dans AndroidManifest.xml
- [ ] Google Services est configuré (google-services.json présent)

## 📝 Format de notification recommandé

Pour garantir que les notifications fonctionnent dans tous les cas :

```json
{
  "notification": {
    "title": "Titre de la notification",
    "body": "Corps de la notification",
    "sound": "default",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "data": {
    "route": "/home",
    "custom_data": "value"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "high_importance_channel",
      "sound": "default"
    }
  }
}
```

## 🚨 Problèmes courants

### Problème : "Notifications reçues mais pas affichées"
**Solution :** Vérifiez que le payload contient le champ `notification`, pas seulement `data`.

### Problème : "Notifications en foreground mais pas en background"
**Solution :** C'est normal si le payload ne contient que `data`. Ajoutez le champ `notification`.

### Problème : "Aucune notification du tout"
**Solution :** 
1. Vérifiez les permissions
2. Vérifiez que le canal est créé
3. Vérifiez le format du payload
4. Testez sur un appareil physique

## 📞 Support

Si le problème persiste après avoir vérifié tous les points ci-dessus :
1. Partagez les logs complets (`adb logcat`)
2. Partagez le format exact du payload utilisé
3. Indiquez l'état de l'app (foreground/background/terminated)
4. Indiquez la version Android de l'émulateur/appareil


