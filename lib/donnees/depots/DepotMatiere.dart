import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/MatiereModele.dart';

class DepotMatiere {
  final _db = FirebaseFirestore.instance;

  Future<void> ajouterMatiere(MatiereModele matiere) async {
    await _db.collection('matieres').doc(matiere.id).set(matiere.toMap());
  }

  Future<void> modifierMatiere(String id, MatiereModele matiere) async {
    await _db.collection('matieres').doc(id).update(matiere.toMap());
  }

  Future<void> supprimerMatiere(String id) async {
    await _db.collection('matieres').doc(id).delete();
  }

  Future<List<MatiereModele>> getToutesLesMatieres() async {
    final snapshot = await _db.collection('matieres').get();
    return snapshot.docs.map((doc) => MatiereModele.fromMap(doc.data(), doc.id)).toList();
  }

  Future<MatiereModele?> getMatiereParId(String id) async {
    final doc = await _db.collection('matieres').doc(id).get();
    if (doc.exists) {
      return MatiereModele.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<List<MatiereModele>> getMatieresParEnseignant(String enseignantId) async {
    final snapshot = await _db
        .collection('matieres')
        .where('enseignantId', isEqualTo: enseignantId)
        .get();
    return snapshot.docs.map((doc) => MatiereModele.fromMap(doc.data(), doc.id)).toList();
  }
}
