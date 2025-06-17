import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ModificationEleveVue extends StatefulWidget {
  final String eleveId;

  const ModificationEleveVue({Key? key, required this.eleveId}) : super(key: key);

  @override
  State<ModificationEleveVue> createState() => _ModificationEleveVueState();
}

class _ModificationEleveVueState extends State<ModificationEleveVue> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _loading = false;
  String? _classeIdSelectionnee;
  List<Map<String, dynamic>> _classesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _chargerDonneesEleve();
  }

  void _afficherMessage(String titre, String message, DialogType type, {VoidCallback? onOk}) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: titre,
      desc: message,
      btnOkOnPress: () {
        if (onOk != null) {
          onOk();
        }
      },
    ).show();
  }

  Future<void> _chargerDonneesEleve() async {
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('eleves').doc(widget.eleveId).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _nomController.text = data['nom'] ?? '';
        _prenomController.text = data['prenom'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telephoneController.text = data['numeroTelephone'] ?? '';
        _adresseController.text = data['adresse'] ?? '';
        _classeIdSelectionnee = data['classeId'];

        await _chargerClasses(data['etablissementId']);
      } else {
        _afficherMessage("Erreur", "Élève introuvable", DialogType.error, onOk: () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors du chargement : $e", DialogType.error, onOk: () {
        Navigator.pop(context);
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _chargerClasses(String etablissementId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('etablissementId', isEqualTo: etablissementId)
        .get();

    setState(() {
      _classesDisponibles = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'] ?? 'Classe sans nom',
        };
      }).toList();
    });
  }

  Future<void> _modifierEleve() async {
    if (!_formKey.currentState!.validate()) return;

    if (_classeIdSelectionnee == null) {
      _afficherMessage("Erreur", "Veuillez sélectionner une classe", DialogType.warning);
      return;
    }

    setState(() => _loading = true);

    try {
      final updatedData = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'numeroTelephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'classeId': _classeIdSelectionnee,
      };

      await FirebaseFirestore.instance.collection('eleves').doc(widget.eleveId).update(updatedData);
      await FirebaseFirestore.instance.collection('utilisateurs').doc(widget.eleveId).update(updatedData);

      _afficherMessage(
        "Succès",
        "Élève modifié avec succès",
        DialogType.success,
        onOk: () {
          Navigator.pop(context); // ferme la page actuelle
          Navigator.pushReplacementNamed(context, '/utilisateurs'); // Redirige vers la liste des utilisateurs
        },
      );
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors de la modification : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _champTexte({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Champ requis" : null,
      ),
    );
  }

  Widget _champClasse() {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: _classeIdSelectionnee,
        items: _classesDisponibles
            .where((classe) => classe['id'] != null && classe['nom'] != null)
            .map((classe) => DropdownMenuItem<String>(
                  value: classe['id'] as String,
                  child: Text(classe['nom'] as String),
                ))
            .toList(),
        decoration: InputDecoration(
          labelText: 'Classe',
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          prefixIcon: Icon(Icons.class_, color: primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (val) => setState(() => _classeIdSelectionnee = val),
        validator: (val) => val == null ? "Sélectionnez une classe" : null,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier un élève"),
        backgroundColor: primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 80, color: primaryColor),
                        const SizedBox(height: 10),
                        Text(
                          "Modification de l'élève",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _champTexte(label: "Nom", icon: Icons.person, controller: _nomController),
                        _champTexte(label: "Prénom", icon: Icons.person_outline, controller: _prenomController),
                        _champTexte(label: "Email", icon: Icons.email, controller: _emailController, keyboardType: TextInputType.emailAddress),
                        _champTexte(label: "Téléphone", icon: Icons.phone, controller: _telephoneController, keyboardType: TextInputType.phone),
                        _champTexte(label: "Adresse", icon: Icons.location_on, controller: _adresseController),
                        _champClasse(),
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
                            onPressed: _loading ? null : _modifierEleve,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
