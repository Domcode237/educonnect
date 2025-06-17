import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';

class ModifierParent extends StatefulWidget {
  final String parentId;
  final String etablissementId;

  const ModifierParent({Key? key, required this.parentId, required this.etablissementId}) : super(key: key);

  @override
  State<ModifierParent> createState() => _ModifierParentState();
}

class _ModifierParentState extends State<ModifierParent> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _loading = false;

  List<ClasseModele> classesDisponibles = [];
  ClasseModele? classeSelectionnee;
  List<QueryDocumentSnapshot> elevesDisponibles = [];
  String? eleveSelectionne;

  String? roleEleveId;

  @override
  void initState() {
    super.initState();
    chargerRolesEtDonnees();
  }

  Future<void> chargerRolesEtDonnees() async {
    setState(() => _loading = true);

    try {
      // Charger le role élève
      final roleEleveSnap = await FirebaseFirestore.instance.collection('roles').where('nom', isEqualTo: 'eleve').limit(1).get();
      if (roleEleveSnap.docs.isEmpty) {
        afficherMessage("Erreur", "Rôle élève introuvable", DialogType.error);
        return;
      }
      roleEleveId = roleEleveSnap.docs.first.id;

      // Charger les classes
      final classesSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      classesDisponibles = classesSnap.docs.map((doc) => ClasseModele.fromMap(doc.data(), doc.id)).toList();

      // Charger les données du parent
      await chargerDonneesParent();
    } catch (e) {
      afficherMessage("Erreur", "Erreur de chargement : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> chargerDonneesParent() async {
    try {
      // Charger utilisateur
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(widget.parentId).get();
      if (!userDoc.exists) {
        afficherMessage("Erreur", "Parent introuvable", DialogType.error);
        return;
      }

      final userData = userDoc.data()!;
      _nomController.text = userData['nom'];
      _prenomController.text = userData['prenom'];
      _emailController.text = userData['email'];
      _telephoneController.text = userData['numeroTelephone'];
      _adresseController.text = userData['adresse'];

      // Charger parent pour récupérer l'enfant lié
      final parentDoc = await FirebaseFirestore.instance.collection('parents').doc(widget.parentId).get();
      if (parentDoc.exists) {
        final parentData = parentDoc.data()!;
        eleveSelectionne = (parentData['enfants'] as List).isNotEmpty ? parentData['enfants'][0] : null;
      }

      // Précharger les élèves de la première classe (optionnel)
      if (classesDisponibles.isNotEmpty) {
        classeSelectionnee = classesDisponibles.first;
        await chargerElevesDeClasse(classeSelectionnee!);
      }
    } catch (e) {
      afficherMessage("Erreur", "Erreur : $e", DialogType.error);
    }
  }

  Future<void> chargerElevesDeClasse(ClasseModele classe) async {
    try {
      if (classe.elevesIds.isEmpty) {
        setState(() {
          elevesDisponibles = [];
          eleveSelectionne = null;
        });
        return;
      }

      final elevesSnap = await FirebaseFirestore.instance.collection('utilisateurs')
          .where(FieldPath.documentId, whereIn: classe.elevesIds)
          .where('roleId', isEqualTo: roleEleveId)
          .get();

      setState(() {
        elevesDisponibles = elevesSnap.docs;
      });
    } catch (e) {
      afficherMessage("Erreur", "Erreur chargement élèves : $e", DialogType.error);
    }
  }

  Future<void> modifierParent() async {
    if (!_formKey.currentState!.validate()) return;
    if (eleveSelectionne == null) {
      afficherMessage("Erreur", "Sélectionnez un enfant", DialogType.warning);
      return;
    }

    setState(() => _loading = true);

    try {
      // Mise à jour utilisateur
      final updatedUser = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'numeroTelephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
      };

      await FirebaseFirestore.instance.collection('utilisateurs').doc(widget.parentId).update(updatedUser);

      // Mise à jour parent
      final updatedParent = {
        'enfants': [eleveSelectionne!],
      };

      await FirebaseFirestore.instance.collection('parents').doc(widget.parentId).update(updatedParent);

      // Mettre à jour l'élève avec le parent
      await FirebaseFirestore.instance.collection('eleves').doc(eleveSelectionne!).update({'parent': widget.parentId});

      afficherMessage("Succès", "Modification effectuée", DialogType.success, onOk: () {
        Navigator.pop(context);
      });
    } catch (e) {
      afficherMessage("Erreur", "Erreur : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  void afficherMessage(String titre, String message, DialogType type, {VoidCallback? onOk}) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: titre,
      desc: message,
      btnOkOnPress: () {
        if (onOk != null) onOk();
      },
    ).show();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le parent"), backgroundColor: primaryColor),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _champTexte("Nom", _nomController),
                    _champTexte("Prénom", _prenomController),
                    _champTexte("Email", _emailController, type: TextInputType.emailAddress),
                    _champTexte("Téléphone", _telephoneController, type: TextInputType.phone),
                    _champTexte("Adresse", _adresseController),

                    const SizedBox(height: 20),

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
                      decoration: const InputDecoration(labelText: "Classe", border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      items: elevesDisponibles.map((doc) {
                        final nomEleve = "${doc['nom']} ${doc['prenom']}";
                        return DropdownMenuItem(value: doc.id, child: Text(nomEleve));
                      }).toList(),
                      value: eleveSelectionne,
                      onChanged: (val) => setState(() => eleveSelectionne = val),
                      validator: (v) => v == null ? 'Sélection obligatoire' : null,
                      decoration: const InputDecoration(labelText: "Enfant", border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: modifierParent,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _champTexte(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
      ),
    );
  }
}
