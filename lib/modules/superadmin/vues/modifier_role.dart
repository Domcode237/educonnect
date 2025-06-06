import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:educonnect/donnees/depots/depot_role.dart';

class ModifierRole extends StatefulWidget {
  final String id; // L'ID du rôle à modifier
  final String nom;
  final String description;

  const ModifierRole({
    super.key,
    required this.id,
    required this.nom,
    required this.description,
  });

  @override
  State<ModifierRole> createState() => _ModifierRoleState();
}

class _ModifierRoleState extends State<ModifierRole> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  final DepotRole _depotRole = DepotRole();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.nom);
    _descriptionController = TextEditingController(text: widget.description);
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
          Navigator.pop(context); // Revenir à la page précédente
        }
      },
    ).show();
  }

  Future<void> _modifierRole() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _depotRole.modifierRole(
          widget.id,
          _nomController.text.trim(),
          _descriptionController.text.trim(),
        );

        _afficherMessage(
          "Succès",
          "Le rôle a été modifié avec succès.",
          DialogType.success,
        );
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de la modification du rôle : $e",
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
        title: const Text("Modifier un rôle"),
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
                      const Icon(Icons.edit, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "Modification de rôle",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge),
                      labelText: "Nom du rôle",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? "Champ requis"
                            : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.description),
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? "Champ requis"
                            : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _modifierRole,
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
