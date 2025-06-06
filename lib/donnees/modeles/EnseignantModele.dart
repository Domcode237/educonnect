import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class EnseignantModele {
  final UtilisateurModele utilisateur;
  final List<String> matieres; // ID des matières
  final List<String> classes;  // ID des classes

  EnseignantModele({
    required this.utilisateur,
    required this.matieres,
    required this.classes,
  });

  factory EnseignantModele.fromMap(Map<String, dynamic> map, String id) {
    return EnseignantModele(
      utilisateur: UtilisateurModele.fromMap(map, id),
      matieres: List<String>.from(map['matieres'] ?? []),
      classes: List<String>.from(map['classes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...utilisateur.toMap(),
      'matieres': matieres,
      'classes': classes,
    };
  }
}
