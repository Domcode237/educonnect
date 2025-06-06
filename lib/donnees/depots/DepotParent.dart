import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';

class DepotParent {
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();
  final String _role = 'parent';

  Future<void> ajouterParent(UtilisateurModele parent) async {
    assert(parent.roleId == _role, 'Le rôle doit être "parent"');
    await _depotUtilisateur.ajouterUtilisateur(parent);
  }

  Future<void> modifierParent(String id, UtilisateurModele parent) async {
    assert(parent.roleId == _role, 'Le rôle doit être "parent"');
    await _depotUtilisateur.modifierUtilisateur(id, parent);
  }

  Future<void> supprimerParent(String id) async {
    await _depotUtilisateur.supprimerUtilisateur(id);
  }

  Future<List<UtilisateurModele>> getTousLesParents() async {
    final tous = await _depotUtilisateur.getTousLesUtilisateurs();
    return tous.where((u) => u.roleId == _role).toList();
  }

  Future<UtilisateurModele?> getParentParId(String id) async {
    final u = await _depotUtilisateur.getUtilisateurParId(id);
    return (u != null && u.roleId == _role) ? u : null;
  }
}
