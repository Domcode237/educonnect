import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../main.dart'; // Pour appwriteClient
import 'creer_annonce_page.dart';

class AnnonceModele {
  final String id;
  final String etablissementId;
  final String titre;
  final String description;
  final String? fichierId; // Champ facultatif
  final List<String> utilisateursConcernes;
  final List<String> luePar;
  final Timestamp dateCreation;

  AnnonceModele({
    required this.id,
    required this.etablissementId,
    required this.titre,
    required this.description,
    this.fichierId,
    required this.utilisateursConcernes,
    required this.luePar,
    required this.dateCreation,
  });

  factory AnnonceModele.fromMap(Map<String, dynamic> data, String id) {
    return AnnonceModele(
      id: id,
      etablissementId: data['etablissementId'] ?? '',
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      fichierId: data['fichierId'],
      utilisateursConcernes: List<String>.from(data['utilisateursConcernes'] ?? []),
      luePar: List<String>.from(data['luePar'] ?? []),
      dateCreation: data['dateCreation'] ?? Timestamp.now(),
    );
  }
}

class ListeAnnoncesPage extends StatefulWidget {
  final String etablissementId;

  const ListeAnnoncesPage({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<ListeAnnoncesPage> createState() => _ListeAnnoncesPageState();
}

class _ListeAnnoncesPageState extends State<ListeAnnoncesPage> {
  bool isLoading = true;
  String? error;
  List<AnnonceModele> annonces = [];

  @override
  void initState() {
    super.initState();
    _chargerAnnonces();
  }

  Future<void> _chargerAnnonces() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final querySnap = await FirebaseFirestore.instance
          .collection('annonces')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .orderBy('dateCreation', descending: true)
          .get();

      annonces = querySnap.docs
          .map((doc) => AnnonceModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('=== Annonces chargées: ${annonces.length} ===');
      for (var i = 0; i < annonces.length; i++) {
        print('Annonce #$i: ${annonces[i].titre} - fichierId: ${annonces[i].fichierId}');
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    final url =
        '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
    print('Construction URL image Appwrite: $url');
    return url;
  }

  void _afficherImagePleine(BuildContext context, String imageUrl, String titre) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Text(
                titre,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [
                  Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 1))
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des annonces"),
        backgroundColor: const Color.fromARGB(255, 19, 51, 76),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text('Erreur : $error'))
                  : annonces.isEmpty
                      ? const Center(child: Text("Aucune annonce trouvée"))
                      : ListView.builder(
                          itemCount: annonces.length,
                          itemBuilder: (context, index) {
                            final annonce = annonces[index];
                            final dateFormat = DateFormat('dd MMM yyyy - HH:mm').format(annonce.dateCreation.toDate());
                            final imageUrl = _getAppwriteImageUrl(annonce.fichierId);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      annonce.titre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color.fromARGB(255, 19, 51, 76),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(annonce.description),
                                    const SizedBox(height: 12),
                                    if (imageUrl != null)
                                      GestureDetector(
                                        onTap: () => _afficherImagePleine(context, imageUrl, annonce.titre),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            imageUrl,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              print('Erreur chargement image Appwrite: $error');
                                              return Row(
                                                children: const [
                                                  Icon(Icons.insert_drive_file, color: Colors.grey),
                                                  SizedBox(width: 8),
                                                  Text("Fichier non affichable"),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Publié le $dateFormat",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 19, 51, 76),
        tooltip: "Créer une annonce",
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreerAnnoncePage(etablissementId: widget.etablissementId),
            ),
          );
          await _chargerAnnonces();
        },
      ),
    );
  }
}
