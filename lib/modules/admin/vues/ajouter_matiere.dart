import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:educonnect/modules/admin/modeles/model_matiere.dart';
import 'package:educonnect/modules/admin/controleurs/controleur_matier.dart';

class AjoutMatiereVue extends StatefulWidget {
  final String etablissementId;  // <-- id de l'établissement

  const AjoutMatiereVue({super.key, required this.etablissementId});

  @override
  State<AjoutMatiereVue> createState() => _AjoutMatiereVueState();
}

class _AjoutMatiereVueState extends State<AjoutMatiereVue> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _coefficientController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final MatiereController _matiereController;

  @override
  void initState() {
    super.initState();
    // Initialise le controller avec l'id de l'établissement
    _matiereController = MatiereController(etablissementId: widget.etablissementId);
  }

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

  void _enregistrerMatiere() async {
    if (_formKey.currentState!.validate()) {
      try {
        final String id = const Uuid().v4();
        final matiere = MatiereModele(
          id: id,
          nom: _nomController.text.trim(),
          coefficient: double.parse(_coefficientController.text.trim()),
          description: _descriptionController.text.trim(),
          etablissementId: widget.etablissementId, // <-- passer l'id établissement ici
        );

        await _matiereController.ajouterMatiere(matiere);

        _afficherMessage(
          "Succès",
          "La matière a été ajoutée avec succès",
          DialogType.success,
        );

        _nomController.clear();
        _coefficientController.clear();
        _descriptionController.clear();
      } catch (e) {
        _afficherMessage(
          "Erreur",
          "Échec de l'ajout de la matière : $e",
          DialogType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _coefficientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une matière"),
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
                      const Icon(Icons.book, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout de matière",
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
                      prefixIcon: Icon(Icons.label),
                      labelText: "Nom de la matière",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _coefficientController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.functions),
                      labelText: "Coefficient",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Champ requis";
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return "Veuillez entrer un coefficient valide (> 0)";
                      }
                      return null;
                    },
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
                        value == null || value.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _enregistrerMatiere,
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
