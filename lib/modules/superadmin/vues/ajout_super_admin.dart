import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AjoutSuperAdministrateurVue extends StatefulWidget {
  const AjoutSuperAdministrateurVue({Key? key}) : super(key: key);

  @override
  State<AjoutSuperAdministrateurVue> createState() => _AjoutSuperAdministrateurVueState();
}

class _AjoutSuperAdministrateurVueState extends State<AjoutSuperAdministrateurVue> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _motDePasseController = TextEditingController();

  bool _loading = false;

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

  Future<void> _enregistrerSuperAdministrateur() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Rechercher le rôle "superadmin"
      final roleSnapshot = await FirebaseFirestore.instance
          .collection('roles')
          .where('nom', isEqualTo: 'Superadmin')
          .limit(1)
          .get();

      if (roleSnapshot.docs.isEmpty) {
        _afficherMessage("Erreur", "Le rôle 'superadmin' est introuvable dans la base de données.", DialogType.error);
        setState(() => _loading = false);
        return;
      }

      final roleId = roleSnapshot.docs.first.id;

      // 2. Créer l'utilisateur Firebase
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
        'roleId': roleId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 3. Enregistrements dans Firestore
      await FirebaseFirestore.instance.collection('superadministrateurs').doc(userId).set(userData);

      await FirebaseFirestore.instance.collection('utilisateurs').doc(userId).set({
        ...userData,
        'typeUtilisateur': 'superadministrateur',
      });

      await FirebaseFirestore.instance.collection('authentification').doc(userId).set({
        'email': _emailController.text.trim(),
        'roleId': roleId,
        'uid': userId,
      });

      _afficherMessage("Succès", "Super administrateur ajouté avec succès", DialogType.success);
      _formKey.currentState?.reset();
    } on FirebaseAuthException catch (e) {
      String message = "Erreur d'authentification";

      if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé.";
      } else if (e.code == 'weak-password') {
        message = "Mot de passe trop faible (minimum 6 caractères).";
      } else {
        message = e.message ?? "Erreur inconnue lors de la création du compte.";
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
      appBar: AppBar(title: const Text("Ajouter un super administrateur")),
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
                      const Icon(Icons.security, size: 30, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout de super administrateur",
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _champTexte(label: "Nom", icon: Icons.person, controller: _nomController),
                  _champTexte(label: "Prénom", icon: Icons.person_outline, controller: _prenomController),
                  _champTexte(
                    label: "Email",
                    icon: Icons.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Champ requis";
                      final emailRegex = RegExp(r"^[^@]+@[^@]+\.[^@]+");
                      if (!emailRegex.hasMatch(val)) return "Email invalide";
                      return null;
                    },
                  ),
                  _champTexte(
                    label: "Numéro de téléphone",
                    icon: Icons.phone,
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _champTexte(label: "Adresse", icon: Icons.location_on, controller: _adresseController),
                  _champTexte(
                    label: "Mot de passe",
                    icon: Icons.lock,
                    controller: _motDePasseController,
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Champ requis";
                      if (val.length < 6) return "Minimum 6 caractères";
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Enregistrer"),
                      onPressed: _loading ? null : _enregistrerSuperAdministrateur,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.redAccent,
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
