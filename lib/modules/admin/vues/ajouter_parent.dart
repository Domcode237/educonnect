import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'package:educonnect/donnees/depots/DepotParent.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';

class AjouterParentPage extends StatefulWidget {
  final String etablissementId;

  const AjouterParentPage({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<AjouterParentPage> createState() => _AjouterParentPageState();
}

class _AjouterParentPageState extends State<AjouterParentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DepotParent _depotParent;
  final _formKey = GlobalKey<FormState>();

  String? nom, prenom, email, numeroTelephone, adresse, motDePasse;
  List<ClasseModele> classesDisponibles = [];
  ClasseModele? classeSelectionnee;

  List<QueryDocumentSnapshot> elevesDisponibles = [];
  String? eleveSelectionne;

  String? roleParentId, roleEleveId;
  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    chargerDonneesInitiales();
  }

  Future<void> chargerDonneesInitiales() async {
    try {
      final roleParentSnap = await _firestore.collection('roles').where('nom', isEqualTo: 'parent').limit(1).get();
      if (roleParentSnap.docs.isEmpty) {
        _showSnackBar("Rôle 'parent' introuvable.");
        return;
      }
      roleParentId = roleParentSnap.docs.first.id;
      _depotParent = DepotParent(roleParentId!);

      final roleEleveSnap = await _firestore.collection('roles').where('nom', isEqualTo: 'eleve').limit(1).get();
      if (roleEleveSnap.docs.isEmpty) {
        _showSnackBar("Rôle 'élève' introuvable.");
        return;
      }
      roleEleveId = roleEleveSnap.docs.first.id;

      final classesSnap = await _firestore.collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      setState(() {
        classesDisponibles = classesSnap.docs.map((doc) => ClasseModele.fromMap(doc.data(), doc.id)).toList();
      });
    } catch (e) {
      _showSnackBar("Erreur lors du chargement : $e");
    }
  }

  // *** MODIFICATION ICI : filtre direct par classeId ***
  Future<void> chargerElevesDeClasse(ClasseModele classe) async {
    try {
      final elevesSnap = await _firestore.collection('utilisateurs')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .where('classeId', isEqualTo: classe.id)
          .where('roleId', isEqualTo: roleEleveId)
          .get();

      setState(() {
        elevesDisponibles = elevesSnap.docs;
        eleveSelectionne = null;
      });
    } catch (e) {
      _showSnackBar("Erreur lors du chargement des élèves : $e");
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> ajouterParent() async {
    if (!_formKey.currentState!.validate()) return;
    if (eleveSelectionne == null) {
      _showSnackBar("Veuillez sélectionner un enfant");
      return;
    }
    if (roleParentId == null) {
      _showSnackBar("Impossible d'ajouter le parent.");
      return;
    }

    _formKey.currentState!.save();
    setState(() => _chargement = true);

    try {
      final utilisateurDoc = _firestore.collection('utilisateurs').doc();

      final utilisateur = UtilisateurModele(
        id: utilisateurDoc.id,
        nom: nom!,
        prenom: prenom!,
        email: email!,
        numeroTelephone: numeroTelephone ?? '',
        adresse: adresse ?? '',
        motDePasse: motDePasse ?? '',
        statut: true,
        roleId: roleParentId!,
        etablissementId: widget.etablissementId,
      );

      final parent = ParentModele(
        id: utilisateur.id,
        utilisateur: utilisateur,
        enfants: [eleveSelectionne!],
      );

      await _depotParent.ajouterParent(parent);
      await _firestore.collection('eleves').doc(eleveSelectionne!).update({'parent': utilisateur.id});

      _showSnackBar("Parent ajouté avec succès");
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Erreur lors de l'ajout : $e");
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (roleParentId == null || roleEleveId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un parent")),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField("Nom", (v) => nom = v),
                    _buildTextField("Prénom", (v) => prenom = v),
                    _buildTextField("Email", (v) => email = v, type: TextInputType.emailAddress, isEmail: true),
                    _buildTextField("Numéro de téléphone", (v) => numeroTelephone = v, type: TextInputType.phone),
                    _buildTextField("Adresse", (v) => adresse = v),
                    _buildTextField("Mot de passe", (v) => motDePasse = v, isPassword: true),

                    const SizedBox(height: 20),

                    const Text('Sélectionner une classe :', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<ClasseModele>(
                      items: classesDisponibles.map((classe) {
                        return DropdownMenuItem(
                          value: classe,
                          child: Text("${classe.niveau} - ${classe.nom}"),
                        );
                      }).toList(),
                      value: classeSelectionnee,
                      onChanged: (val) {
                        setState(() {
                          classeSelectionnee = val;
                        });
                        if (val != null) {
                          chargerElevesDeClasse(val);
                        }
                      },
                      validator: (v) => v == null ? 'Sélection obligatoire' : null,
                    ),

                    const SizedBox(height: 20),

                    const Text('Sélectionner un enfant :', style: TextStyle(fontWeight: FontWeight.bold)),
                    elevesDisponibles.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Aucun enfant disponible pour cette classe'),
                          )
                        : DropdownButtonFormField<String>(
                            items: elevesDisponibles.map((doc) {
                              final nomEleve = "${doc['nom']} ${doc['prenom']}";
                              return DropdownMenuItem(value: doc.id, child: Text(nomEleve));
                            }).toList(),
                            value: eleveSelectionne,
                            onChanged: (val) => setState(() => eleveSelectionne = val),
                            validator: (v) => v == null ? 'Sélection obligatoire' : null,
                          ),

                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: ajouterParent,
                      icon: const Icon(Icons.save),
                      label: const Text("Ajouter le parent"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved,
      {TextInputType type = TextInputType.text, bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        keyboardType: type,
        obscureText: isPassword,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Obligatoire';
          if (isEmail && !v.contains('@')) return 'Email invalide';
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }
}
