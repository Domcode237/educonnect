import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ListeDevoirsParentPage extends StatefulWidget {
  final String utilisateurId;
  const ListeDevoirsParentPage({super.key, required this.utilisateurId});

  @override
  State<ListeDevoirsParentPage> createState() => _ListeDevoirsParentPageState();
}

class _ListeDevoirsParentPageState extends State<ListeDevoirsParentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot> _devoirsStream;

  @override
  void initState() {
    super.initState();
    _devoirsStream = _firestore
        .collection('devoirs')
        .where('parentIds', arrayContains: widget.utilisateurId)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  Future<List<String>> _chargerNomsEnfants(List<String> eleveIdsDuDevoir) async {
  try {

    final famillesSnap = await _firestore
        .collection('famille')
        .where('parentId', isEqualTo: widget.utilisateurId)
        .get();


    final eleveIdsLies = famillesSnap.docs
        .map((doc) {
          final data = doc.data();
          final eleveId = data['eleveId'];
          return eleveId as String?;
        })
        .whereType<String>()
        .toSet();


    final elevesParents = eleveIdsDuDevoir
        .where((id) => eleveIdsLies.contains(id))
        .toList();


    if (elevesParents.isEmpty) {
      return [];
    }

    // Étape 2 : Récupération des élèves pour obtenir les utilisateurId
    final elevesDocs = await _firestore
        .collection('eleves')
        .where(FieldPath.documentId, whereIn: elevesParents)
        .get();


    final utilisateurIds = elevesDocs.docs
        .map((doc) {
          final uid = doc.data()['utilisateurId'];
          return uid;
        })
        .whereType<String>()
        .toList();

    if (utilisateurIds.isEmpty) {
      return [];
    }

    // Étape 3 : Récupération des utilisateurs liés à ces ids
    final utilisateursDocs = await _firestore
        .collection('utilisateurs')
        .where(FieldPath.documentId, whereIn: utilisateurIds)
        .get();


    final noms = utilisateursDocs.docs.map((doc) {
      final data = doc.data();
      final prenom = data['prenom'] ?? '';
      final nom = data['nom'] ?? '';
      final nomComplet = '$prenom $nom'.trim();
      return nomComplet;
    }).toList();

    return noms;
  } catch (e, stack) {
    return [];
  }
}



  Future<String?> _chargerNomClasse(String classeId) async {
    final doc = await _firestore.collection('classes').doc(classeId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final nom = data['nom'] ?? '';
    final niveau = data['niveau'] ?? '';
    return '$nom ($niveau)';
  }

  Future<String?> _chargerNomMatiere(String matiereId) async {
    final doc = await _firestore.collection('matieres').doc(matiereId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['nom'] ?? '';
  }

  Future<void> _marquerCommeLu(String devoirDocId, List<dynamic>? lus) async {
    if (lus != null && lus.contains(widget.utilisateurId)) return;
    final updatedLus = [...?lus, widget.utilisateurId];
    await _firestore.collection('devoirs').doc(devoirDocId).update({'lu': updatedLus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _devoirsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement des devoirs.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Aucun devoir trouvé'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final titre = data['titre'] ?? 'Sans titre';
              final description = data['description'] ?? '';
              final eleveIds = List<String>.from(data['eleveIds'] ?? []);
              final lus = List<String>.from(data['lu'] ?? []);
              final classeId = data['classeId'] ?? '';
              final matiereId = data['matiereId'] ?? '';
              final dateRemiseTs = data['dateRemise'] as Timestamp?;
              final dateRemise = dateRemiseTs?.toDate();
              final dateRemiseStr = dateRemise != null
                  ? DateFormat('dd/MM/yyyy').format(dateRemise)
                  : 'Date non précisée';

              final bool estLu = lus.contains(widget.utilisateurId);

              return FutureBuilder<List<String>>(
                future: _chargerNomsEnfants(eleveIds),
                builder: (context, snapshotEnfants) {
                  final enfants = snapshotEnfants.data ?? [];
                  final enfantsStr = enfants.isEmpty
                      ? 'Enfant(s) non trouvé(s)'
                      : enfants.join(', ');

                  return FutureBuilder<String?>(
                    future: _chargerNomClasse(classeId),
                    builder: (context, snapshotClasse) {
                      final classeStr = snapshotClasse.data ?? 'Classe inconnue';

                      return FutureBuilder<String?>(
                        future: _chargerNomMatiere(matiereId),
                        builder: (context, snapshotMatiere) {
                          final matiereStr = snapshotMatiere.data ?? 'Matière inconnue';

                          return ListTile(
                            tileColor: estLu ? null : Colors.pink.shade50,
                            title: Text(
                              titre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: estLu ? null : const Color.fromARGB(232, 194, 24, 92),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty)
                                  Text(
                                    description.length > 80
                                        ? '${description.substring(0, 80)}...'
                                        : description,
                                  ),
                                Text('Date de remise : $dateRemiseStr'),
                                Text('Pour : $enfantsStr'),
                                Text('Classe : $classeStr'),
                                Text('Matière : $matiereStr'),
                              ],
                            ),
                            trailing: estLu
                                ? const Icon(Icons.notifications_none_outlined, color: Color.fromARGB(255, 5, 5, 5),size: 25,)
                                : const Icon(Icons.notifications_active, color: Color.fromARGB(255, 252, 0, 0)),
                            onTap: () async {
                              await _marquerCommeLu(doc.id, lus);
                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailDevoirPage(
                                    devoirDoc: doc,
                                    devoirData: data,
                                    utilisateurId: widget.utilisateurId,
                                    enfantsNoms: enfants,
                                    classeNom: classeStr,
                                    matiereNom: matiereStr,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
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

class DetailDevoirPage extends StatelessWidget {
  final QueryDocumentSnapshot devoirDoc;
  final Map<String, dynamic> devoirData;
  final String utilisateurId;
  final List<String> enfantsNoms;
  final String classeNom;
  final String matiereNom;

  const DetailDevoirPage({
    super.key,
    required this.devoirDoc,
    required this.devoirData,
    required this.utilisateurId,
    required this.enfantsNoms,
    required this.classeNom,
    required this.matiereNom,
  });

  String? getFichierUrl() {
    final fichierId = devoirData['fichierUrl'] as String?;
    if (fichierId == null || fichierId.isEmpty) return null;
    return 'https://cloud.appwrite.io/v1/storage/buckets/6854df330032c7be516c/files/$fichierId/view?project=6853190c0001df11877c';
  }

  Future<void> _ouvrirFichier(BuildContext context) async {
    final url = getFichierUrl();
    if (url == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aucun fichier lié')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir le fichier')));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final titre = devoirData['titre'] ?? 'Sans titre';
    final description = devoirData['description'] ?? '';
    final dateRemiseTs = devoirData['dateRemise'] as Timestamp?;
    final dateCreationTs = devoirData['dateCreation'] as Timestamp?;
    final dateRemiseStr = dateRemiseTs != null
        ? DateFormat('dd/MM/yyyy').format(dateRemiseTs.toDate())
        : 'Non précisée';
    final dateCreationStr = dateCreationTs != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateCreationTs.toDate())
        : 'Non précisée';
    final enfantsStr = enfantsNoms.isEmpty ? 'Enfant(s) inconnu(s)' : enfantsNoms.join(', ');

    return Scaffold(
      appBar: AppBar(title: Text("Détail du devoir : $titre")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(titre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (description.isNotEmpty)
              Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Date de remise : $dateRemiseStr'),
            Text('Date de création : $dateCreationStr'),
            const SizedBox(height: 16),
            Text('Enfants : $enfantsStr'),
            Text('Classe : $classeNom'),
            Text('Matière : $matiereNom'),
            const SizedBox(height: 16),
            if (getFichierUrl() != null)
              ElevatedButton.icon(
                onPressed: () => _ouvrirFichier(context),
                icon: const Icon(Icons.attach_file),
                label: const Text("Ouvrir le fichier joint"),
              ),
            if (getFichierUrl() == null)
              const Text('Aucun fichier joint.'),
          ],
        ),
      ),
    );
  }
}
