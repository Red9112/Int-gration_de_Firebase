# Configuration Firebase Cloud Messaging pour le Web

## Vue d'ensemble

Firebase Cloud Messaging (FCM) est maintenant configuré pour fonctionner sur le web. Cette configuration permet de recevoir des notifications push même lorsque l'application web est en arrière-plan ou fermée.

## Fichiers créés/modifiés

1. **`web/firebase-messaging-sw.js`** - Service Worker pour gérer les messages en background
2. **`web/index.html`** - Mise à jour pour enregistrer le service worker
3. **`lib/features/messaging/fcm_service.dart`** - Adaptation pour le web

## Configuration requise

### Étape 1 : Mettre à jour le Service Worker avec votre configuration Firebase

1. Ouvrez `web/firebase-messaging-sw.js`
2. Remplacez les valeurs dans `firebaseConfig` avec vos vraies valeurs Firebase :
   - Allez dans [Firebase Console](https://console.firebase.google.com/)
   - Sélectionnez votre projet
   - Allez dans **Paramètres du projet** > **Vos applications** > **Web app**
   - Copiez les valeurs de configuration

   OU

   - Exécutez `flutterfire configure` pour générer `firebase_options.dart`
   - Copiez les valeurs depuis `lib/core/firebase/firebase_options.dart` (classe `DefaultFirebaseOptions.web`)

### Étape 2 : Vérifier le manifest.json

Assurez-vous que `web/manifest.json` contient les icônes nécessaires (déjà configuré).

### Étape 3 : Tester

1. Lancez l'application web :
   ```bash
   flutter run -d chrome
   ```

2. Autorisez les notifications lorsque le navigateur le demande

3. Vérifiez dans la console que le service worker est enregistré :
   ```
   Service Worker registered with scope: ...
   ```

4. Vérifiez que le token FCM est obtenu :
   ```
   FCM Token: ...
   ```

## Fonctionnalités

### Messages Foreground
- Les notifications sont gérées par l'API Notification du navigateur
- S'affichent automatiquement si l'utilisateur a accordé les permissions

### Messages Background
- Gérés par le service worker (`firebase-messaging-sw.js`)
- S'affichent même si l'application est fermée ou en arrière-plan

### Clic sur notification
- Ouvre l'application si elle est fermée
- Focus sur l'application si elle est déjà ouverte

## Envoi de notifications de test

### Depuis Firebase Console

1. Allez dans Firebase Console > **Cloud Messaging**
2. Cliquez sur **Nouvelle notification**
3. Remplissez le titre et le message
4. Cliquez sur **Envoyer un message de test**
5. Collez le token FCM (visible dans les logs de l'application)
6. Cliquez sur **Test**

### Depuis l'API REST

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/flutterproject-72994/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN",
      "notification": {
        "title": "Test Notification",
        "body": "This is a test notification from FCM"
      }
    }
  }'
```

## Limitations du Web

1. **HTTPS requis** : Les notifications push ne fonctionnent qu'en HTTPS (ou localhost pour le développement)
2. **Permissions utilisateur** : L'utilisateur doit explicitement autoriser les notifications
3. **Support navigateur** : Fonctionne sur Chrome, Firefox, Edge, Safari (macOS/iOS 16.4+)
4. **Service Worker** : Nécessite un service worker enregistré

## Dépannage

### Le service worker ne s'enregistre pas

1. Vérifiez que vous servez l'application via HTTPS ou localhost
2. Vérifiez la console du navigateur pour les erreurs
3. Vérifiez que `firebase-messaging-sw.js` est accessible à la racine du site

### Les notifications ne s'affichent pas

1. Vérifiez que l'utilisateur a autorisé les notifications
2. Vérifiez que le token FCM est bien obtenu
3. Vérifiez que la configuration Firebase dans le service worker est correcte
4. Vérifiez les règles de sécurité du navigateur (bloqueurs de publicités, etc.)

### Erreur "Firebase: Error (messaging/unsupported-browser)"

- Vérifiez que vous utilisez un navigateur supporté
- Vérifiez que les notifications sont activées dans les paramètres du navigateur

## Notes importantes

- Le service worker doit être à la racine du domaine (`/firebase-messaging-sw.js`)
- Les notifications web utilisent l'API Notification du navigateur, pas `flutter_local_notifications`
- Le service worker fonctionne indépendamment de l'application Flutter une fois enregistré

## Support

Pour plus d'informations, consultez :
- [Firebase Cloud Messaging Web Documentation](https://firebase.google.com/docs/cloud-messaging/js/client)
- [Service Workers MDN](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)

