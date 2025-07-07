import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotesEnfantPage extends StatelessWidget {
  final String enfantId;
  final String nomComplet;

  const NotesEnfantPage({
    Key? key,
    required this.enfantId,
    required this.nomComplet,
  }) : super(key: key);

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  Future<String> _getNomMatiere(String matiereId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('matieres').doc(matiereId).get();
      if (doc.exists) {
        return doc['nom'] ?? 'Matière inconnue';
      }
    } catch (e) {
      print('[ERROR] Chargement matière $matiereId : $e');
    }
    return 'Matière inconnue';
  }

  @override
  Widget build(BuildContext context) {
    print("[DEBUG] NotesEnfantPage build pour enfantId: $enfantId");

    return Scaffold(
      appBar: AppBar(
        title: Text("Notes de $nomComplet"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('eleveId', isEqualTo: enfantId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("[DEBUG] Chargement des notes en cours...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("[ERROR] Erreur dans la requête notes : ${snapshot.error}");
            return Center(child: Text("Erreur lors du chargement des notes."));
          }

          final notes = snapshot.data?.docs ?? [];
          print("[DEBUG] Nombre de notes récupérées: ${notes.length}");

          if (notes.isEmpty) {
            return const Center(child: Text("Aucune note trouvée."));
          }

          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
            itemBuilder: (context, index) {
              final data = notes[index].data() as Map<String, dynamic>;
              final matiereId = data['matiereId'] ?? '';
              final valeur = data['valeur']?.toString() ?? '-';
              final type = data['type'] ?? '';
              final mention = data['mention'] ?? '';
              final description = data['description'] ?? '';
              final sequence = data['sequence'] ?? '';
              final date = data['date'] as Timestamp?;

              String detail = '';
              if (type == 'Exercice' && description.isNotEmpty) {
                detail = "Exercice : $description";
              } else if (type == 'Examen' && sequence.isNotEmpty) {
                detail = "Examen : $sequence";
              }

              return FutureBuilder<String>(
                future: _getNomMatiere(matiereId),
                builder: (context, matiereSnapshot) {
                  final matiereNom = matiereSnapshot.data ?? '...';
                  return ListTile(
                    leading: const Icon(Icons.grade, color: Colors.teal),
                    title: Text("$matiereNom — Note : $valeur/20"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mention.isNotEmpty) Text("Mention : $mention"),
                        if (detail.isNotEmpty) Text(detail),
                        if (date != null) Text("Date : ${_formatDate(date)}"),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
