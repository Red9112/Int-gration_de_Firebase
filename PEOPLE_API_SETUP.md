# Configuration de la People API pour Google Sign-In sur le Web

## Problème

Lors de l'utilisation de Google Sign-In sur le web, vous pouvez rencontrer l'erreur suivante :

```
People API has not been used in project 276653859682 before or it is disabled.
```

Cette erreur se produit car le package `google_sign_in` sur le web nécessite la People API pour récupérer les informations de profil de l'utilisateur.

## Solution : Activer la People API

### Étape 1 : Accéder à Google Cloud Console

1. Ouvrez votre navigateur et allez sur : [Google Cloud Console - People API](https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=276653859682)

   **OU**

2. Accédez manuellement :
   - Allez sur [Google Cloud Console](https://console.cloud.google.com/)
   - Sélectionnez votre projet Firebase (ID: 276653859682)
   - Allez dans **APIs & Services** > **Library**
   - Recherchez "People API"
   - Cliquez sur "People API"

### Étape 2 : Activer l'API

1. Cliquez sur le bouton **"ENABLE"** (Activer)
2. Attendez quelques minutes pour que l'activation se propage dans les systèmes Google

### Étape 3 : Vérifier les permissions

Assurez-vous que votre projet Firebase a les permissions nécessaires :
- L'API doit être activée pour le projet
- Les credentials OAuth 2.0 doivent être configurés dans Firebase Console

### Étape 4 : Tester à nouveau

Après avoir activé l'API, attendez 2-3 minutes puis testez à nouveau la connexion Google dans votre application Flutter.

## Alternative : Utiliser Firebase Auth directement (avancé)

Si vous ne souhaitez pas activer la People API, vous pouvez utiliser Firebase Auth directement avec Google Identity Services, mais cela nécessite une implémentation personnalisée plus complexe.

## Notes importantes

- La People API est **requise** pour `google_sign_in` sur le web
- Sur mobile (Android/iOS), la People API n'est pas nécessaire
- L'activation de l'API est gratuite et ne génère pas de coûts supplémentaires
- L'API est utilisée uniquement pour récupérer les informations de profil de base (email, nom, photo)

## Vérification

Pour vérifier que l'API est activée :

1. Allez dans Google Cloud Console > APIs & Services > Enabled APIs
2. Recherchez "People API"
3. Elle devrait apparaître dans la liste des APIs activées

## Support

Si vous rencontrez toujours des problèmes après avoir activé l'API :

1. Vérifiez que vous avez attendu quelques minutes après l'activation
2. Vérifiez que vous utilisez le bon projet Firebase
3. Vérifiez les logs de la console pour d'autres erreurs
4. Assurez-vous que les credentials OAuth 2.0 sont correctement configurés dans Firebase Console



