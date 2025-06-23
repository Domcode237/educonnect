import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';

class Depotparent {
  final CollectionReference _parentCollection =
      FirebaseFirestore.instance.collection('parents');

  /// Ajoute un nouveau parent
  Future<String> ajouterParent(ParentModele parent) async {
    try {
      final docRef = await _parentCollection.add(parent.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Erreur lors de l'ajout du parent : $e");
    }
  }

  /// Récupère un parent par son ID
  Future<ParentModele?> getParentParId(String parentId) async {
    try {
      final doc = await _parentCollection.doc(parentId).get();
      if (!doc.exists) return null;
      return ParentModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception("Erreur lors de la récupération du parent : $e");
    }
  }

  /// Met à jour les données d’un parent
  Future<void> modifierParent(String parentId, Map<String, dynamic> nouvellesDonnees) async {
    try {
      await _parentCollection.doc(parentId).update(nouvellesDonnees);
    } catch (e) {
      throw Exception("Erreur lors de la modification du parent : $e");
    }
  }

  /// Supprime un parent par ID
  Future<void> supprimerParent(String parentId) async {
    try {
      await _parentCollection.doc(parentId).delete();
    } catch (e) {
      throw Exception("Erreur lors de la suppression du parent : $e");
    }
  }

  /// Liste tous les parents (en temps réel)
  Stream<List<ParentModele>> getTousLesParentsStream() {
    return _parentCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ParentModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Recherche de parents par utilisateurId
  Future<ParentModele?> getParentParUtilisateurId(String utilisateurId) async {
    try {
      final query = await _parentCollection
          .where('utilisateurId', isEqualTo: utilisateurId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      return ParentModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception("Erreur lors de la récupération du parent par utilisateurId : $e");
    }
  }
}
