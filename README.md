# Projet Flutter - Intégration Firebase

Application Flutter avec intégration complète de Firebase incluant l'authentification, Firestore, Realtime Database, Cloud Messaging, Analytics et Crashlytics.

## 🚀 Fonctionnalités

- **Authentification Firebase**
  - Connexion par email/mot de passe
  - Connexion avec Google Sign-In (Web et Mobile)
  - Inscription
  - Réinitialisation de mot de passe

- **Firestore Database**
  - Service wrapper pour les opérations CRUD
  - Gestion des documents et collections
  - Streams en temps réel
  - Requêtes avancées

- **Realtime Database**
  - Service wrapper pour les opérations CRUD
  - Listeners en temps réel (onValue, onChildAdded, etc.)
  - Transactions atomiques
  - Synchronisation hors ligne
  - Requêtes et filtres
  - **Gestion de présence utilisateur** : Suivi automatique du statut online/offline

- **Cloud Messaging (FCM)**
  - Notifications push (Android, iOS, **Web**)
  - Gestion des messages en foreground et background
  - Gestion des tokens FCM
  - Service Worker pour le web

- **Firebase Analytics**
  - Suivi des événements utilisateur
  - Logs d'écrans et d'actions

- **Firebase Crashlytics**
  - Rapport d'erreurs automatique
  - Logs personnalisés

## 📋 Prérequis

- Flutter SDK (3.10.3 ou supérieur)
- Dart SDK
- Compte Firebase
- Android Studio / Xcode (pour mobile)

## 🔧 Installation

1. Clonez le dépôt :
```bash
git clone https://github.com/Red9112/Int-gration_de_Firebase.git
cd Int-gration_de_Firebase
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Configurez Firebase :
   - Créez un projet Firebase sur [Firebase Console](https://console.firebase.google.com/)
   - Ajoutez vos applications Android/iOS/Web
   - Téléchargez les fichiers de configuration :
     - `google-services.json` pour Android → `android/app/`
     - `GoogleService-Info.plist` pour iOS → `ios/Runner/`
   - Générez `firebase_options.dart` avec FlutterFire CLI :
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

4. Configurez Google Sign-In :
   - **Pour le Web** : Activez la People API dans [Google Cloud Console](https://console.cloud.google.com/)
     - Voir `PEOPLE_API_SETUP.md` pour les instructions détaillées
   - **Pour Android** : Ajoutez le SHA-1 dans Firebase Console
     - Voir `ANDROID_GOOGLE_SIGNIN_SETUP.md` pour les instructions détaillées

## 🏃 Exécution

### Web
```bash
flutter run -d chrome
```

### Android
```bash
flutter run -d <device-id>
```

### iOS
```bash
flutter run -d <device-id>
```

## 📁 Structure du projet

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── core/
│   └── firebase/
│       ├── firebase_options.dart    # Configuration Firebase (généré)
│       └── firebase_service.dart    # Service d'initialisation Firebase
├── features/
│   ├── auth/
│   │   ├── auth_provider.dart       # Provider d'authentification
│   │   ├── data/
│   │   │   └── auth_repository.dart # Repository d'authentification
│   │   └── presentation/
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           ├── register_screen.dart
│   │           └── home_screen.dart
│   ├── database/
│   │   ├── firestore_service.dart  # Service Firestore
│   │   └── realtime_database_service.dart  # Service Realtime Database
│   └── messaging/
│       └── fcm_service.dart        # Service FCM
└── services/
    ├── analytics_service.dart      # Service Analytics
    ├── crashlytics_service.dart    # Service Crashlytics
    └── presence_service.dart       # Service de présence utilisateur
```

## 🔐 Configuration requise

### Firebase Console
- Activez **Authentication** > **Sign-in method** :
  - Email/Password
  - Google
- Créez une base de données Firestore (si nécessaire)
- Activez **Realtime Database** (si nécessaire)
  - Voir [REALTIME_DATABASE_SETUP.md](REALTIME_DATABASE_SETUP.md) pour la configuration
- Configurez Cloud Messaging (si nécessaire)

### Google Cloud Console
- **Pour le Web** : Activez la People API
- **Pour Android** : Configurez OAuth 2.0 avec SHA-1

## 📚 Documentation

- [Configuration People API pour Web](PEOPLE_API_SETUP.md)
- [Configuration Google Sign-In pour Android](ANDROID_GOOGLE_SIGNIN_SETUP.md)
- [Configuration FCM pour le Web](WEB_FCM_SETUP.md)
- [Configuration Realtime Database](REALTIME_DATABASE_SETUP.md)
- [Configuration Gestion de présence utilisateur](PRESENCE_SETUP.md)

## 🛠️ Technologies utilisées

- **Flutter** - Framework de développement
- **Firebase** - Backend as a Service
  - Firebase Auth
  - Cloud Firestore
  - Realtime Database
  - Cloud Messaging
  - Analytics
  - Crashlytics
- **Provider** - Gestion d'état
- **Google Sign-In** - Authentification Google

## 📝 Notes importantes

- Les fichiers `google-services.json`, `GoogleService-Info.plist` et `firebase_options.dart` sont exclus du dépôt pour des raisons de sécurité
- Chaque développeur doit générer ses propres fichiers de configuration Firebase
- Le SHA-1 doit être configuré pour chaque machine de développement

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## 📄 Licence

Ce projet est sous licence MIT.
