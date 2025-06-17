import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:educonnect/modules/admin/controleurs/controleur_matier.dart';
import 'package:educonnect/modules/admin/modeles/model_matiere.dart';

class ModifierMatiere extends StatefulWidget {
  final String id;
  final String nom;
  final String description;
  final double coefficient;
  final String etablissementId; // Ajouté ici

  const ModifierMatiere({
    super.key,
    required this.id,
    required this.nom,
    required this.description,
    required this.coefficient,
    required this.etablissementId, // Ajouté ici
  });

  @override
  State<ModifierMatiere> createState() => _ModifierMatiereState();
}

class _ModifierMatiereState extends State<ModifierMatiere> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coefficientController;
  late final MatiereController _matiereController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.nom);
    _descriptionController = TextEditingController(text: widget.description);
    _coefficientController =
        TextEditingController(text: widget.coefficient.toString());
    _matiereController = MatiereController(etablissementId: widget.etablissementId);
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

  Future<void> _modifierMatiere() async {
    if (_formKey.currentState!.validate()) {
      try {
        final coefficient = double.tryParse(_coefficientController.text.trim());
        if (coefficient == null || coefficient <= 0) {
          _afficherMessage(
            "Erreur",
            "Le coefficient doit être un nombre valide et supérieur à 0.",
            DialogType.error,
          );
          return;
        }

        final matiere = MatiereModele(
          id: widget.id,
          nom: _nomController.text.trim(),
          description: _descriptionController.text.trim(),
          coefficient: coefficient,
          etablissementId: widget.etablissementId, // Important : passer l'id ici
        );

        await _matiereController.modifierMatiere(matiere);

        _afficherMessage(
          "Succès",
          "La matière a été modifiée avec succès.",
          DialogType.success,
        );
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de la modification de la matière : $e",
          DialogType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _coefficientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier une matière"),
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
                        "Modification de matière",
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
                      prefixIcon: Icon(Icons.book),
                      labelText: "Nom de la matière",
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _coefficientController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calculate),
                      labelText: "Coefficient",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Champ requis";
                      }
                      final number = double.tryParse(value.trim());
                      if (number == null || number <= 0) {
                        return "Veuillez entrer un coefficient valide (> 0)";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _modifierMatiere,
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
