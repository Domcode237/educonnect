import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:educonnect/main.dart'; // pour appwriteStorage

class AjoutEleveVue extends StatefulWidget {
  final String etablissementId;

  const AjoutEleveVue({super.key, required this.etablissementId});

  @override
  State<AjoutEleveVue> createState() => _AjoutEleveVueState();
}

class _AjoutEleveVueState extends State<AjoutEleveVue> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _motDePasseController = TextEditingController();

  Map<String, dynamic>? _etablissement;
  bool _loading = false;
  bool _chargementTermine = false;

  List<Map<String, dynamic>> _classes = [];
  String? _classeIdSelectionne;

  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();
    _chargerEtablissementEtClasses();
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

  Future<void> _chargerEtablissementEtClasses() async {
    if (widget.etablissementId.isEmpty) {
      _afficherMessage("Erreur", "L'identifiant de l'établissement est manquant.", DialogType.error);
      return;
    }

    try {
      final id = widget.etablissementId.trim();
      final snapshot = await FirebaseFirestore.instance.collection('etablissements').doc(id).get();
      if (snapshot.exists) {
        setState(() {
          _etablissement = snapshot.data();
        });
        await _chargerClasses();
      } else {
        _afficherMessage("Erreur", "Établissement introuvable.", DialogType.error);
      }
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors du chargement de l'établissement : $e", DialogType.error);
    } finally {
      setState(() {
        _chargementTermine = true;
      });
    }
  }

  Future<void> _chargerClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      setState(() {
        _classes = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors du chargement des classes : $e", DialogType.error);
    }
  }

  Future<String?> _recupererRoleEleveId() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('roles')
          .where('nom', isEqualTo: 'eleve')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      _afficherMessage("Erreur", "Erreur lors de la récupération du rôle élève : $e", DialogType.error);
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
      const bucketId = '6854df330032c7be516c'; // adapte cet ID à ton bucket
      final result = await appwriteStorage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
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

  Future<void> _enregistrerEleve() async {
    if (!_formKey.currentState!.validate()) return;

    if (_etablissement == null) {
      _afficherMessage("Erreur", "Établissement introuvable.", DialogType.error);
      return;
    }

    if (_classeIdSelectionne == null) {
      _afficherMessage("Erreur", "Veuillez sélectionner une classe.", DialogType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final roleEleveId = await _recupererRoleEleveId();

      if (roleEleveId == null) {
        _afficherMessage("Erreur", "Le rôle élève est introuvable.", DialogType.error);
        setState(() => _loading = false);
        return;
      }

      // Création utilisateur Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _motDePasseController.text.trim(),
      );

      String userId = userCredential.user!.uid;

      // Upload image si sélectionnée
      String? fileId;
      if (_imageBytes != null && _imageName != null) {
        fileId = await _uploadImageToAppwrite(_imageBytes!, _imageName!);
      }

      // Préparation des données utilisateur à enregistrer dans Firestore
      final utilisateurData = {
        'uid': userId,
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'numeroTelephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'statut': false,
        'photo': fileId ?? '',
        'roleId': roleEleveId,
        'etablissementId': widget.etablissementId,
        'etablissement': _etablissement,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Enregistrer utilisateur dans la collection 'utilisateurs'
      await FirebaseFirestore.instance.collection('utilisateurs').doc(userId).set(utilisateurData);

      // Enregistrer élève dans la collection 'eleves' avec seulement utilisateurId et classeId
      final eleveData = {
        'utilisateurId': userId,
        'classeId': _classeIdSelectionne,
        'notesIds': <String>[],
      };

      await FirebaseFirestore.instance.collection('eleves').doc(userId).set(eleveData);

      // ** AJOUTER L'ID DE L'ELEVE DANS LA LISTE elevesIds DE LA CLASSE **
      final classeRef = FirebaseFirestore.instance.collection('classes').doc(_classeIdSelectionne);
      final classeSnapshot = await classeRef.get();
      if (classeSnapshot.exists) {
        final classeData = classeSnapshot.data()!;
        List<dynamic> elevesIds = classeData['elevesIds'] ?? [];
        if (!elevesIds.contains(userId)) {
          elevesIds.add(userId);
          await classeRef.update({'elevesIds': elevesIds});
        }
      }

      _afficherMessage("Succès", "Élève ajouté avec succès", DialogType.success);
      _formKey.currentState?.reset();
      setState(() {
        _classeIdSelectionne = null;
        _imageBytes = null;
        _imageName = null;
      });
    } on FirebaseAuthException catch (e) {
      String message = "Erreur d'authentification";
      if (e.code == 'email-already-in-use') {
        message = "Cet email est déjà utilisé.";
      } else if (e.code == 'weak-password') {
        message = "Mot de passe trop faible (minimum 6 caractères).";
      } else {
        message = e.message ?? "Erreur inconnue.";
      }
      _afficherMessage("Erreur", message, DialogType.error);
    } catch (e) {
      _afficherMessage("Erreur", "Échec de l'enregistrement : $e", DialogType.error);
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
    String? Function(String?)? validator,
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
        validator: validator ?? (value) => (value == null || value.isEmpty) ? "Champ requis" : null,
      ),
    );
  }

  Widget _champClasse() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.class_),
          labelText: "Classe",
          border: OutlineInputBorder(),
        ),
        items: _classes.map((classe) {
          return DropdownMenuItem<String>(
            value: classe['id'],
            child: Text(classe['nom']),
          );
        }).toList(),
        value: _classeIdSelectionne,
        onChanged: (value) {
          setState(() {
            _classeIdSelectionne = value;
          });
        },
        validator: (value) => value == null ? "Veuillez sélectionner une classe" : null,
      ),
    );
  }

  Widget _champImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Photo de l'élève",
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
    final theme = Theme.of(context);

    if (!_chargementTermine) {
      return Scaffold(
        appBar: AppBar(title: const Text("Ajouter un élève")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un élève")),
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
                      const Icon(Icons.school, size: 30, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Formulaire d'ajout d'élève",
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _champImage(),
                  _champTexte(label: "Nom", icon: Icons.person, controller: _nomController),
                  _champTexte(label: "Prénom", icon: Icons.person_outline, controller: _prenomController),
                  _champTexte(label: "Email", icon: Icons.email, controller: _emailController, keyboardType: TextInputType.emailAddress),
                  _champTexte(label: "Téléphone", icon: Icons.phone, controller: _telephoneController, keyboardType: TextInputType.phone),
                  _champTexte(label: "Adresse", icon: Icons.location_on, controller: _adresseController),
                  _champTexte(label: "Mot de passe", icon: Icons.lock, controller: _motDePasseController, obscureText: true),
                  _champClasse(),
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
                      onPressed: _loading ? null : _enregistrerEleve,
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
        ),
      ),
    );
  }
}
