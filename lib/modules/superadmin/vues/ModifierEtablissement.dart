import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:educonnect/donnees/depots/depot_etablissement.dart';
import 'package:educonnect/donnees/modeles/EtablissementModele.dart';

class ModifierEtablissement extends StatefulWidget {
  final EtablissementModele etab;

  const ModifierEtablissement({Key? key, required this.etab}) : super(key: key);

  @override
  State<ModifierEtablissement> createState() => _ModifierEtablissementState();
}

class _ModifierEtablissementState extends State<ModifierEtablissement> {
  final _formKey = GlobalKey<FormState>();
  final DepotEtablissement _depotEtablissement = DepotEtablissement();

  late final TextEditingController _nomController;
  late final TextEditingController _typeController;
  late final TextEditingController _adresseController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _villeController;
  late final TextEditingController _regionController;
  late final TextEditingController _paysController;
  late final TextEditingController _codePostalController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.etab.nom);
    _typeController = TextEditingController(text: widget.etab.type);
    _adresseController = TextEditingController(text: widget.etab.adresse);
    _descriptionController = TextEditingController(text: widget.etab.description);
    _villeController = TextEditingController(text: widget.etab.ville);
    _regionController = TextEditingController(text: widget.etab.region);
    _paysController = TextEditingController(text: widget.etab.pays);
    _codePostalController = TextEditingController(text: widget.etab.codePostal);
    _emailController = TextEditingController(text: widget.etab.email);
    _telephoneController = TextEditingController(text: widget.etab.telephone);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _typeController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    _villeController.dispose();
    _regionController.dispose();
    _paysController.dispose();
    _codePostalController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
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

  Future<void> _modifierEtablissement() async {
    if (_formKey.currentState!.validate()) {
      try {
        final etabModifie = EtablissementModele(
          id: widget.etab.id,
          nom: _nomController.text.trim(),
          type: _typeController.text.trim(),
          adresse: _adresseController.text.trim(),
          description: _descriptionController.text.trim(),
          ville: _villeController.text.trim(),
          region: _regionController.text.trim(),
          pays: _paysController.text.trim(),
          codePostal: _codePostalController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim(),
        );

        await _depotEtablissement.modifierEtablissement(widget.etab.id, etabModifie);

        _afficherMessage(
          "Succès",
          "L’établissement a été modifié avec succès.",
          DialogType.success,
        );
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de la modification de l’établissement : $e",
          DialogType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    InputDecoration champDecoration(String label, IconData icone) {
      return InputDecoration(
        prefixIcon: Icon(icone),
        labelText: label,
        border: const OutlineInputBorder(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier un établissement"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nomController,
                    decoration: champDecoration("Nom", Icons.badge),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _typeController,
                    decoration: champDecoration("Type", Icons.category),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _adresseController,
                    decoration: champDecoration("Adresse", Icons.location_on),
                    maxLines: 2,
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: champDecoration("Description", Icons.info_outline),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _villeController,
                    decoration: champDecoration("Ville", Icons.location_city),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _regionController,
                    decoration: champDecoration("Région", Icons.map),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _paysController,
                    decoration: champDecoration("Pays", Icons.flag),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _codePostalController,
                    decoration: champDecoration("Code Postal", Icons.pin),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: champDecoration("Email", Icons.email),
                    validator: (value) =>
                        value != null && value.contains('@') ? null : "Email invalide",
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _telephoneController,
                    decoration: champDecoration("Téléphone", Icons.phone),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _modifierEtablissement,
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer les modifications"),
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
