import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> fetchClasseDetails() async {
    final doc = await _firestore.collection('classes').doc(widget.classeId).get();
    setState(() {
      classeData = doc.data();

      selectedMatieres = Set<String>.from(
        (classeData?['matieres'] as List<dynamic>? ?? []).map((e) => e.toString())
      );
      selectedEleves = Set<String>.from(
        (classeData?['eleves'] as List<dynamic>? ?? []).map((e) => e.toString())
      );
      selectedEnseignants = Set<String>.from(
        (classeData?['enseignants'] as List<dynamic>? ?? []).map((e) => e.toString())
      );
    });

    if (classeData != null) {
      final etablissementId = classeData!['etablissement'];
      final etabDoc = await _firestore.collection('etablissements').doc(etablissementId).get();
      setState(() {
        etablissementData = etabDoc.data();
      });
    }
  }

  Future<void> toggleElement({
    required String type,
    required String elementId,
    required bool selected,
  }) async {
    final fieldPath = type;
    final currentList = Set<String>.from(classeData?[fieldPath] as List<dynamic>? ?? []);

    if (selected) {
      currentList.add(elementId);
    } else {
      currentList.remove(elementId);
    }

    await _firestore.collection('classes').doc(widget.classeId).update({
      fieldPath: currentList.toList(),
    });

    await fetchClasseDetails();
  }

  Future<void> resetClasse() async {
    await _firestore.collection('classes').doc(widget.classeId).update({
      'matieres': [],
      'eleves': [],
      'enseignants': [],
    });

    await fetchClasseDetails();
  }

  @override
  void initState() {
    super.initState();
    fetchClasseDetails();
  }

  Widget buildElevesSection() {
    return buildListSection(
      title: "Élèves",
      collectionName: "eleves",
      selectedSet: selectedEleves,
      type: "eleves",
      showAddButton: true,
      onAddPressed: () {
        Navigator.pushNamed(context, '/ajouter-eleves', arguments: widget.classeId)
            .then((_) => fetchClasseDetails());
      },
    );
  }

  Widget buildMatieresSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Column(
        children: [
          ListTile(
            title: const Text("Matières", style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              onPressed: () => _ajouterMatiere(),
            ),
          ),
          const Divider(),
          ...selectedMatieres.map((matiereId) {
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection("matieres").doc(matiereId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                return ListTile(
                  title: Text(data?['nom'] ?? 'Sans nom'),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildEnseignantsSection() {
    return buildListSection(
      title: "Enseignants",
      collectionName: "enseignants",
      selectedSet: selectedEnseignants,
      type: "enseignants",
    );
  }

  Widget buildListSection({
    required String title,
    required String collectionName,
    required Set<String> selectedSet,
    required String type,
    bool showAddButton = false,
    VoidCallback? onAddPressed,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection(collectionName).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: Column(
            children: [
              ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: showAddButton
                    ? IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: onAddPressed,
                      )
                    : null,
              ),
              const Divider(),
              ...docs.map((doc) {
                final name = doc['nom'] ?? 'Sans nom';
                final id = doc.id;
                final isChecked = selectedSet.contains(id);

                return CheckboxListTile(
                  value: isChecked,
                  title: Text(name),
                  onChanged: (bool? val) {
                    toggleElement(
                      type: type,
                      elementId: id,
                      selected: val ?? false,
                    );
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _ajouterMatiere() async {
    String? matiereChoisie;
    String? enseignantChoisi;

    final snapshot = await _firestore.collection('matieres').get();
    final docs = snapshot.docs.where((doc) => !selectedMatieres.contains(doc.id)).toList();

    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Toutes les matières sont déjà ajoutées")));
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Ajouter une matière"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  hint: const Text("Sélectionner la matière"),
                  value: matiereChoisie,
                  isExpanded: true,
                  items: docs.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nom']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      matiereChoisie = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (matiereChoisie != null)
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('enseignants').get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();

                      final enseignants = snapshot.data!.docs;

                      return DropdownButton<String>(
                        hint: const Text("Sélectionner l'enseignant"),
                        value: enseignantChoisi,
                        isExpanded: true,
                        items: enseignants.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['nom']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            enseignantChoisi = value;
                          });
                        },
                      );
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
                      'matieres': FieldValue.arrayUnion([matiereChoisie]),
                      'enseignants': FieldValue.arrayUnion([enseignantChoisi]),
                    });
                    await fetchClasseDetails();
                    Navigator.pop(context);
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
              final confirm = await showDialog(
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
              if (confirm == true) resetClasse();
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
