import 'package:appwrite/appwrite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../main.dart'; // pour appwriteClient

class ProfilUtilisateurPage extends StatefulWidget {
  final String utilisateurId;

  const ProfilUtilisateurPage({super.key, required this.utilisateurId});

  @override
  State<ProfilUtilisateurPage> createState() => _ProfilUtilisateurPageState();
}

class _ProfilUtilisateurPageState extends State<ProfilUtilisateurPage> {
  Map<String, dynamic>? utilisateurData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerInfos();
  }

  Future<void> _chargerInfos() async {
    
      final doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(widget.utilisateurId)
          .get();

      if (doc.exists) {
        setState(() {
          utilisateurData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
   
  }

  void _modifierInformations() {
    if (utilisateurData == null) return;
    final nomController = TextEditingController(text: utilisateurData!['nom']);
    final prenomController = TextEditingController(text: utilisateurData!['prenom']);
    final emailController = TextEditingController(text: utilisateurData!['email']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Modifier les informations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: prenomController, decoration: const InputDecoration(labelText: 'Prénom')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('utilisateurs')
                    .doc(widget.utilisateurId)
                    .update({
                  'nom': nomController.text.trim(),
                  'prenom': prenomController.text.trim(),
                  'email': emailController.text.trim(),
                });
                Navigator.pop(context);
                _chargerInfos();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _modifierMotDePasse() {
    final mdpController = TextEditingController();
    final mdpConfirm = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Modifier le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mdpController,
                decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                obscureText: true,
              ),
              TextField(
                controller: mdpConfirm,
                decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (mdpController.text != mdpConfirm.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Les mots de passe ne correspondent pas")));
                  return;
                }

                try {
                  final account = Account(appwriteClient);
                  await account.updatePassword(password: mdpController.text.trim());

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Mot de passe mis à jour avec succès")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _modifierPhotoProfil() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final filename = picked.name;

    final storage = Storage(appwriteClient);

   
    // Supprimer ancienne photo si existe
    final ancienFichierId = utilisateurData?['photoFileId'];
    if (ancienFichierId != null && ancienFichierId != '') {
      await storage.deleteFile(bucketId: '6854df330032c7be516c', fileId: ancienFichierId);
    }

    final newFile = await storage.createFile(
      bucketId: '6854df330032c7be516c',
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: bytes, filename: filename),
    );

    await FirebaseFirestore.instance.collection('utilisateurs').doc(widget.utilisateurId).update({
      'photoFileId': newFile.$id,
    });

    _chargerInfos();
   
  }

  String? _getPhotoUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = _getPhotoUrl(utilisateurData?['photoFileId']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
        backgroundColor: const Color.fromARGB(255, 19, 51, 76),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : utilisateurData == null
              ? const Center(child: Text('Utilisateur introuvable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _modifierPhotoProfil,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null ? const Icon(Icons.person, size: 60) : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${utilisateurData!['prenom']} ${utilisateurData!['nom']}',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        utilisateurData!['email'] ?? '',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Divider(height: 32),
                      ListTile(
                        title: const Text('Nom'),
                        subtitle: Text(utilisateurData!['nom'] ?? ''),
                      ),
                      ListTile(
                        title: const Text('Prénom'),
                        subtitle: Text(utilisateurData!['prenom'] ?? ''),
                      ),
                      ListTile(
                        title: const Text('Email'),
                        subtitle: Text(utilisateurData!['email'] ?? ''),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _modifierInformations,
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier les informations'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _modifierMotDePasse,
                        icon: const Icon(Icons.lock),
                        label: const Text('Changer le mot de passe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
