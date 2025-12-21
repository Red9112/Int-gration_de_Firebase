import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_provider.dart' as auth;
import '../../../../services/presence_service.dart';
import '../../../../features/database/firestore_service.dart';
import '../../../presence/presentation/screens/online_users_screen.dart';
import '../../../messaging/presentation/widgets/test_notification_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

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
      body: user == null
          ? const Center(child: Text('Utilisateur non connecté'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Option 1: Informations utilisateur complètes
                  _buildUserInfoSection(context, user, firestoreService),
                  
                  const SizedBox(height: 24),
                  
                  // Option 2: Liste des utilisateurs en ligne
                  _buildOnlineUsersButton(context),
                  
                  const SizedBox(height: 16),
                  
                  // Option 3: Bouton test notification
                  const TestNotificationButton(),
                  
                  const SizedBox(height: 16),
                  
                  // Option 4: Historique de connexion
                  _buildLoginHistorySection(context, user, firestoreService),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection(
    BuildContext context,
    firebase_auth.User user,
    FirestoreService firestoreService,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Informations utilisateur',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Nom
            _buildInfoRow(
              context,
              'Nom',
              user.displayName ?? 'Non défini',
              Icons.badge,
            ),
            
            const SizedBox(height: 12),
            
            // Email
            _buildInfoRow(
              context,
              'Email',
              user.email ?? 'N/A',
              Icons.email,
            ),
            
            const SizedBox(height: 12),
            
            // Statut online (Realtime Database)
            StreamBuilder<DatabaseEvent>(
              stream: PresenceService.listenToUserPresence(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.exists) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final isOnline = data['online'] as bool? ?? false;
                  return _buildInfoRow(
                    context,
                    'Statut',
                    isOnline ? '🟢 En ligne' : '🔴 Hors ligne',
                    isOnline ? Icons.circle : Icons.circle_outlined,
                    color: isOnline ? Colors.green : Colors.grey,
                  );
                }
                return _buildInfoRow(
                  context,
                  'Statut',
                  'Chargement...',
                  Icons.hourglass_empty,
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Auth
            _buildInfoRow(
              context,
              'Auth',
              '✅ Connecté',
              Icons.verified_user,
              color: Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            // Firestore
            StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.streamDocument(
                collection: 'users',
                documentId: user.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  return _buildInfoRow(
                    context,
                    'Firestore',
                    '✅ Document existant',
                    Icons.cloud_done,
                    color: Colors.green,
                  );
                }
                return _buildInfoRow(
                  context,
                  'Firestore',
                  '⏳ En attente...',
                  Icons.cloud_off,
                  color: Colors.orange,
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Realtime Database (présence)
            StreamBuilder<DatabaseEvent>(
              stream: PresenceService.listenToUserPresence(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.exists) {
                  return _buildInfoRow(
                    context,
                    'Realtime Database',
                    '✅ Présence active',
                    Icons.sync,
                    color: Colors.green,
                  );
                }
                return _buildInfoRow(
                  context,
                  'Realtime Database',
                  '⏳ En attente...',
                  Icons.sync_disabled,
                  color: Colors.orange,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineUsersButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OnlineUsersScreen(),
          ),
        );
      },
      icon: const Icon(Icons.people),
      label: const Text('Voir les utilisateurs en ligne'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildLoginHistorySection(
    BuildContext context,
    firebase_auth.User user,
    FirestoreService firestoreService,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Historique de connexion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.streamDocument(
                collection: 'users',
                documentId: user.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('Aucun historique disponible');
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const Text('Aucun historique disponible');
                }

                final lastSignInAt = userData['lastSignInAt'] as Timestamp?;
                final lastSignInMethod = userData['lastSignInMethod'] as String? ?? 'N/A';

                String formattedDate = 'N/A';
                if (lastSignInAt != null) {
                  final date = lastSignInAt.toDate();
                  formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Dernière connexion',
                      formattedDate,
                      Icons.access_time,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Méthode',
                      lastSignInMethod == 'google' ? '🔵 Google' : '📧 Email',
                      lastSignInMethod == 'google' ? Icons.g_mobiledata : Icons.email,
                      color: lastSignInMethod == 'google' ? Colors.blue : Colors.green,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


