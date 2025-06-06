import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:educonnect/donnees/depots/depot_role.dart';

class AjoutRoleVue extends StatefulWidget {
  const AjoutRoleVue({Key? key}) : super(key: key);

  @override
  State<AjoutRoleVue> createState() => _AjoutRoleVueState();
}

class _AjoutRoleVueState extends State<AjoutRoleVue> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DepotRole _depotRole = DepotRole();

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

  void _enregistrerRole() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _depotRole.ajouterRole(
          _nomController.text.trim(),
          _descriptionController.text.trim(),
        );

        _afficherMessage(
          "Succès",
          "Le rôle a été ajouté avec succès",
          DialogType.success,
        );

        _nomController.clear();
        _descriptionController.clear();
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de l'ajout du rôle : $e",
          DialogType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un rôle"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout de rôle",
                        style: theme.textTheme.titleLarge?.copyWith(
                          //color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge),
                      labelText: "Nom du rôle",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.description),
                      labelText: "Description",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _enregistrerRole,
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
