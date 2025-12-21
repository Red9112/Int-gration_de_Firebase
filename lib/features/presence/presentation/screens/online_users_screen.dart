import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../services/presence_service.dart';

class OnlineUsersScreen extends StatelessWidget {
  const OnlineUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs en ligne'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: PresenceService.listenToAllPresence(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('Aucun utilisateur en ligne'),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null || data.isEmpty) {
            return const Center(
              child: Text('Aucun utilisateur en ligne'),
            );
          }

          // Filtrer les utilisateurs en ligne
          final onlineUsers = <String, Map<dynamic, dynamic>>{};
          data.forEach((userId, userData) {
            if (userData is Map) {
              final current = userData['current'] as Map<dynamic, dynamic>?;
              if (current != null && current['online'] == true) {
                onlineUsers[userId] = current;
              }
            }
          });

          if (onlineUsers.isEmpty) {
            return const Center(
              child: Text('Aucun utilisateur en ligne'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: onlineUsers.length,
            itemBuilder: (context, index) {
              final userId = onlineUsers.keys.elementAt(index);
              final userData = onlineUsers[userId]!;
              final email = userData['email'] as String? ?? 'N/A';
              final lastSeen = userData['lastSeen'];
              final formattedDate = userData['lastSeenFormatted'] as String? ??
                  PresenceService.formatLastSeen(lastSeen);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Dernière connexion: $formattedDate'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


