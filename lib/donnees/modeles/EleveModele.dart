import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/NoteModele.dart';

class EleveModele {
  final UtilisateurModele utilisateur;
  final String classeId; // ID de la classe
  final List<NoteModele> notes;

  EleveModele({
    required this.utilisateur,
    required this.classeId,
    required this.notes,
  });

  factory EleveModele.fromMap(Map<String, dynamic> map, String id) {
    return EleveModele(
      utilisateur: UtilisateurModele.fromMap(map, id),
      classeId: map['classeId'] ?? '',
      notes: (map['notes'] as List<dynamic>? ?? [])
          .map((noteMap) => NoteModele.fromMap(noteMap))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...utilisateur.toMap(),
      'classeId': classeId,
      'notes': notes.map((note) => note.toMap()).toList(),
    };
  }
}
