import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotesElevePage extends StatefulWidget {
  final String utilisateurId; // UID de l'élève connecté

  const NotesElevePage({
    Key? key,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<NotesElevePage> createState() => _NotesElevePageState();
}

class _NotesElevePageState extends State<NotesElevePage> {
  String? eleveId;
  String nomComplet = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _chargerInfosEleve();
  }

  Future<void> _chargerInfosEleve() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('eleves')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          eleveId = snapshot.docs.first.id;
          nomComplet = "${data['nom']} ${data['prenom']}";
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
        print('[WARN] Aucun élève trouvé pour cet utilisateur.');
      }
    } catch (e) {
      print('[ERROR] Chargement élève : $e');
      setState(() => loading = false);
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  Future<String> _getNomMatiere(String matiereId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matieres')
          .doc(matiereId)
          .get();
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
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (eleveId == null) {
      return const Scaffold(
        body: Center(child: Text("Élève non trouvé.")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('eleveId', isEqualTo: eleveId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erreur lors du chargement des notes."));
          }

          final notes = snapshot.data?.docs ?? [];

          if (notes.isEmpty) {
            return const Center(child: Text("Aucune note trouvée."));
          }

          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
