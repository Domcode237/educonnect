import 'dart:typed_data';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:educonnect/main.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';
import 'package:educonnect/donnees/depots/DepotAdministrateur.dart';
import 'package:educonnect/donnees/modeles/AdministrateurModele.dart';

class AjoutAdministrateurVue extends StatefulWidget {
  const AjoutAdministrateurVue({Key? key}) : super(key: key);

  @override
  State<AjoutAdministrateurVue> createState() => _AjoutAdministrateurVueState();
}

class _AjoutAdministrateurVueState extends State<AjoutAdministrateurVue> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _motDePasseController = TextEditingController();

  String? _etablissementIdSelectionne;
  Map<String, dynamic>? _etablissementSelectionne;
  bool _loading = false;

  Uint8List? _imageBytes;
  String? _imageName;

  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();
  final DepotAdministrateur _depotAdministrateur = DepotAdministrateur();

  Future<List<QueryDocumentSnapshot>> _chargerEtablissements() async {
    final snapshot = await FirebaseFirestore.instance.collection('etablissements').get();
    return snapshot.docs;
  }

  Future<String?> _recupererRoleAdministrateurId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('roles')
        .where('nom', isEqualTo: 'administrateur')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
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

  Future<void> _enregistrerAdministrateur() async {
    if (!_formKey.currentState!.validate()) return;

    if (_etablissementIdSelectionne == null) {
      _afficherMessage(
        "Erreur",
        "Veuillez sélectionner un établissement.",
        DialogType.warning,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Récupérer l'ID du rôle "administrateur"
      final roleAdministrateurId = await _recupererRoleAdministrateurId();
      if (roleAdministrateurId == null) {
        _afficherMessage(
          "Erreur",
          "Le rôle administrateur est introuvable.",
          DialogType.error,
        );
        setState(() => _loading = false);
        return;
      }

      // 2. Upload photo si besoin
      String? fileId;
      if (_imageBytes != null && _imageName != null) {
        fileId = await _uploadImageToAppwrite(_imageBytes!, _imageName!);
      }

      // 3. Création d’un utilisateur dans FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _motDePasseController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 4. Création du modèle utilisateur avec le rôle récupéré
      final utilisateur = UtilisateurModele(
        id: uid,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        numeroTelephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim(),
        motDePasse: _motDePasseController.text.trim(),
        statut: false,
        roleId: roleAdministrateurId,
        etablissementId: _etablissementIdSelectionne!,
        photo: fileId,
      );

      // 5. Enregistrement de l'utilisateur dans Firestore
      await _depotUtilisateur.ajouterUtilisateur(utilisateur);

      // 6. Création de l’administrateur lié à l'utilisateur
      final administrateur = AdministrateurModele(
        id: uid,
        utilisateurId: uid,
      );

      // 7. Enregistrement de l’administrateur
      await _depotAdministrateur.ajouterAdministrateur(administrateur);

      _afficherMessage(
        "Succès",
        "Administrateur ajouté avec succès",
        DialogType.success,
      );

      _formKey.currentState?.reset();
      setState(() {
        _imageBytes = null;
        _imageName = null;
        _etablissementIdSelectionne = null;
        _etablissementSelectionne = null;
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
      _afficherMessage(
        "Erreur",
        "Échec de l'enregistrement : $e",
        DialogType.error,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

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

  Widget _champEtablissement() {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _chargerEtablissements(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final etablissements = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: _etablissementIdSelectionne,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.school),
            labelText: "Établissement",
            border: OutlineInputBorder(),
          ),
          items: etablissements
              .map((doc) => DropdownMenuItem(
                    value: doc.id,
                    child: Text(doc['nom'] ?? 'Sans nom'),
                  ))
              .toList(),
          onChanged: (value) {
            final etablissement = etablissements.firstWhere((doc) => doc.id == value);
            setState(() {
              _etablissementIdSelectionne = value;
              _etablissementSelectionne = etablissement.data() as Map<String, dynamic>;
            });
          },
          validator: (val) => val == null ? "Sélection requise" : null,
        );
      },
    );
  }

  Widget _champTexte({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator ??
            (val) => (val == null || val.isEmpty) ? "Champ requis" : null,
      ),
    );
  }

  Widget _champImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Photo de l’administrateur",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un administrateur")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, size: 30, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout d'administrateur",
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _champImage(),
                  _champTexte(
                    label: "Nom",
                    icon: Icons.person,
                    controller: _nomController,
                  ),
                  _champTexte(
                    label: "Prénom",
                    icon: Icons.person_outline,
                    controller: _prenomController,
                  ),
                  _champTexte(
                    label: "Email",
                    icon: Icons.email,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Champ requis";
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(val)) return "Email invalide";
                      return null;
                    },
                  ),
                  _champTexte(
                    label: "Numéro de téléphone",
                    icon: Icons.phone,
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*$'))],
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Champ requis";
                      if (!RegExp(r'^\+?\d{6,15}$').hasMatch(val)) {
                        return "Numéro invalide (6 à 15 chiffres)";
                      }
                      return null;
                    },
                  ),
                  _champTexte(
                    label: "Adresse",
                    icon: Icons.location_on,
                    controller: _adresseController,
                  ),
                  _champTexte(
                    label: "Mot de passe",
                    icon: Icons.lock,
                    controller: _motDePasseController,
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Champ requis";
                      if (val.length < 6) return "Minimum 6 caractères";
                      return null;
                    },
                  ),
                  _champEtablissement(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      onPressed: _loading ? null : _enregistrerAdministrateur,
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
