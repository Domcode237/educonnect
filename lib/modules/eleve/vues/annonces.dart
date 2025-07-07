import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../main.dart'; // Pour appwriteClient

class AnnonceModele {
  final String id;
  final String etablissementId;
  final String titre;
  final String description;
  final String? fichierId;
  final List<String> utilisateursConcernees;
  final List<String> luePar;
  final Timestamp dateCreation;

  AnnonceModele({
    required this.id,
    required this.etablissementId,
    required this.titre,
    required this.description,
    this.fichierId,
    required this.utilisateursConcernees,
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
      utilisateursConcernees: List<String>.from(data['utilisateursConcernees'] ?? []),
      luePar: List<String>.from(data['luePar'] ?? []),
      dateCreation: data['dateCreation'] ?? Timestamp.now(),
    );
  }
}

class ListeAnnoncesElevePage extends StatefulWidget {
  final String utilisateurId;
  final String etablissementId;

  const ListeAnnoncesElevePage({
    Key? key,
    required this.utilisateurId,
    required this.etablissementId,
  }) : super(key: key);

  @override
  State<ListeAnnoncesElevePage> createState() => _ListeAnnoncesElevePageState();
}

class _ListeAnnoncesElevePageState extends State<ListeAnnoncesElevePage> {
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
          .where('utilisateursConcernees', arrayContains: widget.utilisateurId)
          .orderBy('dateCreation', descending: true)
          .get();

      annonces = querySnap.docs
          .map((doc) => AnnonceModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        error = e.message;
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
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
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
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 1))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _marquerCommeLue(String annonceId) async {
    final docRef = FirebaseFirestore.instance.collection('annonces').doc(annonceId);
    try {
      await docRef.update({
        'luePar': FieldValue.arrayUnion([widget.utilisateurId]),
      });

      if (mounted) {
        setState(() {
          annonces = annonces.map((annonce) {
            if (annonce.id == annonceId) {
              return AnnonceModele(
                id: annonce.id,
                etablissementId: annonce.etablissementId,
                titre: annonce.titre,
                description: annonce.description,
                fichierId: annonce.fichierId,
                utilisateursConcernees: annonce.utilisateursConcernees,
                luePar: List<String>.from(annonce.luePar)..add(widget.utilisateurId),
                dateCreation: annonce.dateCreation,
              );
            }
            return annonce;
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text('Erreur : $error'))
                  : annonces.isEmpty
                      ? const Center(child: Text("Aucune annonce disponible"))
                      : ListView.builder(
                          itemCount: annonces.length,
                          itemBuilder: (context, index) {
                            final annonce = annonces[index];
                            final dateFormat =
                                DateFormat('dd MMM yyyy - HH:mm').format(annonce.dateCreation.toDate());
                            final imageUrl = _getAppwriteImageUrl(annonce.fichierId);
                            final estLue = annonce.luePar.contains(widget.utilisateurId);

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFDFD),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          annonce.titre,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (estLue) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    annonce.description,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 10),
                                  if (imageUrl != null)
                                    GestureDetector(
                                      onTap: () => _afficherImagePleine(context, imageUrl, annonce.titre),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.insert_drive_file, size: 20, color: Colors.grey),
                                                  SizedBox(width: 8),
                                                  Text("Fichier non affichable", style: TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Publié le $dateFormat",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  if (!estLue)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _marquerCommeLue(annonce.id),
                                        child: const Text("Marquer comme lue"),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
