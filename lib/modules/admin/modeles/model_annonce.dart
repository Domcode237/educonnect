import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'etablissementId': etablissementId,
      'titre': titre,
      'description': description,
      'fichierId': fichierId,
      'utilisateursConcernes': utilisateursConcernes,
      'luePar': luePar,
      'dateCreation': dateCreation,
    };
  }
}
