import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:educonnect/donnees/depots/depot_etablissement.dart';
import 'package:educonnect/donnees/modeles/EtablissementModele.dart';
import 'package:uuid/uuid.dart';

class AjoutEtablissementVue extends StatefulWidget {
  const AjoutEtablissementVue({Key? key}) : super(key: key);

  @override
  State<AjoutEtablissementVue> createState() => _AjoutEtablissementVueState();
}

class _AjoutEtablissementVueState extends State<AjoutEtablissementVue> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _regionController = TextEditingController();
  final _paysController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();

  final DepotEtablissement _depotEtablissement = DepotEtablissement();

  void _afficherMessage(String titre, String message, DialogType type) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: titre,
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _enregistrerEtablissement() async {
    if (_formKey.currentState!.validate()) {
      try {
        final etab = EtablissementModele(
          id: const Uuid().v4(),
          nom: _nomController.text.trim(),
          type: _typeController.text.trim(),
          description: _descriptionController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          region: _regionController.text.trim(),
          pays: _paysController.text.trim(),
          codePostal: _codePostalController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim(),
        );

        await _depotEtablissement.ajouterEtablissement(etab);

        _afficherMessage(
          "Succès",
          "L'établissement a été ajouté avec succès",
          DialogType.success,
        );

        _formKey.currentState!.reset();
        _nomController.clear();
        _typeController.clear();
        _descriptionController.clear();
        _adresseController.clear();
        _villeController.clear();
        _regionController.clear();
        _paysController.clear();
        _codePostalController.clear();
        _emailController.clear();
        _telephoneController.clear();
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de l'ajout de l'établissement : $e",
          DialogType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _regionController.dispose();
    _paysController.dispose();
    _codePostalController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Widget _champTexte({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "Champ requis" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un établissement"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout d'établissement",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _champTexte(
                      label: "Nom de l'établissement",
                      icon: Icons.badge,
                      controller: _nomController),
                  _champTexte(
                      label: "Type (ex: Lycée, collège)",
                      icon: Icons.category,
                      controller: _typeController),
                  _champTexte(
                      label: "Description",
                      icon: Icons.description,
                      controller: _descriptionController,
                      maxLines: 3),
                  _champTexte(
                      label: "Adresse",
                      icon: Icons.location_on,
                      controller: _adresseController),
                  _champTexte(
                      label: "Ville",
                      icon: Icons.location_city,
                      controller: _villeController),
                  _champTexte(
                      label: "Région",
                      icon: Icons.map,
                      controller: _regionController),
                  _champTexte(
                      label: "Pays",
                      icon: Icons.flag,
                      controller: _paysController),
                  _champTexte(
                      label: "Code postal",
                      icon: Icons.markunread_mailbox,
                      controller: _codePostalController),
                  _champTexte(
                      label: "Email",
                      icon: Icons.email,
                      controller: _emailController),
                  _champTexte(
                      label: "Téléphone",
                      icon: Icons.phone,
                      controller: _telephoneController),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _enregistrerEtablissement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
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
