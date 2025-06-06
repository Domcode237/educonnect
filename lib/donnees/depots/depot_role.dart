import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/role_modele.dart';

class DepotRole {
  final _db = FirebaseFirestore.instance;

  // Récupérer tous les rôles
  Future<List<RoleModele>> getTousLesRoles() async {
    final snapshot = await _db.collection('roles').get();
    return snapshot.docs.map((doc) => RoleModele.fromMap(doc.data(), doc.id)).toList();
  }

  // Récupérer un rôle par ID
  Future<RoleModele?> getRoleParId(String id) async {
    final doc = await _db.collection('roles').doc(id).get();
    if (doc.exists) {
      return RoleModele.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
  // Modifier un rôle existant par ID
  Future<void> modifierRole(String id, String nom, String description) async {
    try {
      await _db.collection('roles').doc(id).update({
        'nom': nom,
        'description': description,
      });
    } catch (e) {
      throw Exception("Erreur lors de la modification du rôle : $e");
    }
  }

  // Ajouter un nouveau rôle
  Future<void> ajouterRole(String nom, String description) async {
    await _db.collection('roles').add({
      'nom': nom,
      'description': description,
    });
  }
}
