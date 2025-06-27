import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/model_enseignement.dart';

class EnseignementDepot {
  final _collection = FirebaseFirestore.instance.collection('enseignements');

  /// Créer un enseignement
  Future<void> ajouterEnseignement(String enseignantId, String matiereId) async {
    await _collection.add({
      'enseignantId': enseignantId,
      'matiereId': matiereId,
    });
  }

  /// Supprimer un enseignement
  Future<void> supprimerEnseignement(String enseignementId) async {
    await _collection.doc(enseignementId).delete();
  }

  /// Lister les matières d’un enseignant
  Future<List<EnseignementModele>> getEnseignementsPourEnseignant(String enseignantId) async {
    final snap = await _collection.where('enseignantId', isEqualTo: enseignantId).get();
    return snap.docs.map((doc) => EnseignementModele.fromMap(doc.data(), doc.id)).toList();
  }

  /// Lister les enseignants d’une matière
  Future<List<EnseignementModele>> getEnseignementsPourMatiere(String matiereId) async {
    final snap = await _collection.where('matiereId', isEqualTo: matiereId).get();
    return snap.docs.map((doc) => EnseignementModele.fromMap(doc.data(), doc.id)).toList();
  }
}
