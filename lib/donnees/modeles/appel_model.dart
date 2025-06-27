import 'package:cloud_firestore/cloud_firestore.dart';

class AppelModele {
  final String id;
  final String classeId;
  final String etablissementId;
  final String matiereId;
  final String enseignantId;
  final List<String> elevesPresents;
  final List<String> elevesAbsents;
  final DateTime date; // Date de l'appel (pas createdAt)
  final DateTime createdAt;

  AppelModele({
    required this.id,
    required this.classeId,
    required this.etablissementId,
    required this.matiereId,
    required this.enseignantId,
    required this.elevesPresents,
    required this.elevesAbsents,
    required this.date,
    required this.createdAt,
  });

  factory AppelModele.fromMap(Map<String, dynamic> map, String id) {
    return AppelModele(
      id: id,
      classeId: map['classeId'] ?? '',
      etablissementId: map['etablissementId'] ?? '',
      matiereId: map['matiereId'] ?? '',
      enseignantId: map['enseignantId'] ?? '',
      elevesPresents: List<String>.from(map['elevesPresents'] ?? []),
      elevesAbsents: List<String>.from(map['elevesAbsents'] ?? []),
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classeId': classeId,
      'etablissementId': etablissementId,
      'matiereId': matiereId,
      'enseignantId': enseignantId,
      'elevesPresents': elevesPresents,
      'elevesAbsents': elevesAbsents,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
