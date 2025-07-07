import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

// Importe le client Appwrite global pour récupérer l’endpoint et projectId
import 'package:educonnect/main.dart';

class ClasseDetailPage extends StatefulWidget {
  final String classeId;

  const ClasseDetailPage({required this.classeId, super.key});

  @override
  State<ClasseDetailPage> createState() => _ClasseDetailPageState();
}

class _ClasseDetailPageState extends State<ClasseDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? classeData;
  Map<String, dynamic>? etablissementData;

  Set<String> selectedMatieres = {};
  Set<String> selectedEleves = {};
  Set<String> selectedEnseignants = {};

  List<Map<String, dynamic>> elevesDetails = [];
  List<Map<String, dynamic>> enseignantsDetails = [];
  bool loadingEleves = false;
  bool loadingEnseignants = false;

  // Etats d'expansion pour les sections
  bool elevesExpanded = true;
  bool matieresExpanded = true;
  bool enseignantsExpanded = true;

  @override
  void initState() {
    super.initState();
    fetchClasseDetails();
  }

  Future<void> fetchClasseDetails() async {
    try {
      final doc = await _firestore.collection('classes').doc(widget.classeId).get();
      final data = doc.data();
      if (data == null) {
        setState(() {
          classeData = null;
          selectedMatieres.clear();
          selectedEleves.clear();
          selectedEnseignants.clear();
          elevesDetails.clear();
          enseignantsDetails.clear();
        });
        return;
      }

      setState(() {
        classeData = data;
        selectedMatieres = Set<String>.from(
          (data['matieresIds'] as List<dynamic>? ?? []).map((e) => e.toString()),
        );
        selectedEleves = Set<String>.from(
          (data['elevesIds'] as List<dynamic>? ?? []).map((e) => e.toString()),
        );
        selectedEnseignants = Set<String>.from(
          (data['enseignantsIds'] as List<dynamic>? ?? []).map((e) => e.toString()),
        );
      });

      await fetchEtablissement();
      await fetchElevesDetails();
      await fetchEnseignantsDetails();
    } catch (e) {
      debugPrint('Erreur fetchClasseDetails: $e');
    }
  }

  Future<void> fetchEtablissement() async {
    if (classeData == null) return;
    final etablissementId = classeData!['etablissementId'] as String?;
    if (etablissementId == null || etablissementId.isEmpty) return;

    try {
      final etabDoc = await _firestore.collection('etablissements').doc(etablissementId).get();
      setState(() {
        etablissementData = etabDoc.data();
      });
    } catch (e) {
      debugPrint('Erreur fetchEtablissement: $e');
    }
  }

  Future<void> fetchElevesDetails() async {
    if (classeData == null) return;
    setState(() => loadingEleves = true);

    try {
      final elevesIds = classeData?['elevesIds'] ?? [];
      List<Map<String, dynamic>> tempList = [];

      for (final eleveId in elevesIds.cast<String>()) {
        final eleveDoc = await _firestore.collection('eleves').doc(eleveId).get();
        if (!eleveDoc.exists) continue;

        final eleveData = eleveDoc.data()!;
        final utilisateurId = eleveData['utilisateurId'] as String?;
        if (utilisateurId == null || utilisateurId.isEmpty) continue;

        final utilisateurDoc = await _firestore.collection('utilisateurs').doc(utilisateurId).get();
        if (!utilisateurDoc.exists) continue;

        final utilisateurData = utilisateurDoc.data()!;
        tempList.add({
          'eleveId': eleveId,
          'utilisateurId': utilisateurId,
          'nom': utilisateurData['nom'] ?? '',
          'prenom': utilisateurData['prenom'] ?? '',
          'email': utilisateurData['email'] ?? '',
          'photo': utilisateurData['photo'] ?? '',
        });
      }

      setState(() {
        elevesDetails = tempList;
      });
    } catch (e) {
      debugPrint('Erreur fetchElevesDetails: $e');
    } finally {
      setState(() => loadingEleves = false);
    }
  }

  Future<void> fetchEnseignantsDetails() async {
    if (classeData == null) return;
    setState(() => loadingEnseignants = true);

    try {
      final enseignantsIds = classeData?['enseignantsIds'] ?? [];
      List<Map<String, dynamic>> tempList = [];

      for (final enseignantId in enseignantsIds.cast<String>()) {
        final enseignantDoc = await _firestore.collection('enseignants').doc(enseignantId).get();
        if (!enseignantDoc.exists) continue;

        final enseignantData = enseignantDoc.data()!;
        final utilisateurId = enseignantData['utilisateurId'] as String?;
        if (utilisateurId == null || utilisateurId.isEmpty) continue;

        final utilisateurDoc = await _firestore.collection('utilisateurs').doc(utilisateurId).get();
        if (!utilisateurDoc.exists) continue;

        final utilisateurData = utilisateurDoc.data()!;
        tempList.add({
          'enseignantId': enseignantId,
          'utilisateurId': utilisateurId,
          'nom': utilisateurData['nom'] ?? '',
          'prenom': utilisateurData['prenom'] ?? '',
          'email': utilisateurData['email'] ?? '',
          'photo': utilisateurData['photo'] ?? '',
        });
      }

      setState(() {
        enseignantsDetails = tempList;
      });
    } catch (e) {
      debugPrint('Erreur fetchEnseignantsDetails: $e');
    } finally {
      setState(() => loadingEnseignants = false);
    }
  }

  Future<void> toggleElement({
    required String type,
    required String elementId,
    required bool selected,
  }) async {
    if (classeData == null) return;

    final currentList = Set<String>.from(classeData?[type] as List<dynamic>? ?? []);

    if (selected) {
      currentList.add(elementId);
    } else {
      currentList.remove(elementId);
    }

    try {
      await _firestore.collection('classes').doc(widget.classeId).update({
        type: currentList.toList(),
      });
      await fetchClasseDetails();
    } catch (e) {
      debugPrint('Erreur toggleElement: $e');
    }
  }

  Future<void> resetClasse() async {
    try {
      await _firestore.collection('classes').doc(widget.classeId).update({
        'matieresIds': [],
        'elevesIds': [],
        'enseignantsIds': [],
      });
      await fetchClasseDetails();
    } catch (e) {
      debugPrint('Erreur resetClasse: $e');
    }
  }

  /// Construis l’URL Appwrite de la photo depuis son fileId
  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  Widget buildElevesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: ExpansionTile(
        initiallyExpanded: elevesExpanded,
        onExpansionChanged: (expanded) => setState(() => elevesExpanded = expanded),
        title: const Text("Élèves", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          const Divider(),
          if (loadingEleves)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (elevesDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Aucun élève dans cette classe."),
            )
          else
            ...elevesDetails.map((eleve) {
            final photoUrl = _getAppwriteImageUrl(eleve['photo']);
            return ListTile(
              leading: (photoUrl != null)
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(photoUrl),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${eleve['prenom']} ${eleve['nom']}'),
              subtitle: Text(eleve['email']),
            );
          }),
        ],
      ),
    );
  }

  Widget buildMatieresSection() {
    final etablissementId = classeData?['etablissementId'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: ExpansionTile(
        initiallyExpanded: matieresExpanded,
        onExpansionChanged: (expanded) => setState(() => matieresExpanded = expanded),
        title: ListTile(
          title: const Text("Matières", style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            onPressed: () => _ajouterMatiere(etablissementId),
          ),
        ),
        children: [
          const Divider(),
          ...selectedMatieres.map((matiereId) {
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection("matieres").doc(matiereId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const ListTile(title: Text("Matière non trouvée"));
                }
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                return ListTile(
                  title: Text(data['nom'] ?? 'Sans nom'),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget buildEnseignantsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: ExpansionTile(
        initiallyExpanded: enseignantsExpanded,
        onExpansionChanged: (expanded) => setState(() => enseignantsExpanded = expanded),
        title: const Text("Enseignants", style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          const Divider(),
          if (loadingEnseignants)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (enseignantsDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Aucun enseignant sélectionné."),
            )
          else
            ...enseignantsDetails.map((enseignant) {
            final photoUrl = _getAppwriteImageUrl(enseignant['photo']);
            return ListTile(
              leading: (photoUrl != null)
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(photoUrl),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${enseignant['prenom']} ${enseignant['nom']}'),
              subtitle: Text(enseignant['email']),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _ajouterMatiere(String? etablissementId) async {
    if (etablissementId == null || etablissementId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible de récupérer l'établissement.")));
      return;
    }

    String? matiereChoisie;
    String? enseignantChoisi;
    List<Map<String, String>> enseignantsDisponibles = [];

    // Récupérer uniquement matières liées à cet établissement
    final matieresSnap = await _firestore
        .collection('matieres')
        .where('etablissementId', isEqualTo: etablissementId)
        .get();
    // Filtrer matières non encore sélectionnées
    final matieresDisponibles = matieresSnap.docs.where((doc) => !selectedMatieres.contains(doc.id)).toList();

    if (matieresDisponibles.isEmpty) {
          if (!mounted) return;  // Ajoute cette vérification avant d'utiliser context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Toutes les matières sont déjà ajoutées"))
          );
          return;
        }


    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          Future<void> loadEnseignants(String matiereId) async {
            enseignantsDisponibles.clear();
            enseignantChoisi = null;

            try {
              // 1. Récupérer les enseignements liés à la matière
              final enseignementsSnap = await _firestore
                  .collection('enseignements')
                  .where('matiereId', isEqualTo: matiereId)
                  .get();

              if (enseignementsSnap.docs.isEmpty) {
                setState(() {
                  enseignantsDisponibles = [];
                });
                return;
              }

              // 2. Extraire les IDs des enseignants
              final enseignantIds = enseignementsSnap.docs
                  .map((doc) => doc['enseignantId'] as String)
                  .where((id) => id.isNotEmpty)
                  .toSet() // pour éviter doublons
                  .toList();

              if (enseignantIds.isEmpty) {
                setState(() {
                  enseignantsDisponibles = [];
                });
                return;
              }

              // 3. Récupérer les enseignants correspondants
              final enseignantsSnap = await _firestore
                  .collection('enseignants')
                  .where(FieldPath.documentId, whereIn: enseignantIds)
                  .get();

              if (enseignantsSnap.docs.isEmpty) {
                setState(() {
                  enseignantsDisponibles = [];
                });
                return;
              }

              // 4. Extraire les utilisateurIds des enseignants
              final utilisateurIds = enseignantsSnap.docs
                  .map((doc) => doc['utilisateurId'] as String)
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();

              if (utilisateurIds.isEmpty) {
                setState(() {
                  enseignantsDisponibles = [];
                });
                return;
              }

              // 5. Récupérer les utilisateurs correspondants
              final utilisateursSnap = await _firestore
                  .collection('utilisateurs')
                  .where(FieldPath.documentId, whereIn: utilisateurIds)
                  .get();

              if (utilisateursSnap.docs.isEmpty) {
                setState(() {
                  enseignantsDisponibles = [];
                });
                return;
              }

              // 6. Construire une map utilisateurId -> UtilisateurModele
              final Map<String, UtilisateurModele> utilisateursMap = {
                for (var doc in utilisateursSnap.docs)
                  doc.id: UtilisateurModele.fromMap(doc.data(), doc.id),
              };

              // 7. Construire la liste finale enseignantsDisponibles
              List<Map<String, String>> liste = [];

              for (var enseignantDoc in enseignantsSnap.docs) {
                final enseignantId = enseignantDoc.id;
                final utilisateurId = enseignantDoc['utilisateurId'] as String;

                final utilisateur = utilisateursMap[utilisateurId];
                if (utilisateur != null) {
                  final nomComplet = '${utilisateur.prenom} ${utilisateur.nom}';
                  liste.add({'id': enseignantId, 'nom': nomComplet});
                } else {
                  liste.add({'id': enseignantId, 'nom': 'Nom inconnu'});
                }
              }

              setState(() {
                enseignantsDisponibles = liste;
              });
            } catch (e) {
              debugPrint("Erreur loadEnseignants: $e");
              setState(() {
                enseignantsDisponibles = [];
              });
            }
          }

          return AlertDialog(
            title: const Text("Ajouter une matière"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  hint: const Text("Sélectionner la matière"),
                  value: matiereChoisie,
                  isExpanded: true,
                  items: matieresDisponibles.map((doc) {
                    final data = doc.data();
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['nom'] ?? 'Sans nom'),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      matiereChoisie = value;
                      enseignantChoisi = null;
                      enseignantsDisponibles = [];
                    });
                    if (value != null) {
                      await loadEnseignants(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (matiereChoisie != null)
                  enseignantsDisponibles.isEmpty
                      ? const Text("Aucun enseignant pour cette matière.")
                      : DropdownButton<String>(
                          hint: const Text("Sélectionner l'enseignant"),
                          value: enseignantChoisi,
                          isExpanded: true,
                          items: enseignantsDisponibles.map((e) {
                            return DropdownMenuItem(
                              value: e['id'],
                              child: Text(e['nom'] ?? 'Sans nom'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              enseignantChoisi = value;
                            });
                          },
                        ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
              ElevatedButton(
                onPressed: () async {
                  if (matiereChoisie != null && enseignantChoisi != null) {
                    await _firestore.collection('classes').doc(widget.classeId).update({
                      'matieresIds': FieldValue.arrayUnion([matiereChoisie]),
                      'enseignantsIds': FieldValue.arrayUnion([enseignantChoisi]),
                    });
                    await fetchClasseDetails();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez sélectionner une matière et un enseignant")),
                    );
                  }
                },
                child: const Text("Valider"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (classeData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nomClasse = classeData?['nom'] ?? '';
    final niveau = classeData?['niveau'] ?? '';
    final nomEtablissement = etablissementData?['nom'] ?? 'Chargement...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la classe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: "Réinitialiser la classe",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmer la réinitialisation"),
                  content: const Text("Voulez-vous vraiment vider toutes les listes ?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirmer")),
                  ],
                ),
              );
              if (confirm == true) await resetClasse();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchClasseDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Établissement : $nomEtablissement", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text("Classe : $nomClasse ($niveau)", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              buildElevesSection(),
              buildMatieresSection(),
              buildEnseignantsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
