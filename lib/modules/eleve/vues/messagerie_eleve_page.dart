import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/EnseignantModele.dart';
import 'page_message_detail.dart';
import 'package:educonnect/main.dart';

class ClasseModele {
  final String id;
  final String nom;
  final List<String> enseignantsIds;

  ClasseModele({
    required this.id,
    required this.nom,
    required this.enseignantsIds,
  });

  factory ClasseModele.fromMap(String id, Map<String, dynamic> data) {
    return ClasseModele(
      id: id,
      nom: data['nom'] ?? 'Classe',
      enseignantsIds: List<String>.from(data['enseignantsIds'] ?? []),
    );
  }
}

class MessagerieElevePage extends StatefulWidget {
  final String utilisateurId;
  final String etablissementId;
  final String eleveId;

  const MessagerieElevePage({
    Key? key,
    required this.utilisateurId,
    required this.etablissementId,
    required this.eleveId,
  }) : super(key: key);

  @override
  State<MessagerieElevePage> createState() => _MessagerieElevePageState();
}

class _MessagerieElevePageState extends State<MessagerieElevePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, UtilisateurModele> utilisateursMap = {};
  Map<String, List<String>> matieresParEnseignant = {};
  List<EnseignantModele> enseignants = [];
  List<ClasseModele> classes = [];

  bool isLoading = true;
  String? error;

  String searchQuery = '';
  String? selectedClasseId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final enseignantsSnapshot = await _firestore.collection('enseignants').get();
      enseignants = enseignantsSnapshot.docs
          .map((doc) => EnseignantModele.fromMap(doc.data(), doc.id))
          .toList();

      final utilisateurIds = enseignants.map((e) => e.utilisateurId).toSet().toList();

      final utilisateursSnapshot = await _firestore
          .collection('utilisateurs')
          .where(FieldPath.documentId, whereIn: utilisateurIds)
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      utilisateursMap = {
        for (var doc in utilisateursSnapshot.docs)
          doc.id: UtilisateurModele.fromMap(doc.data(), doc.id)
      };

      enseignants = enseignants.where((e) => utilisateursMap.containsKey(e.utilisateurId)).toList();

      await _loadMatieres();
      await _loadClasses();

      setState(() => isLoading = false);
    } catch (e, st) {
      print('❌ Erreur chargement init : $e\n$st');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadMatieres() async {
    final enseignantIds = enseignants.map((e) => e.id).toList();
    if (enseignantIds.isEmpty) return;

    final enseignementsSnapshot = await _firestore
        .collection('enseignements')
        .where('enseignantId', whereIn: enseignantIds)
        .get();

    final matiereIds = enseignementsSnapshot.docs
        .map((doc) => doc.data()['matiereId'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final matieresSnapshot = await _firestore
        .collection('matieres')
        .where(FieldPath.documentId, whereIn: matiereIds)
        .get();

    final matieresMap = {
      for (var doc in matieresSnapshot.docs)
        doc.id: (doc.data()['nom'] ?? 'Inconnu') as String
    };

    final mapTemp = <String, List<String>>{};
    for (var doc in enseignementsSnapshot.docs) {
      final data = doc.data();
      final enseignantId = data['enseignantId'];
      final matiereId = data['matiereId'];
      if (enseignantId == null || matiereId == null) continue;

      final matiereNom = matieresMap[matiereId] ?? 'Inconnu';
      mapTemp.putIfAbsent(enseignantId, () => []).add(matiereNom);
    }

    matieresParEnseignant = mapTemp;
  }

  Future<void> _loadClasses() async {
    final classesSnapshot = await _firestore
        .collection('classes')
        .where('etablissementId', isEqualTo: widget.etablissementId)
        .get();

    classes = classesSnapshot.docs
        .map((doc) => ClasseModele.fromMap(doc.id, doc.data()))
        .toList();
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text("Erreur : $error")));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Recherche enseignant...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => searchQuery = v),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: classes.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('Toutes'),
                        selected: selectedClasseId == null,
                        onSelected: (_) => setState(() => selectedClasseId = null),
                      ),
                    );
                  }
                  final cl = classes[i - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cl.nom),
                      selected: selectedClasseId == cl.id,
                      onSelected: (_) => setState(() => selectedClasseId = cl.id),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .where('participants', arrayContains: widget.eleveId)
                    .orderBy('dateEnvoi', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  final Map<String, Map<String, dynamic>> dernierMessage = {};
                  final Map<String, int> nbMessagesNonLus = {};

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final emetteurId = data['emetteurId'] ?? '';
                    final recepteurId = data['recepteurId'] ?? '';
                    final date = (data['dateEnvoi'] as Timestamp?)?.toDate();
                    final message = data['contenu'] ?? '';
                    final lu = data['lu'] ?? true;

                    final autreId = emetteurId == widget.eleveId ? recepteurId : emetteurId;

                    if (!enseignants.any((e) => e.id == autreId)) continue;

                    if (dernierMessage[autreId] == null ||
                        (date != null &&
                            date.isAfter(dernierMessage[autreId]?['date'] ?? DateTime(0)))) {
                      dernierMessage[autreId] = {'message': message, 'date': date};
                    }

                    if (recepteurId == widget.eleveId && !lu) {
                      nbMessagesNonLus[autreId] = (nbMessagesNonLus[autreId] ?? 0) + 1;
                    }
                  }

                  var enseignantsFiltres = enseignants.where((e) {
                    final utilisateur = utilisateursMap[e.utilisateurId];
                    if (utilisateur == null) return false;

                    final matchesSearch = '${utilisateur.prenom} ${utilisateur.nom}'
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());

                    final matchesClasse = selectedClasseId == null ||
                        classes
                            .firstWhere((c) => c.id == selectedClasseId!)
                            .enseignantsIds
                            .contains(e.id);

                    return matchesSearch && matchesClasse;
                  }).toList();

                  enseignantsFiltres.sort((a, b) {
                    final dateA = dernierMessage[a.id]?['date'] ?? DateTime(2000);
                    final dateB = dernierMessage[b.id]?['date'] ?? DateTime(2000);
                    return dateB.compareTo(dateA);
                  });

                  if (enseignantsFiltres.isEmpty) {
                    return const Center(child: Text("Aucun message trouvé"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: enseignantsFiltres.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final enseignant = enseignantsFiltres[index];
                      final utilisateur = utilisateursMap[enseignant.utilisateurId];
                      if (utilisateur == null) return const SizedBox();

                      final matieres = matieresParEnseignant[enseignant.id] ?? [];
                      final photoUrl = _getAppwriteImageUrl(utilisateur.photo);
                      final statutColor = utilisateur.statut ? Colors.green : Colors.grey;
                      final message = dernierMessage[enseignant.id]?['message'] ?? 'Aucun message';
                      final nbNonLus = nbMessagesNonLus[enseignant.id] ?? 0;

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PageMessageDetailEleve(
                                eleveId: widget.eleveId,
                                enseignantId: enseignant.id,
                                enseignantNom: '${utilisateur.prenom} ${utilisateur.nom}',
                                enseignantPhotoFileId: utilisateur.photo,
                              ),
                            ),
                          );
                        },
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  photoUrl != null ? NetworkImage(photoUrl) : null,
                              backgroundColor: Colors.grey.shade300,
                              child: photoUrl == null
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: statutColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            )
                          ],
                        ),
                        title: Text('${utilisateur.prenom} ${utilisateur.nom}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (matieres.isNotEmpty)
                              Text("Matières : ${matieres.join(', ')}",
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: nbNonLus > 0
                            ? CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '$nbNonLus',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
