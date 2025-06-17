import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';

class DepotParent {
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // On stocke l'ID du rôle parent, par exemple "a1b2c3d4"
  final String _roleIdParent;

  // Constructeur prenant l'id du rôle parent en paramètre
  DepotParent(this._roleIdParent);

  /// Construit la map à enregistrer dans Firestore avec la liste d'IDs enfants
  Map<String, dynamic> _mapAvecEnfants(UtilisateurModele utilisateur, List<String> enfants) {
    final map = utilisateur.toMap();
    map['enfants'] = enfants;
    return map;
  }

  /// Ajoute un parent avec la liste d'IDs enfants dans Firestore (doc id = parent.id)
  Future<void> ajouterParent(ParentModele parent) async {
    assert(parent.utilisateur.roleId == _roleIdParent, 'Le rôle doit être celui du parent');
    final map = _mapAvecEnfants(parent.utilisateur, parent.enfants);
    await _db.collection('utilisateurs').doc(parent.id).set(map);
  }

  /// Modifie un parent avec la liste d'IDs enfants mise à jour
  Future<void> modifierParent(String id, ParentModele parent) async {
    assert(parent.utilisateur.roleId == _roleIdParent, 'Le rôle doit être celui du parent');
    final map = _mapAvecEnfants(parent.utilisateur, parent.enfants);
    await _db.collection('utilisateurs').doc(id).update(map);
  }

  /// Supprime un parent par son ID
  Future<void> supprimerParent(String id) async {
    await _depotUtilisateur.supprimerUtilisateur(id);
  }

  /// Récupère tous les parents, en reconstruisant ParentModele avec la liste d'IDs enfants
  Future<List<ParentModele>> getTousLesParents() async {
    final snapshot = await _db.collection('utilisateurs')
      .where('roleId', isEqualTo: _roleIdParent)
      .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final utilisateur = UtilisateurModele.fromMap(data, doc.id);
      final enfants = (data['enfants'] as List<dynamic>? ?? []).cast<String>();
      return ParentModele(
        id: doc.id,
        utilisateur: utilisateur,
        enfants: enfants,
      );
    }).toList();
  }

  /// Récupère un parent par ID avec sa liste d'IDs enfants
  Future<ParentModele?> getParentParId(String id) async {
    final doc = await _db.collection('utilisateurs').doc(id).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    if (data['roleId'] != _roleIdParent) return null;

    final utilisateur = UtilisateurModele.fromMap(data, doc.id);
    final enfants = (data['enfants'] as List<dynamic>? ?? []).cast<String>();

    return ParentModele(
      id: doc.id,
      utilisateur: utilisateur,
      enfants: enfants,
    );
  }
}
