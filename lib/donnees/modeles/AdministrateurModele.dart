import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class AdministrateurModele {
  final UtilisateurModele utilisateur;

  AdministrateurModele({required this.utilisateur});

  factory AdministrateurModele.fromMap(Map<String, dynamic> map, String id) {
    return AdministrateurModele(
      utilisateur: UtilisateurModele.fromMap(map, id),
    );
  }

  Map<String, dynamic> toMap() {
    return utilisateur.toMap();
  }
}
