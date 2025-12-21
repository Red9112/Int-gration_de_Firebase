import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import '../../auth_provider.dart' as auth;
import '../../../../services/analytics_service.dart';
import '../../../../services/presence_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<auth.AuthProvider>();
              await authProvider.signOut();
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenue !',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Text(
                  'Email: ${user.email}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'UID: ${user.uid}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                // Affichage de la présence utilisateur en temps réel
                StreamBuilder<DatabaseEvent>(
                  stream: PresenceService.listenToUserPresence(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.exists) {
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      final isOnline = data['online'] as bool? ?? false;
                      final lastSeen = data['lastSeen'];
                      // Utiliser lastSeenFormatted si disponible, sinon formater
                      final formattedDate = data['lastSeenFormatted'] as String? ?? 
                                          PresenceService.formatLastSeen(lastSeen);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isOnline ? Icons.circle : Icons.circle_outlined,
                                    color: isOnline ? Colors.green : Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isOnline ? 'En ligne' : 'Hors ligne',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isOnline ? Colors.green : Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dernière connexion: $formattedDate',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await AnalyticsService.logButtonClick(
                    buttonName: 'test_firebase',
                    screenName: 'home_screen',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Événement Analytics enregistré !'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Tester Analytics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


