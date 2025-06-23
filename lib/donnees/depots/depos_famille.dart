import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/famille_modele.dart';

class DepotFamille {
  final CollectionReference _familleCollection =
      FirebaseFirestore.instance.collection('famille');

  /// Ajoute une nouvelle relation parent-enfant
  Future<String> ajouterRelation(String parentId, String eleveId) async {
    try {
      // On vérifie si la relation existe déjà
      final querySnapshot = await _familleCollection
          .where('parentId', isEqualTo: parentId)
          .where('eleveId', isEqualTo: eleveId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Relation déjà existante, retourne l'id existant
        return querySnapshot.docs.first.id;
      }

      final docRef = await _familleCollection.add({
        'parentId': parentId,
        'eleveId': eleveId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de la relation famille : $e");
    }
  }

  /// Supprime une relation parent-enfant par ID
  Future<void> supprimerRelation(String relationId) async {
    try {
      await _familleCollection.doc(relationId).delete();
    } catch (e) {
      throw Exception("Erreur lors de la suppression de la relation famille : $e");
    }
  }

  /// Liste toutes les relations d'un parent
  Stream<List<FamilleModele>> getRelationsParParent(String parentId) {
    return _familleCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilleModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
