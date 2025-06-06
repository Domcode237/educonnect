import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';

class DepotAdministrateur {
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();
  final String _role = 'administrateur';

  ///  Ajouter un administrateur
  Future<void> ajouterAdministrateur(UtilisateurModele admin) async {
    assert(admin.roleId == _role, 'Le rôle doit être "administrateur"');
    await _depotUtilisateur.ajouterUtilisateur(admin);
  }

  ///  Modifier un administrateur
  Future<void> modifierAdministrateur(String id, UtilisateurModele admin) async {
    assert(admin.roleId == _role, 'Le rôle doit être "administrateur"');
    await _depotUtilisateur.modifierUtilisateur(id, admin);
  }

  ///  Supprimer un administrateur
  Future<void> supprimerAdministrateur(String id) async {
    await _depotUtilisateur.supprimerUtilisateur(id);
  }

  ///  Obtenir tous les administrateurs
  Future<List<UtilisateurModele>> getTousLesAdministrateurs() async {
    final tous = await _depotUtilisateur.getTousLesUtilisateurs();
    return tous.where((u) => u.roleId == _role).toList();
  }

  ///  Obtenir un administrateur par ID
  Future<UtilisateurModele?> getAdministrateurParId(String id) async {
    final u = await _depotUtilisateur.getUtilisateurParId(id);
    return (u != null && u.roleId == _role) ? u : null;
  }
}
