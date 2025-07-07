import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import 'liste_annonce.dart';

class CreerAnnoncePage extends StatefulWidget {
  final String etablissementId;

  const CreerAnnoncePage({super.key, required this.etablissementId});

  @override
  State<CreerAnnoncePage> createState() => _CreerAnnoncePageState();
}

class _CreerAnnoncePageState extends State<CreerAnnoncePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _fichierBytes;
  String? _nomFichier;
  String? _fichierId;

  bool _chargement = false;

  Future<void> _choisirFichier() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fichierBytes = result.files.first.bytes;
        _nomFichier = result.files.first.name;
      });
    }
  }

  Future<void> _uploaderFichierDansAppwrite() async {
    if (_fichierBytes == null || _nomFichier == null) return;

    final idUnique = const Uuid().v4();
    final storage = Storage(appwriteClient);

    try {
      final response = await storage.createFile(
        bucketId: '6854df330032c7be516c',
        fileId: idUnique,
        file: InputFile.fromBytes(
          bytes: _fichierBytes!,
          filename: _nomFichier!,
        ),
      );

      setState(() {
        _fichierId = response.$id;
      });
    } catch (e) {
      debugPrint('Erreur upload fichier: $e');
    }
  }

  Future<void> _soumettreAnnonce() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _chargement = true);

    if (_fichierBytes != null) {
      await _uploaderFichierDansAppwrite();
    }

    try {
      final utilisateursSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      final utilisateursIds =
          utilisateursSnap.docs.map((doc) => doc.id).toList();

      await FirebaseFirestore.instance.collection('annonces').add({
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fichierId': _fichierId,
        'utilisateursConcernees': utilisateursIds,
        'luePar': [],
        'etablissementId': widget.etablissementId,
        'dateCreation': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Annonce publiée avec succès")),
      );
      // Navigator.pop(context);
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'annonce : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() => _chargement = false);
    }
  }

  bool _estImage(String nomFichier) {
    final extension = nomFichier.toLowerCase();
    return extension.endsWith('.png') ||
        extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg') ||
        extension.endsWith('.gif') ||
        extension.endsWith('.bmp') ||
        extension.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _chargement
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        labelText: "Titre",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Titre requis" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Description requise" : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _choisirFichier,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_nomFichier ?? "Joindre un fichier"),
                    ),
                    if (_fichierBytes != null && _nomFichier != null) ...[
                      const SizedBox(height: 16),
                      Text("Aperçu du fichier :",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _estImage(_nomFichier!)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _fichierBytes!,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              height: 60,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _nomFichier!,
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _soumettreAnnonce,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Publier l'annonce"),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.list_alt),
        tooltip: "Voir la liste des annonces",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListeAnnoncesPage(etablissementId: widget.etablissementId),
            ),
          );
        },
      ),
    );
  }
}

// Exemple minimal d'une page ListeAnnoncesPage (à adapter selon ton code)

