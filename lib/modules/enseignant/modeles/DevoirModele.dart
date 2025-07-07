import 'package:cloud_firestore/cloud_firestore.dart';

class DevoirModele {
  final String id;
  final String titre;
  final String description;
  final String etablissementId;      // ✅ Établissement d’origine du devoir
  final String classeId;
  final String matiereId;
  final String enseignantId;         // Émetteur
  final List<String> eleveIds;       // Récepteurs directs
  final List<String> parentIds;      // Récepteurs indirects
  final List<String> lusPar;         // ✅ Utilisateurs ayant lu le devoir
  final DateTime dateRemise;
  final String? fichierUrl;
  final String? fichierType;
  final DateTime dateCreation;

  DevoirModele({
    required this.id,
    required this.titre,
    required this.description,
    required this.etablissementId,
    required this.classeId,
    required this.matiereId,
    required this.enseignantId,
    required this.eleveIds,
    required this.parentIds,
    required this.lusPar,
    required this.dateRemise,
    required this.fichierUrl,
    required this.fichierType,
    required this.dateCreation,
  });

  factory DevoirModele.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DevoirModele(
      id: doc.id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      etablissementId: data['etablissementId'] ?? '',
      classeId: data['classeId'] ?? '',
      matiereId: data['matiereId'] ?? '',
      enseignantId: data['enseignantId'] ?? '',
      eleveIds: List<String>.from(data['eleveIds'] ?? []),
      parentIds: List<String>.from(data['parentIds'] ?? []),
      lusPar: List<String>.from(data['lusPar'] ?? []),
      dateRemise: (data['dateRemise'] as Timestamp).toDate(),
      fichierUrl: data['fichierUrl'],
      fichierType: data['fichierType'],
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'etablissementId': etablissementId,
      'classeId': classeId,
      'matiereId': matiereId,
      'enseignantId': enseignantId,
      'eleveIds': eleveIds,
      'parentIds': parentIds,
      'lusPar': lusPar,
      'dateRemise': Timestamp.fromDate(dateRemise),
      'fichierUrl': fichierUrl,
      'fichierType': fichierType,
      'dateCreation': Timestamp.fromDate(dateCreation),
    };
  }
}
