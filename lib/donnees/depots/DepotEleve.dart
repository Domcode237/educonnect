import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';

class DepotEleve {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('eleves');

  /// Ajouter un nouvel élève dans Firestore.
  Future<void> ajouterEleve(EleveModele eleve) async {
    try {
      await _collection.doc(eleve.id).set(eleve.toMap());
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de l'élève : $e");
    }
  }

  /// Modifier un élève existant dans Firestore.
  Future<void> modifierEleve(String id, EleveModele eleve) async {
    try {
      await _collection.doc(id).update(eleve.toMap());
    } catch (e) {
      throw Exception("Erreur lors de la modification de l'élève : $e");
    }
  }

  /// Supprimer un élève de Firestore.
  Future<void> supprimerEleve(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'élève : $e");
    }
  }

  /// Rechercher un élève par son ID.
  Future<EleveModele?> rechercherEleveParId(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return EleveModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception("Erreur lors de la recherche de l'élève : $e");
    }
  }

  /// Rechercher tous les élèves d'une classe spécifique.
  Future<List<EleveModele>> rechercherElevesParClasse(String classeId) async {
    try {
      final querySnapshot = await _collection
          .where('classeId', isEqualTo: classeId)
          .get();
      return querySnapshot.docs
          .map((doc) =>
              EleveModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception("Erreur lors de la recherche des élèves : $e");
    }
  }

  /// Récupérer tous les élèves.
  Future<List<EleveModele>> recupererTousLesEleves() async {
    try {
      final querySnapshot = await _collection.get();
      return querySnapshot.docs
          .map((doc) =>
              EleveModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception("Erreur lors de la récupération des élèves : $e");
    }
  }
}