# Configuration Google Sign-In pour Android

## Problème

Si Google Sign-In fonctionne (vous pouvez sélectionner un compte) mais que l'application retourne à la page de connexion après l'authentification, cela indique généralement un problème de configuration SHA-1 dans Firebase Console.

## Solution : Configurer le SHA-1 dans Firebase Console

### Étape 1 : Obtenir le SHA-1 de votre application

#### Pour Windows (PowerShell) :

```powershell
cd android
.\gradlew signingReport
```

#### Pour Windows (CMD) :

```cmd
cd android
gradlew signingReport
```

#### Pour Mac/Linux :

```bash
cd android
./gradlew signingReport
```

### Étape 2 : Trouver le SHA-1 dans la sortie

Cherchez dans la sortie une ligne qui ressemble à :

```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: XX:XX:XX:...
Valid until: ...
```

**Copiez le SHA1** (la ligne qui commence par `SHA1:`).

### Étape 3 : Ajouter le SHA-1 dans Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet Firebase
3. Allez dans **Paramètres du projet** (icône d'engrenage) > **Vos applications**
4. Trouvez votre application Android (package name: `com.example.projet_flutter`)
5. Cliquez sur l'application Android
6. Dans la section **Empreintes de certificat SHA**, cliquez sur **Ajouter une empreinte**
7. Collez le SHA-1 que vous avez copié
8. Cliquez sur **Enregistrer**

### Étape 4 : Télécharger le nouveau `google-services.json`

1. Après avoir ajouté le SHA-1, téléchargez le nouveau fichier `google-services.json`
2. Remplacez le fichier existant dans `android/app/google-services.json`
3. Redémarrez l'application

### Étape 5 : Vérifier la configuration OAuth

1. Allez dans [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet Firebase
3. Allez dans **APIs & Services** > **Credentials**
4. Trouvez votre **OAuth 2.0 Client ID** pour Android
5. Vérifiez que le **Package name** est correct : `com.example.projet_flutter`
6. Vérifiez que le **SHA-1** est présent dans la liste

## Vérification rapide

Pour vérifier rapidement votre SHA-1 actuel :

```bash
# Windows (PowerShell)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Mac/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Pour les builds de production

Si vous créez un build de production, vous devrez également ajouter le SHA-1 de votre keystore de production :

1. Générez le SHA-1 de votre keystore de production :
   ```bash
   keytool -list -v -keystore votre-keystore.jks -alias votre-alias
   ```

2. Ajoutez ce SHA-1 dans Firebase Console de la même manière

## Notes importantes

- Le SHA-1 est nécessaire pour que Google Sign-In fonctionne sur Android
- Chaque environnement (debug, release) peut avoir un SHA-1 différent
- Après avoir ajouté le SHA-1, attendez quelques minutes pour que les changements se propagent
- Si vous utilisez plusieurs machines de développement, vous devrez ajouter le SHA-1 de chaque machine

## Dépannage

Si le problème persiste après avoir ajouté le SHA-1 :

1. Vérifiez que vous avez bien téléchargé le nouveau `google-services.json`
2. Vérifiez que le package name dans Firebase Console correspond à `com.example.projet_flutter`
3. Vérifiez les logs de l'application pour voir les erreurs spécifiques
4. Attendez 5-10 minutes après avoir ajouté le SHA-1 pour que les changements se propagent
5. Redémarrez complètement l'application (pas juste un hot reload)

## Support

Si vous rencontrez toujours des problèmes, vérifiez :
- Les logs de l'application (cherchez les messages `[Google Sign-In]`)
- La console Firebase pour les erreurs d'authentification
- Que Google Sign-In est bien activé dans Firebase Console > Authentication > Sign-in method

