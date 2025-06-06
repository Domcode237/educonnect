import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class ParentModele {
  final UtilisateurModele utilisateur;
  final List<String> enfants; // ID des enfants (élèves)

  ParentModele({
    required this.utilisateur,
    required this.enfants,
  });

  factory ParentModele.fromMap(Map<String, dynamic> map, String id) {
    return ParentModele(
      utilisateur: UtilisateurModele.fromMap(map, id),
      enfants: List<String>.from(map['enfants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...utilisateur.toMap(),
      'enfants': enfants,
    };
  }
}
