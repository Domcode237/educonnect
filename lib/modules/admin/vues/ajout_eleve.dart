import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjouterElevesClassePage extends StatefulWidget {
  final String classeId;

  const AjouterElevesClassePage({super.key, required this.classeId});

  @override
  State<AjouterElevesClassePage> createState() => _AjouterElevesClassePageState();
}

class _AjouterElevesClassePageState extends State<AjouterElevesClassePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? classeData;
  String? etablissementId;
  Set<String> selectedEleves = {};

  @override
  void initState() {
    super.initState();
    fetchClasseData();
  }

  Future<void> fetchClasseData() async {
    final doc = await _firestore.collection('classes').doc(widget.classeId).get();
    setState(() {
      classeData = doc.data();
      etablissementId = classeData?['etablissement'];
    });
  }

  Future<List<QueryDocumentSnapshot>> fetchEligibleEleves() async {
    if (etablissementId == null) return [];

    final elevesSnapshot = await _firestore
        .collection('eleves')
        .where('etablissement', isEqualTo: etablissementId)
        .where('classe', isNull: true)
        .get();

    return elevesSnapshot.docs;
  }

  Future<void> ajouterEleves() async {
    if (selectedEleves.isEmpty) return;

    final batch = _firestore.batch();

    // Mise à jour de chaque élève avec l'ID de la classe
    for (var eleveId in selectedEleves) {
      final eleveRef = _firestore.collection('eleves').doc(eleveId);
      batch.update(eleveRef, {'classe': widget.classeId});
    }

    // Mise à jour de la liste d'élèves de la classe
    final classeRef = _firestore.collection('classes').doc(widget.classeId);
    final classeSnapshot = await classeRef.get();
    final currentEleves = List<String>.from(classeSnapshot.data()?['eleves'] ?? []);
    final newEleves = [...currentEleves, ...selectedEleves];

    batch.update(classeRef, {'eleves': newEleves});

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Élèves ajoutés avec succès")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (classeData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter des élèves"),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: fetchEligibleEleves(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final eleves = snapshot.data!;

          if (eleves.isEmpty) {
            return const Center(child: Text("Aucun élève disponible à ajouter"));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: eleves.length,
                  itemBuilder: (context, index) {
                    final eleve = eleves[index];
                    final eleveId = eleve.id;
                    final nom = eleve['nom'] ?? 'Sans nom';

                    return CheckboxListTile(
                      value: selectedEleves.contains(eleveId),
                      title: Text(nom),
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            selectedEleves.add(eleveId);
                          } else {
                            selectedEleves.remove(eleveId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: selectedEleves.isEmpty ? null : ajouterEleves,
                  icon: const Icon(Icons.check),
                  label: const Text("Valider les modifications"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.blue,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
