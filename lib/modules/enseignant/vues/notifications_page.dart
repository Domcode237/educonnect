import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../main.dart'; // Pour appwriteClient

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

class ListeAnnoncesEnseignantPage extends StatefulWidget {
  final String enseignantId;
  final String etablissementId;

  const ListeAnnoncesEnseignantPage({
    Key? key,
    required this.enseignantId,
    required this.etablissementId,
  }) : super(key: key);

  @override
  State<ListeAnnoncesEnseignantPage> createState() => _ListeAnnoncesEnseignantPageState();
}

class _ListeAnnoncesEnseignantPageState extends State<ListeAnnoncesEnseignantPage> {
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
          .where('utilisateursConcernees', arrayContains: widget.enseignantId)
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

      // Si erreur liée à l'index manquant, Firestore fournit un lien dans e.message
      if (e.message != null && e.message!.contains('https://console.firebase.google.com')) {
        final regex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
        final match = regex.firstMatch(e.message!);
        if (match != null) {
          print('Lien pour créer l\'index Firestore recommandé : ${match.group(0)}');
        }
      }
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
        'luePar': FieldValue.arrayUnion([widget.enseignantId]),
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
                utilisateursConcernes: annonce.utilisateursConcernes,
                luePar: List<String>.from(annonce.luePar)..add(widget.enseignantId),
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
    final dateFormat = DateFormat('dd MMM yyyy - HH:mm').format(annonce.dateCreation.toDate());
    final imageUrl = _getAppwriteImageUrl(annonce.fichierId);
    final estLue = annonce.luePar.contains(widget.enseignantId);

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
          // Titre & "Lue"
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
              if (estLue)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            annonce.description,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 10),

          // Image (si présente)
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
          // Date
          Text(
            "Publié le $dateFormat",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          // Bouton "marquer comme lue"
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
)

        ),
      ),
    );
  }
}
