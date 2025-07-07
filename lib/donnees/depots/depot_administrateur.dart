import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/AdministrateurModele.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_utilisateur.dart';

/// Dépôt permettant d'accéder aux administrateurs dans Firestore.
/// La collection "administrateurs" contient uniquement le champ "utilisateurId".
class DepotAdministrateur {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DepotUtilisateur _depotUtilisateur = DepotUtilisateur();

  static const String _collection = 'administrateurs';
  static const String _rolesCollection = 'roles';

  /// Ajouter un administrateur en utilisant le modèle `AdministrateurModele`.
  ///
  /// Cette méthode :
  /// - Récupère le rôle "administrateur" dans la collection `roles`
  /// - Met à jour l’utilisateur pour lui assigner ce rôle
  /// - Ajoute le document dans la collection `administrateurs`.
  Future<void> ajouterAdministrateur(AdministrateurModele admin) async {
    // Récupérer le rôle "administrateur"
    final roleSnapshot = await _firestore
        .collection(_rolesCollection)
        .where('nom', isEqualTo: 'administrateur')
        .limit(1)
        .get();

    if (roleSnapshot.docs.isEmpty) {
      throw Exception('Le rôle "administrateur" est introuvable dans Firestore.');
    }


    // Récupère les détails de l’utilisateur à mettre à jour
    final utilisateur = await _depotUtilisateur.getUtilisateurParId(admin.utilisateurId);
    if (utilisateur == null) {
      throw Exception('Utilisateur introuvable.');
    }
    // Ajoute le document dans la collection "administrateurs"
    await _firestore.collection(_collection).doc(admin.id).set(admin.toMap());
  }

  /// Modifier les détails d’un administrateur.
  Future<void> modifierAdministrateur(AdministrateurModele admin) async {
    await _firestore.collection(_collection).doc(admin.id).update(admin.toMap());
  }

  /// Supprimer un administrateur par son ID de document.
  Future<void> supprimerAdministrateur(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Récupérer tous les administrateurs sous forme d'objets `UtilisateurModele`.
  Future<List<UtilisateurModele>> getTousLesAdministrateurs() async {
    final snapshot = await _firestore.collection(_collection).get();

    final administrateurs = <UtilisateurModele>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final admin = AdministrateurModele.fromMap(data, doc.id);

      final utilisateur = await _depotUtilisateur.getUtilisateurParId(admin.utilisateurId);
      if (utilisateur != null) {
        administrateurs.add(utilisateur);
      }
    }
    return administrateurs;
  }

  /// Récupérer les détails d’un administrateur par son ID de document.
  Future<UtilisateurModele?> getAdministrateurParId(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;

    final admin = AdministrateurModele.fromMap(doc.data()!, doc.id);
    return await _depotUtilisateur.getUtilisateurParId(admin.utilisateurId);
  }
}
