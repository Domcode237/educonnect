import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class ModifierAdministrateur extends StatefulWidget {
  final UtilisateurModele administrateur;

  const ModifierAdministrateur({super.key, required this.administrateur});

  @override
  State<ModifierAdministrateur> createState() => _ModifierAdministrateurState();
}

class _ModifierAdministrateurState extends State<ModifierAdministrateur> {
  final _formKey = GlobalKey<FormState>();
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();

  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _adresseController;

  bool _chargement = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.administrateur.nom);
    _prenomController = TextEditingController(text: widget.administrateur.prenom);
    _emailController = TextEditingController(text: widget.administrateur.email);
    _telephoneController = TextEditingController(text: widget.administrateur.numeroTelephone);
    _adresseController = TextEditingController(text: widget.administrateur.adresse);
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

  void _afficherMessage(String titre, String message, DialogType type) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: titre,
      desc: message,
      btnOkOnPress: () {
        if (type == DialogType.success && mounted) {
          Navigator.pop(context);
        }
      },
    ).show();
  }

  Future<void> _modifierAdministrateur() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _chargement = true);
      try {
        final adminModifie = UtilisateurModele(
          id: widget.administrateur.id,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          numeroTelephone: _telephoneController.text.trim(),
          adresse: _adresseController.text.trim(),
          motDePasse: widget.administrateur.motDePasse, // mot de passe conservé
          statut: widget.administrateur.statut,
          roleId: widget.administrateur.roleId,
          etablissementId: widget.administrateur.etablissementId,
        );

        await _depotUtilisateur.modifierUtilisateur(widget.administrateur.id, adminModifie);

        _afficherMessage(
          "Succès",
          "L’administrateur a été modifié avec succès.",
          DialogType.success,
        );
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de la modification de l’administrateur : $e",
          DialogType.error,
        );
      } finally {
        if (mounted) setState(() => _chargement = false);
      }
    }
  }

  InputDecoration _champDecoration(String label, IconData icone) {
    return InputDecoration(
      prefixIcon: Icon(icone),
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier un administrateur"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomController,
                    decoration: _champDecoration("Nom", Icons.person),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _prenomController,
                    decoration: _champDecoration("Prénom", Icons.person_outline),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: _champDecoration("Email", Icons.email),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Champ requis";
                      }
                      final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      return emailRegExp.hasMatch(value.trim())
                          ? null
                          : "Email invalide";
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _telephoneController,
                    decoration: _champDecoration("Téléphone", Icons.phone),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _adresseController,
                    decoration: _champDecoration("Adresse", Icons.home),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _chargement ? null : _modifierAdministrateur,
                      icon: _chargement
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _chargement
                            ? "Enregistrement en cours..."
                            : "Enregistrer les modifications",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
