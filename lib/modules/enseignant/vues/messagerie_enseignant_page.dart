import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'page_message_detail.dart';
import 'package:educonnect/main.dart'; // appwriteClient global

class MessagerieEnseignantPage extends StatefulWidget {
  final String utilisateurId; // id utilisateur enseignant
  final String etablissementId;

  const MessagerieEnseignantPage({
    Key? key,
    required this.utilisateurId,
    required this.etablissementId,
  }) : super(key: key);

  @override
  State<MessagerieEnseignantPage> createState() => _MessagerieEnseignantPageState();
}

class _MessagerieEnseignantPageState extends State<MessagerieEnseignantPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, UtilisateurModele> utilisateursMap = {};
  List<ParentModele> parents = [];
  Map<String, int> nbMessagesNonLusParParent = {};
  bool isLoading = true;
  String? error;
  int _nbMessagesNonLus = 0;

  String? enseignantDocId; // ID du document enseignant lié à utilisateurId

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    await _chargerEnseignantDocId();
    await _chargerDonnees();
    await _chargerNbMessagesNonLus();
  }

  Future<void> _chargerEnseignantDocId() async {
    try {
      final query = await _firestore
          .collection('enseignants')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        enseignantDocId = query.docs.first.id;
      } else {
        print("Aucun document enseignant trouvé pour utilisateurId=${widget.utilisateurId}");
      }
    } catch (e) {
      print("Erreur récupération ID enseignant: $e");
    }
  }

  Future<void> _chargerDonnees() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // 1. Charger tous les parents
      final parentsSnapshot = await _firestore.collection('parents').get();
      parents = parentsSnapshot.docs
          .map((doc) => ParentModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final utilisateurIds = parents.map((p) => p.utilisateurId).toSet().toList();

      if (utilisateurIds.isEmpty) {
        setState(() {
          utilisateursMap = {};
          nbMessagesNonLusParParent = {};
          parents = [];
          isLoading = false;
        });
        return;
      }

      // 2. Charger tous les utilisateurs liés, filtrés par établissement
      final utilisateursSnapshot = await _firestore
          .collection('utilisateurs')
          .where(FieldPath.documentId, whereIn: utilisateurIds)
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      utilisateursMap = {
        for (var doc in utilisateursSnapshot.docs)
          doc.id: UtilisateurModele.fromMap(doc.data(), doc.id)
      };

      // 3. Charger toutes les notifications non lues envoyées par ces parents à cet enseignant (ID enseignantDocId)
      if (enseignantDocId == null) {
        print("enseignantDocId est null, impossible de charger les notifications");
        setState(() {
          isLoading = false;
          error = "Impossible de récupérer l'ID enseignant.";
        });
        return;
      }

      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('type', isEqualTo: 'message')
          .where('lu', isEqualTo: false)
          .where('recepteurId', isEqualTo: enseignantDocId)
          .where('expediteurId', whereIn: utilisateurIds)
          .get();

      // 4. Compter les messages non lus par parent
      nbMessagesNonLusParParent = {};
      for (var parent in parents) {
        final utilisateurId = parent.utilisateurId;
        final count = notificationsSnapshot.docs
            .where((doc) => doc['expediteurId'] == utilisateurId)
            .length;
        nbMessagesNonLusParParent[parent.id] = count;
      }

      // 5. Filtrer parents qui ont un utilisateur valide dans l'établissement
      parents = parents.where((p) => utilisateursMap.containsKey(p.utilisateurId)).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Erreur : $e");
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _chargerNbMessagesNonLus() async {
    try {
      if (enseignantDocId == null) return;
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('recepteurId', isEqualTo: enseignantDocId)
          .where('lu', isEqualTo: false)
          .where('type', isEqualTo: 'message')
          .get();

      setState(() {
        _nbMessagesNonLus = querySnapshot.size;
      });
    } catch (_) {}
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erreur : $error'))
              : parents.isEmpty
                  ? const Center(child: Text('Aucun parent trouvé.'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _chargerDonnees();
                        await _chargerNbMessagesNonLus();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        itemCount: parents.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (context, index) {
                          final parent = parents[index];
                          final utilisateur = utilisateursMap[parent.utilisateurId];
                          if (utilisateur == null) {
                            return const ListTile(title: Text('Utilisateur non trouvé'));
                          }

                          final photoUrl = _getAppwriteImageUrl(utilisateur.photo);
                          final statutColor = utilisateur.statut ? Colors.green : Colors.grey;
                          final nbNonLus = nbMessagesNonLusParParent[parent.id] ?? 0;

                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PageMessageDetail(
                                    enseignantId: enseignantDocId!,  // On passe l'id enseignant ici
                                    parentId: parent.utilisateurId,  // ici on passe utilisateurId du parent
                                    parentNom: '${utilisateur.prenom} ${utilisateur.nom}',
                                    parentPhotoFileId: utilisateur.photo,
                                  ),
                                ),
                              );
                            },
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null
                                      ? const Icon(Icons.person, size: 28, color: Colors.blueAccent)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statutColor,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              '${utilisateur.prenom} ${utilisateur.nom}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              utilisateur.statut ? 'en ligne' : 'hors ligne',
                            ),
                            trailing: nbNonLus > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      '$nbNonLus',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  )
                                : const Icon(Icons.chat_bubble_outline),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.grey.shade100,
        child: Row(
          children: [
            const Icon(Icons.sms, size: 24),
            const SizedBox(width: 8),
            Text(
              'Messages non lus : $_nbMessagesNonLus',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
