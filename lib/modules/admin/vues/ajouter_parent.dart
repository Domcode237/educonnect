import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:educonnect/main.dart';

class AjoutParentVue extends StatefulWidget {
  final String etablissementId;

  const AjoutParentVue({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<AjoutParentVue> createState() => _AjoutParentVueState();
}

class _AjoutParentVueState extends State<AjoutParentVue> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _motDePasseController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;

  void _afficherMessage(String titre, String message, DialogType type) {
    if (!mounted) return;
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: titre,
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  Future<String?> _recupererRoleParentId() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('roles')
          .where('nom', isEqualTo: 'parent')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors de la récupération du rôle parent : $e", DialogType.error);
      return null;
    }
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  Future<String?> _uploadImageToAppwrite(Uint8List fileBytes, String fileName) async {
    try {
      const bucketId = '6854df330032c7be516c';
      final result = await appwriteStorage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile(
          bytes: fileBytes,
          filename: fileName,
          contentType: 'image/png',
        ),
      );
      return result.$id;
    } catch (e) {
      debugPrint('Erreur Appwrite lors de l\'upload: $e');
      return null;
    }
  }

  Future<void> _enregistrerParent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final roleParentId = await _recupererRoleParentId();
      if (roleParentId == null) {
        _afficherMessage("Erreur", "Le rôle parent est introuvable.", DialogType.error);
        setState(() => _loading = false);
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _motDePasseController.text.trim(),
      );

      String userId = userCredential.user!.uid;
      String? fileId;
      if (_imageBytes != null && _imageName != null) {
        fileId = await _uploadImageToAppwrite(_imageBytes!, _imageName!);
      }

      final utilisateurData = {
        'uid': userId,
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'numeroTelephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'statut': false,
        'photo': fileId ?? '',
        'roleId': roleParentId,
        'etablissementId': widget.etablissementId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('utilisateurs').doc(userId).set(utilisateurData);

      final parentData = {
        'utilisateurId': userId,     
      };

      await FirebaseFirestore.instance.collection('parents').doc(userId).set(parentData);

      _afficherMessage("Succès", "Parent ajouté avec succès", DialogType.success);
      _formKey.currentState?.reset();
      setState(() {
        _imageBytes = null;
        _imageName = null;
      });
    } on FirebaseAuthException catch (e) {
      String message = "Erreur d'authentification";
      if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé.";
      } else if (e.code == 'weak-password') {
        message = "Mot de passe trop faible.";
      } else {
        message = e.message ?? "Erreur inconnue.";
      }
      _afficherMessage("Erreur", message, DialogType.error);
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors de l'enregistrement : $e", DialogType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _champTexte({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => (value == null || value.isEmpty) ? "Champ requis" : null,
      ),
    );
  }

  Widget _champImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Photo du parent", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _choisirImage,
          child: _imageBytes == null
              ? Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un parent")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _champImage(),
              _champTexte(label: "Nom", icon: Icons.person, controller: _nomController),
              _champTexte(label: "Prénom", icon: Icons.person_outline, controller: _prenomController),
              _champTexte(label: "Email", icon: Icons.email, controller: _emailController, keyboardType: TextInputType.emailAddress),
              _champTexte(label: "Téléphone", icon: Icons.phone, controller: _telephoneController, keyboardType: TextInputType.phone),
              _champTexte(label: "Adresse", icon: Icons.location_on, controller: _adresseController),
              _champTexte(label: "Mot de passe", icon: Icons.lock, controller: _motDePasseController, obscureText: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text("Enregistrer"),
                  onPressed: _loading ? null : _enregistrerParent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
