import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:educonnect/modules/admin/modeles/model_classe.dart'; // Assure-toi d’importer ta classe modèle ClasseModele

class AjouterClassePage extends StatefulWidget {
  final String etablissementId; // <-- id de l'établissement à passer

  const AjouterClassePage({super.key, required this.etablissementId});

  @override
  State<AjouterClassePage> createState() => _AjouterClassePageState();
}

class _AjouterClassePageState extends State<AjouterClassePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();

  final List<String> _niveaux = ['6e', '5e', '4e', '3e', '2nde', '1ere', 'Tle'];
  String? _niveauSelectionne;

  bool _isLoading = false;

  static Color _getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  Future<void> _ajouterClasse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String id = const Uuid().v4();

      final nouvelleClasse = ClasseModele(
        id: id,
        nom: _nomController.text.trim(),
        niveau: _niveauSelectionne!,
        etablissementId: widget.etablissementId,
        matieresIds: [],
        elevesIds: [],
        enseignantsIds: [],
      );

      await FirebaseFirestore.instance.collection('classes').doc(id).set(nouvelleClasse.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classe ajoutée avec succès')),
      );

      Navigator.pop(context); // Retour à la page précédente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout : $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une classe"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la classe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _niveauSelectionne,
                items: _niveaux.map((niveau) {
                  return DropdownMenuItem(
                    value: niveau,
                    child: Text(niveau),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Niveau',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) {
                  setState(() {
                    _niveauSelectionne = val;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un niveau';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _ajouterClasse,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Ajouter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
