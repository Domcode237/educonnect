import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/appel_model.dart';

class DeposAppel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('appels');

  /// Créer un nouvel appel
  Future<void> creerAppel(AppelModele appel) async {
    try {
      await _collection.add(appel.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Lire un appel par son ID
  Future<AppelModele?> getAppelParId(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return AppelModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtenir tous les appels d'une classe
  Future<List<AppelModele>> getAppelsParClasse(String classeId) async {
    try {
      final snapshot = await _collection
          .where('classeId', isEqualTo: classeId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AppelModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtenir tous les appels d’un enseignant
  Future<List<AppelModele>> getAppelsParEnseignant(String enseignantId) async {
    try {
      final snapshot = await _collection
          .where('enseignantId', isEqualTo: enseignantId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AppelModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Obtenir les absences d’un élève
  Future<List<AppelModele>> getAbsencesParEleve(String eleveId) async {
    try {
      final snapshot = await _collection
          .where('elevesAbsents', arrayContains: eleveId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return AppelModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer un appel
  Future<void> supprimerAppel(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }
}
