import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/EtablissementModele.dart';

class DepotEtablissement {
  final _db = FirebaseFirestore.instance;

  // Ajouter un établissement
  Future<void> ajouterEtablissement(EtablissementModele etab) async {
    await _db.collection('etablissements').add(etab.toMap());
  }

  // Modifier un établissement
  Future<void> modifierEtablissement(String id, EtablissementModele etab) async {
    await _db.collection('etablissements').doc(id).update(etab.toMap());
  }

  // Supprimer un établissement
  Future<void> supprimerEtablissement(String id) async {
    await _db.collection('etablissements').doc(id).delete();
  }

  // Obtenir tous les établissements
  Future<List<EtablissementModele>> getTousLesEtablissements() async {
    final snapshot = await _db.collection('etablissements').get();
    return snapshot.docs.map((doc) => EtablissementModele.fromMap(doc.data(), doc.id)).toList();
  }

  // Obtenir un établissement par ID
  Future<EtablissementModele?> getEtablissementParId(String id) async {
    final doc = await _db.collection('etablissements').doc(id).get();
    if (doc.exists) {
      return EtablissementModele.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
