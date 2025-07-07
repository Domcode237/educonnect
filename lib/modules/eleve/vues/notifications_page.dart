import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationModeleEleve {
  final String id;
  final String eleveId;
  final String destinataireId;
  final String message;
  final bool lu;
  final DateTime date;
  final String type;
  final String? noteId;

  NotificationModeleEleve({
    required this.id,
    required this.eleveId,
    required this.destinataireId,
    required this.message,
    required this.lu,
    required this.date,
    required this.type,
    this.noteId,
  });

  factory NotificationModeleEleve.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parsedDate;
    try {
      parsedDate = (data['date'] as Timestamp).toDate();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModeleEleve(
      id: doc.id,
      eleveId: data['eleveId'] ?? '',
      destinataireId: data['destinataireId'] ?? '',
      message: data['message'] ?? '',
      lu: data['vu'] ?? false,
      date: parsedDate,
      type: data['type'] ?? '',
      noteId: data['noteId'],
    );
  }
}

class ListeNotificationsElevePage extends StatefulWidget {
  final String utilisateurId;

  const ListeNotificationsElevePage({Key? key, required this.utilisateurId}) : super(key: key);

  @override
  State<ListeNotificationsElevePage> createState() => _ListeNotificationsElevePageState();
}

class _ListeNotificationsElevePageState extends State<ListeNotificationsElevePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _eleveId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('[initState] Recherche élève avec utilisateurId=${widget.utilisateurId}');
    _fetchEleveId();
  }

  Future<void> _fetchEleveId() async {
    try {
      final query = await _firestore
          .collection('eleves')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('[fetchEleveId] Aucun élève trouvé pour utilisateurId=${widget.utilisateurId}');
        setState(() {
          _error = "Aucun élève trouvé pour cet utilisateur.";
          _loading = false;
        });
        return;
      }

      _eleveId = query.docs.first.id;
      print('[fetchEleveId] Élève trouvé: eleveId=$_eleveId');
      setState(() => _loading = false);
    } catch (e) {
      print('[fetchEleveId] Erreur: $e');
      setState(() {
        _error = "Erreur de chargement : $e";
        _loading = false;
      });
    }
  }

  Stream<List<NotificationModeleEleve>> _notificationsStream() {
    if (_eleveId == null) {
      print('[notificationsStream] eleveId non défini');
      return const Stream.empty();
    }

    print('[notificationsStream] Écoute notifications pour eleveId=$_eleveId');

    return _firestore
        .collection('notifications')
        .where('eleveId', isEqualTo: _eleveId)
        .where('destinataireId', isEqualTo: _eleveId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print('[notificationsStream] ${snapshot.docs.length} notifications reçues');
      return snapshot.docs.map((doc) => NotificationModeleEleve.fromDoc(doc)).toList();
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

  Widget _buildNotificationTile(NotificationModeleEleve notif) {
    final isLu = notif.lu;
    final icon = isLu ? Icons.notifications : Icons.notifications_active;
    final iconColor = isLu ? Colors.black : Colors.blue;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isLu ? Colors.transparent : const Color.fromARGB(44, 195, 221, 235),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              onTap: () async {
                if (!notif.lu) {
                  print('[onTap] Marque notification ${notif.id} comme lue');
                  await _firestore.collection('notifications').doc(notif.id).update({'vu': true});
                  setState(() {});
                }
              },
              leading: Icon(icon, color: iconColor, size: 30),
              title: Text(
                notif.type,
                style: TextStyle(
                  fontWeight: isLu ? FontWeight.normal : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(notif.message, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(_formatDate(notif.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            ),
          ),
        ),
        const Divider(height: 0, thickness: 1, indent: 22, endIndent: 22),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Erreur : $_error')));
    }

    return Scaffold(
      body: StreamBuilder<List<NotificationModeleEleve>>(
        stream: _notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

         if (snapshot.hasError) {
  final errorMsg = snapshot.error.toString();
  print('[StreamBuilder] Erreur détectée: $errorMsg');

  if (errorMsg.contains('failed precondition') && errorMsg.contains('index')) {
    // Cherche un lien vers la console Firebase
    final indexLinkRegex = RegExp(r'https:\/\/console\.firebase\.google\.com[^\s]+');
    final match = indexLinkRegex.firstMatch(errorMsg);
    final indexLink = match?.group(0) ?? "Lien non trouvé.";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          "⚠️ Un index Firestore est requis pour cette requête.\n\n"
          "Créez-le en cliquant sur le lien ci-dessous :\n\n"
          "$indexLink",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  return Center(child: Text("Erreur : $errorMsg"));
}

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text("Aucune notification pour le moment."));
          }

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) => _buildNotificationTile(notifications[index]),
            ),
          );
        },
      ),
    );
  }
}
