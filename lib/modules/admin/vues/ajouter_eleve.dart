import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AjoutEleveVue extends StatefulWidget {
  const AjoutEleveVue({Key? key}) : super(key: key);

  @override
  State<AjoutEleveVue> createState() => _AjoutEleveVueState();
}

class _AjoutEleveVueState extends State<AjoutEleveVue> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _motDePasseController = TextEditingController();

  String? _etablissementId;
  Map<String, dynamic>? _etablissement;
  bool _loading = false;

  List<Map<String, dynamic>> _classes = [];
  String? _classeIdSelectionne;

  @override
  void initState() {
    super.initState();
    _chargerEtablissementUtilisateur();
  }

  void _afficherMessage(String titre, String message, DialogType type) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: titre,
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _chargerEtablissementUtilisateur() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance.collection('utilisateurs').doc(userId).get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _etablissementId = data['etablissementId'];
          _etablissement = data['etablissement'];
        });
        await _chargerClasses();
      } else {
        _afficherMessage("Erreur", "Impossible de récupérer l'établissement.", DialogType.error);
      }
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors de la récupération : $e", DialogType.error);
    }
  }

  Future<void> _chargerClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: _etablissementId)
          .get();

      setState(() {
        _classes = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors du chargement des classes : $e", DialogType.error);
    }
  }

  Future<String?> _recupererRoleEleveId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('roles')
        .where('nom', isEqualTo: 'eleve')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    } else {
      return null;
    }
  }

  Future<void> _enregistrerEleve() async {
    if (!_formKey.currentState!.validate()) return;

    if (_etablissementId == null || _etablissement == null) {
      _afficherMessage("Erreur", "Établissement introuvable.", DialogType.error);
      return;
    }

    if (_classeIdSelectionne == null) {
      _afficherMessage("Erreur", "Veuillez sélectionner une classe.", DialogType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final roleEleveId = await _recupererRoleEleveId();

      if (roleEleveId == null) {
        _afficherMessage("Erreur", "Le rôle élève est introuvable.", DialogType.error);
        setState(() => _loading = false);
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _motDePasseController.text.trim(),
      );

      String userId = userCredential.user!.uid;

      final userData = {
        'uid': userId,
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'numeroTelephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'statut': false,
        'photoUrl': '',
        'roleId': roleEleveId,
        'etablissementId': _etablissementId,
        'etablissement': _etablissement,
        'classeId': _classeIdSelectionne,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('eleves').doc(userId).set(userData);
      await FirebaseFirestore.instance.collection('utilisateurs').doc(userId).set({
        ...userData,
        'typeUtilisateur': 'eleve',
      });

      await FirebaseFirestore.instance.collection('authentification').doc(userId).set({
        'email': _emailController.text.trim(),
        'roleId': roleEleveId,
        'uid': userId,
      });

      _afficherMessage("Succès", "Élève ajouté avec succès", DialogType.success);
      _formKey.currentState?.reset();
      setState(() {
        _classeIdSelectionne = null;
      });

    } on FirebaseAuthException catch (e) {
      String message = "Erreur d'authentification";
      if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé.";
      } else if (e.code == 'weak-password') {
        message = "Mot de passe trop faible (minimum 6 caractères).";
      } else {
        message = e.message ?? "Erreur inconnue.";
      }
      _afficherMessage("Erreur", message, DialogType.error);
    } catch (e) {
      _afficherMessage("Erreur", "Échec de l'enregistrement : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _champTexte({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator ?? (value) => (value == null || value.isEmpty) ? "Champ requis" : null,
      ),
    );
  }

  Widget _champClasse() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.class_),
          labelText: "Classe",
          border: OutlineInputBorder(),
        ),
        items: _classes.map((classe) {
          return DropdownMenuItem<String>(
            value: classe['id'],
            child: Text(classe['nom']),
          );
        }).toList(),
        value: _classeIdSelectionne,
        onChanged: (value) {
          setState(() {
            _classeIdSelectionne = value;
          });
        },
        validator: (value) => value == null ? "Veuillez sélectionner une classe" : null,
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un élève")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school, size: 30, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout d'élève",
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _champTexte(label: "Nom", icon: Icons.person, controller: _nomController),
                  _champTexte(label: "Prénom", icon: Icons.person_outline, controller: _prenomController),
                  _champTexte(label: "Email", icon: Icons.email, controller: _emailController, keyboardType: TextInputType.emailAddress),
                  _champTexte(label: "Téléphone", icon: Icons.phone, controller: _telephoneController, keyboardType: TextInputType.phone),
                  _champTexte(label: "Adresse", icon: Icons.location_on, controller: _adresseController),
                  _champTexte(label: "Mot de passe", icon: Icons.lock, controller: _motDePasseController, obscureText: true),
                  _champClasse(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          : const Text("Enregistrer"),
                      onPressed: _loading ? null : _enregistrerEleve,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
