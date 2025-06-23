import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ModifierParent extends StatefulWidget {
  final String parentId;

  const ModifierParent({Key? key, required this.parentId}) : super(key: key);

  @override
  State<ModifierParent> createState() => _ModifierParentState();
}

class _ModifierParentState extends State<ModifierParent> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chargerDonneesParent();
  }

  Future<void> _chargerDonneesParent() async {
    setState(() => _loading = true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(widget.parentId).get();
      if (!userDoc.exists) {
        _afficherMessage("Erreur", "Parent introuvable", DialogType.error);
        return;
      }

      final userData = userDoc.data()!;
      _nomController.text = userData['nom'] ?? '';
      _prenomController.text = userData['prenom'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _telephoneController.text = userData['numeroTelephone'] ?? '';
      _adresseController.text = userData['adresse'] ?? '';
    } catch (e) {
      _afficherMessage("Erreur", "Erreur de chargement : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _modifierParent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final updatedUser = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'numeroTelephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
      };

      await FirebaseFirestore.instance.collection('utilisateurs').doc(widget.parentId).update(updatedUser);

      _afficherMessage("Succès", "Modification effectuée", DialogType.success, onOk: () {
        Navigator.pop(context);
      });
    } catch (e) {
      _afficherMessage("Erreur", "Erreur : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
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
        if (onOk != null) onOk();
      },
    ).show();
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
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le parent")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _champTexte("Nom", _nomController),
                    _champTexte("Prénom", _prenomController),
                    _champTexte("Email", _emailController, type: TextInputType.emailAddress),
                    _champTexte("Téléphone", _telephoneController, type: TextInputType.phone),
                    _champTexte("Adresse", _adresseController),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _modifierParent,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _champTexte(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
      ),
    );
  }
}
