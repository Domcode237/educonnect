import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';
import 'package:educonnect/donnees/depots/depos_famille.dart';

class EleveUtilisateur {
  final EleveModele eleve;
  final UtilisateurModele utilisateur;

  EleveUtilisateur({required this.eleve, required this.utilisateur});
}

class LierParentEnfantVue extends StatefulWidget {
  final String parentId;

  const LierParentEnfantVue({Key? key, required this.parentId}) : super(key: key);

  @override
  State<LierParentEnfantVue> createState() => _LierParentEnfantVueState();
}

class _LierParentEnfantVueState extends State<LierParentEnfantVue> {
  final DepotFamille _depotFamille = DepotFamille();

  List<ClasseModele> classes = [];
  String? selectedClasseId;

  List<UtilisateurModele> utilisateursEleves = [];
  List<EleveModele> elevesModele = [];
  List<EleveUtilisateur> elevesUtilisateurs = [];
  List<EleveUtilisateur> filteredElevesUtilisateurs = [];

  String searchQuery = '';

  bool isLoading = true;
  String? etablissementId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      // 1. Récupérer parent et utilisateur pour avoir etablissementId
      final parentDoc = await FirebaseFirestore.instance.collection('parents').doc(widget.parentId).get();
      if (!parentDoc.exists) throw Exception("Parent non trouvé");

      final parentData = parentDoc.data()!;
      final utilisateurId = parentData['utilisateurId'] as String;

      final utilisateurDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(utilisateurId).get();
      if (!utilisateurDoc.exists) throw Exception("Utilisateur parent non trouvé");

      final utilisateurData = utilisateurDoc.data()!;
      etablissementId = utilisateurData['etablissementId'] as String?;

      if (etablissementId == null) throw Exception("EtablissementId introuvable");

      // 2. Charger classes de l'établissement
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: etablissementId)
          .get();

      classes = classesSnapshot.docs
          .map((doc) => ClasseModele.fromMap(doc.data(), doc.id))
          .toList();

      // 3. Charger utilisateurs ayant rôle 'eleve' et etablissementId donné
      final utilisateursSnapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('etablissementId', isEqualTo: etablissementId)
          .where('roleId', isEqualTo: 'eleve')
          .get();

      utilisateursEleves = utilisateursSnapshot.docs
          .map((doc) => UtilisateurModele.fromMap(doc.data(), doc.id))
          .toList();

      // 4. Charger Eleves (EleveModele) avec utilisateurId dans la liste des utilisateurs chargés
      List<String> utilisateurIds = utilisateursEleves.map((u) => u.id).toList();

      elevesModele = [];

      // Firestore whereIn supporte max 10 éléments donc batch
      for (int i = 0; i < utilisateurIds.length; i += 10) {
        final batch = utilisateurIds.sublist(i, (i + 10) > utilisateurIds.length ? utilisateurIds.length : i + 10);
        final elevesSnapshot = await FirebaseFirestore.instance
            .collection('eleves')
            .where('utilisateurId', whereIn: batch)
            .get();

        elevesModele.addAll(elevesSnapshot.docs.map((doc) => EleveModele.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      // 5. Faire la jointure Eleve - Utilisateur
      elevesUtilisateurs = elevesModele.map((eleve) {
        final utilisateur = utilisateursEleves.firstWhere((u) => u.id == eleve.utilisateurId, orElse: () => UtilisateurModele.empty());
        return EleveUtilisateur(eleve: eleve, utilisateur: utilisateur);
      }).toList();

      _applyFilters();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement : $e")),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      filteredElevesUtilisateurs = elevesUtilisateurs.where((item) {
        final classeMatch = selectedClasseId == null || selectedClasseId!.isEmpty || item.eleve.classeId == selectedClasseId;
        final searchMatch = searchQuery.isEmpty ||
            item.utilisateur.nom.toLowerCase().contains(searchQuery) ||
            item.utilisateur.prenom.toLowerCase().contains(searchQuery);
        return classeMatch && searchMatch;
      }).toList();
    });
  }

  void _onSearchChanged(String val) {
    searchQuery = val.toLowerCase();
    _applyFilters();
  }

  void _onClasseChanged(String? val) {
    selectedClasseId = val;
    _applyFilters();
  }

  Future<void> _lierParentEleve(String eleveUtilisateurId) async {
    try {
      await _depotFamille.ajouterRelation(widget.parentId, eleveUtilisateurId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Relation parent-enfant créée avec succès !")),
      );
      Navigator.of(context).pop(); // Retour à la page précédente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la liaison : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lier un enfant au parent"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Recherche avec auto-complétion
                  Autocomplete<EleveUtilisateur>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<EleveUtilisateur>.empty();
                      final query = textEditingValue.text.toLowerCase();
                      return filteredElevesUtilisateurs.where((item) =>
                          item.utilisateur.nom.toLowerCase().startsWith(query) ||
                          item.utilisateur.prenom.toLowerCase().startsWith(query));
                    },
                    displayStringForOption: (EleveUtilisateur option) => "${option.utilisateur.nom} ${option.utilisateur.prenom}",
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Rechercher un élève",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: _onSearchChanged,
                      );
                    },
                    onSelected: (EleveUtilisateur selection) {
                      _lierParentEleve(selection.utilisateur.id);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Filtre par classe
                  DropdownButtonFormField<String>(
                    value: selectedClasseId,
                    decoration: InputDecoration(
                      labelText: "Filtrer par classe",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.class_),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Toutes les classes")),
                      ...classes.map((classe) => DropdownMenuItem(
                            value: classe.id,
                            child: Text(classe.nom),
                          )),
                    ],
                    onChanged: _onClasseChanged,
                  ),

                  const SizedBox(height: 20),

                  // Liste élèves filtrés
                  Expanded(
                    child: filteredElevesUtilisateurs.isEmpty
                        ? const Center(child: Text("Aucun élève trouvé avec ces critères"))
                        : ListView.builder(
                            itemCount: filteredElevesUtilisateurs.length,
                            itemBuilder: (context, index) {
                              final item = filteredElevesUtilisateurs[index];
                              final classeNom = classes
                                      .firstWhere(
                                        (c) => c.id == item.eleve.classeId,
                                        orElse: () => ClasseModele(id: '', nom: 'Inconnue', niveau: '', matieresIds: [], elevesIds: []),
                                      )
                                      .nom;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text("${item.utilisateur.nom} ${item.utilisateur.prenom}"),
                                  subtitle: Text("Classe : $classeNom"),
                                  trailing: ElevatedButton(
                                    child: const Text("Lier"),
                                    onPressed: () => _lierParentEleve(item.utilisateur.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

extension on UtilisateurModele {
  /// Pour gérer le cas où aucun utilisateur n'est trouvé dans la jointure
  static UtilisateurModele empty() => UtilisateurModele(
        id: '',
        nom: '',
        prenom: '',
        email: '',
        numeroTelephone: '',
        adresse: '',
        motDePasse: '', // <-- ajouté ici
        statut: false,
        roleId: '',
        etablissementId: '',
        photo: null,  // optionnel, car nullable
      );
}