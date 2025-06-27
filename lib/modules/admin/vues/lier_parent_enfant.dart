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
      final parentDoc = await FirebaseFirestore.instance.collection('parents').doc(widget.parentId).get();
      if (!parentDoc.exists) throw "Parent non trouvé";

      final utilisateurId = parentDoc.data()!['utilisateurId'] as String;
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(utilisateurId).get();
      if (!userDoc.exists) throw "Utilisateur parent non trouvé";

      etablissementId = userDoc.data()!['etablissementId'] as String?;
      if (etablissementId == null) throw "Établissement introuvable";

      final clsSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: etablissementId)
          .get();
      classes = clsSnap.docs.map((d) => ClasseModele.fromMap(d.data(), d.id)).toList();

      await _loadEleves();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> _getEleveRoleId() async {
    final roleSnap = await FirebaseFirestore.instance
        .collection('roles')
        .where('nom', isEqualTo: 'eleve')
        .limit(1)
        .get();
    if (roleSnap.docs.isNotEmpty) {
      return roleSnap.docs.first.id;
    }
    return null;
  }

  Future<void> _loadEleves() async {
    setState(() => isLoading = true);
    try {
      final roleId = await _getEleveRoleId();
      if (roleId == null) throw "Rôle 'eleve' introuvable.";

      final userSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('etablissementId', isEqualTo: etablissementId)
          .where('roleId', isEqualTo: roleId)
          .get();
      final users = userSnap.docs.map((d) => UtilisateurModele.fromMap(d.data(), d.id)).toList();
      final uIds = users.map((u) => u.id).toList();

      List<EleveModele> eModels = [];
      for (int i = 0; i < uIds.length; i += 10) {
        final batch = uIds.sublist(i, (i + 10 > uIds.length) ? uIds.length : i + 10);
        var query = FirebaseFirestore.instance
            .collection('eleves')
            .where('utilisateurId', whereIn: batch);
        if (selectedClasseId?.isNotEmpty ?? false) {
          query = query.where('classeId', isEqualTo: selectedClasseId);
        }
        final snap = await query.get();
        eModels.addAll(snap.docs.map((d) => EleveModele.fromMap(d.data(), d.id)));
      }

      elevesUtilisateurs = eModels.map((e) {
        final u = users.firstWhere((u) => u.id == e.utilisateurId, orElse: () => UtilisateurRoleEmpty());
        return EleveUtilisateur(eleve: e, utilisateur: u);
      }).toList();

      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur chargement : $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    filteredElevesUtilisateurs = elevesUtilisateurs.where((it) {
      final mS = it.utilisateur.nom.toLowerCase().contains(searchQuery) ||
          it.utilisateur.prenom.toLowerCase().contains(searchQuery);
      return mS;
    }).toList();
  }

  void _onSearchChanged(String v) {
    setState(() {
      searchQuery = v.toLowerCase();
      _applyFilters();
    });
  }

  void _onClasseChanged(String? val) {
    setState(() {
      selectedClasseId = val;
      _loadEleves(); // Recharge avec filtre
    });
  }

  Future<void> _lierParentEleve(String eleveDocId) async {
    try {
      // eleveDocId est l'id du document 'eleves', pas de l'utilisateur
      await _depotFamille.ajouterRelation(widget.parentId, eleveDocId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enfant lié ✅")));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur liaison : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lier un enfant"), backgroundColor: Colors.blueAccent),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Rechercher (nom/prénom)",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedClasseId == null || selectedClasseId == '' ? null : selectedClasseId,
                    decoration: InputDecoration(
                      labelText: "Classe (optionnel)",
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text("Toutes")),
                      ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))),
                    ],
                    onChanged: _onClasseChanged,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: filteredElevesUtilisateurs.isEmpty
                        ? Center(child: Text("Aucun élève trouvé."))
                        : ListView.builder(
                            itemCount: filteredElevesUtilisateurs.length,
                            itemBuilder: (_, i) {
                              final it = filteredElevesUtilisateurs[i];
                              final cn = classes.firstWhere(
                                (c) => c.id == it.eleve.classeId,
                                orElse: () => ClasseModele(id: "", nom: "Inconnue", niveau: "", matieresIds: [], elevesIds: []),
                              ).nom;

                              return ListTile(
                                title: Text("${it.utilisateur.nom} ${it.utilisateur.prenom}"),
                                subtitle: Text("Classe : $cn"),
                                // <-- ici on passe l'id du document eleve (it.eleve.id) et non utilisateur.id
                                trailing: ElevatedButton(
                                  onPressed: () => _lierParentEleve(it.eleve.id),
                                  child: Text("Lier"),
                                ),
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

class UtilisateurRoleEmpty extends UtilisateurModele {
  UtilisateurRoleEmpty()
      : super(
          id: '',
          nom: '',
          prenom: '',
          email: '',
          numeroTelephone: '',
          adresse: '',
          motDePasse: '',
          statut: false,
          roleId: '',
          etablissementId: '',
          photo: null,
        );
}
