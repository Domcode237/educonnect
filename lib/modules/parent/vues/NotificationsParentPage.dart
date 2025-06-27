import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../enseignant/modeles/model_notification.dart';

class NotificationsParentPage extends StatefulWidget {
  final String parentId;

  const NotificationsParentPage({super.key, required this.parentId});

  @override
  State<NotificationsParentPage> createState() => _NotificationsParentPageState();
}

class _NotificationsParentPageState extends State<NotificationsParentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<NotificationModele>> _notificationsStream() {
    return _firestore
        .collection('notifications')
        .where('parentId', isEqualTo: widget.parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        DateTime createdAt;
        try {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } catch (_) {
          createdAt = DateTime.now();
        }

        return NotificationModele(
          id: doc.id,
          eleveId: data['eleveId'] ?? '',
          parentId: data['parentId'] ?? '',
          expediteurId: data['expediteurId'] ?? '',
          expediteurRole: data['expediteurRole'] ?? '',
          etablissementId: data['etablissementId'] ?? '',
          titre: data['titre'] ?? 'Notification',
          message: data['message'] ?? '',
          lu: data['lu'] ?? false,
          createdAt: createdAt,
          type: data['type'] ?? '',
          metadata: data['metadata'] != null
              ? Map<String, dynamic>.from(data['metadata'])
              : null,
        );
      }).toList();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min";
    if (diff.inHours < 24) return "${diff.inHours} h";
    return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  Widget _buildNotificationTile(NotificationModele notif) {
    final isLu = notif.lu;
    final icon = isLu ? Icons.notifications_none : Icons.notifications_active;
    final iconColor = isLu ? Colors.grey : Colors.blue;

    return Column(
      children: [
        ListTile(
          onTap: () async {
            if (!notif.lu) {
              await _firestore.collection('notifications').doc(notif.id).update({'lu': true});
              setState(() {});
            }
          },
          leading: Icon(icon, color: iconColor, size: 30),
          title: Text(
            notif.titre,
            style: TextStyle(
              fontWeight: isLu ? FontWeight.normal : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notif.message,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(notif.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        const Divider(height: 0, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<NotificationModele>>(
        stream: _notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains("requires an index")) {
              final indexLinkRegex = RegExp(r'https://console.firebase.google.com[^\s]+');
              final match = indexLinkRegex.firstMatch(errorMsg);
              final indexLink = match?.group(0) ?? "Lien non disponible";

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    "🔥 Firestore nécessite un index composite pour cette requête.\n\n"
                    "Cliquez sur le lien suivant pour créer l'index :\n\n$indexLink",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Center(child: Text("Erreur de chargement: $errorMsg"));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text("Aucune notification pour le moment."));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationTile(notif);
              },
            ),
          );
        },
      ),
    );
  }
}
