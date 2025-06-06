import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';

class DepotEnseignant {
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();
  final String _role = 'enseignant';

  Future<void> ajouterEnseignant(UtilisateurModele enseignant) async {
    assert(enseignant.roleId == _role, 'Le rôle doit être "enseignant"');
    await _depotUtilisateur.ajouterUtilisateur(enseignant);
  }

  Future<void> modifierEnseignant(String id, UtilisateurModele enseignant) async {
    assert(enseignant.roleId == _role, 'Le rôle doit être "enseignant"');
    await _depotUtilisateur.modifierUtilisateur(id, enseignant);
  }

  Future<void> supprimerEnseignant(String id) async {
    await _depotUtilisateur.supprimerUtilisateur(id);
  }

  Future<List<UtilisateurModele>> getTousLesEnseignants() async {
    final tous = await _depotUtilisateur.getTousLesUtilisateurs();
    return tous.where((u) => u.roleId == _role).toList();
  }

  Future<UtilisateurModele?> getEnseignantParId(String id) async {
    final u = await _depotUtilisateur.getUtilisateurParId(id);
    return (u != null && u.roleId == _role) ? u : null;
  }
}
