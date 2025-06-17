import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:educonnect/modules/admin/modeles/model_classe.dart'; // Assure-toi d’importer ta classe modèle ClasseModele

class ModifierClassePage extends StatefulWidget {
  final String idClasse;

  const ModifierClassePage({
    super.key,
    required this.idClasse,
  });

  @override
  State<ModifierClassePage> createState() => _ModifierClassePageState();
}

class _ModifierClassePageState extends State<ModifierClassePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  String? _niveauSelectionne;
  bool _isLoading = false;
  bool _isFetching = true;

  final List<String> _niveaux = ['6e', '5e', '4e', '3e', '2nde', '1ere', 'Tle'];

  ClasseModele? _classeModele;

  static Color _getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  @override
  void initState() {
    super.initState();
    _chargerClasse();
  }

  Future<void> _chargerClasse() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('classes').doc(widget.idClasse).get();

      if (doc.exists) {
        _classeModele = ClasseModele.fromMap(doc.data()!, doc.id);
        _nomController.text = _classeModele!.nom;
        _niveauSelectionne = _classeModele!.niveau;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement: $e')));
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  Future<void> _modifierClasse() async {
    if (!_formKey.currentState!.validate() || _classeModele == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // On recrée l'objet avec les modifications sur nom et niveau, en gardant les autres champs
      final classeModifiee = ClasseModele(
        id: _classeModele!.id,
        nom: _nomController.text.trim(),
        niveau: _niveauSelectionne!,
        etablissementId: _classeModele!.etablissementId,
        matieresIds: _classeModele!.matieresIds,
        elevesIds: _classeModele!.elevesIds,
        enseignantsIds: _classeModele!.enseignantsIds,
      );

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.idClasse)
          .set(classeModifiee.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classe modifiée avec succès')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
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

    if (_isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier la classe"),
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
                    _niveauSelectionne = val!;
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
                onPressed: _isLoading ? null : _modifierClasse,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Enregistrer"),
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
