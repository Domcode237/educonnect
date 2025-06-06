import 'package:educonnect/donnees/modeles/MatiereModele.dart';

class NoteModele {
  final double valeur;
  final String type;
  final String mention;
  final String eleveId;
  final MatiereModele matiere;

  NoteModele({
    required this.valeur,
    required this.type,
    required this.mention,
    required this.eleveId,
    required this.matiere,
  });

  factory NoteModele.fromMap(Map<String, dynamic> map) {
    return NoteModele(
      valeur: map['valeur']?.toDouble() ?? 0.0,
      type: map['type'] ?? '',
      mention: map['mention'] ?? '',
      eleveId: map['eleveId'] ?? '',
      matiere: MatiereModele.fromMap(map['matiere']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'valeur': valeur,
      'type': type,
      'mention': mention,
      'eleveId': eleveId,
      'matiere': matiere.toMap(),
    };
  }
}
