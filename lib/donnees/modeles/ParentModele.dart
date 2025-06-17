import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class ParentModele {
  final String id; // nouvel id pour Parent
  final UtilisateurModele utilisateur;
  final List<String> enfants; // Liste des IDs des élèves

  ParentModele({
    required this.id,
    required this.utilisateur,
    required this.enfants,
  });

  factory ParentModele.fromMap(Map<String, dynamic> map, String id) {
    return ParentModele(
      id: id,
      utilisateur: UtilisateurModele.fromMap(map, id), // si UtilisateurModele utilise le même id, sinon adapte
      enfants: List<String>.from(map['enfants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...utilisateur.toMap(),
      'enfants': enfants,
      // 'id': id, // généralement l'id n’est pas dans les données Firestore, donc tu peux commenter ou supprimer
    };
  }
}
