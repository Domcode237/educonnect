import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';

class DepotEleve {
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();
  final String _role = 'eleve';

  Future<void> ajouterEleve(UtilisateurModele eleve) async {
    assert(eleve.roleId == _role, 'Le rôle doit être "eleve"');
    await _depotUtilisateur.ajouterUtilisateur(eleve);
  }

  Future<void> modifierEleve(String id, UtilisateurModele eleve) async {
    assert(eleve.roleId == _role, 'Le rôle doit être "eleve"');
    await _depotUtilisateur.modifierUtilisateur(id, eleve);
  }

  Future<void> supprimerEleve(String id) async {
    await _depotUtilisateur.supprimerUtilisateur(id);
  }

  Future<List<UtilisateurModele>> getTousLesEleves() async {
    final tous = await _depotUtilisateur.getTousLesUtilisateurs();
    return tous.where((u) => u.roleId == _role).toList();
  }

  Future<UtilisateurModele?> getEleveParId(String id) async {
    final u = await _depotUtilisateur.getUtilisateurParId(id);
    return (u != null && u.roleId == _role) ? u : null;
  }
}
