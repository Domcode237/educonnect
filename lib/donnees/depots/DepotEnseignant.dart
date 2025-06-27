import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/EnseignantModele.dart';

class DepotEnseignant {
  final CollectionReference _enseignantsRef =
      FirebaseFirestore.instance.collection('enseignants');

  /// Ajouter un enseignant
  Future<void> ajouterEnseignant(EnseignantModele enseignant) async {
    await _enseignantsRef.add(enseignant.toMap());
  }
  

  /// Modifier un enseignant (si besoin)
  Future<void> modifierEnseignant(String id, EnseignantModele enseignant) async {
    await _enseignantsRef.doc(id).update(enseignant.toMap());
  }

  /// Supprimer un enseignant
  Future<void> supprimerEnseignant(String id) async {
    await _enseignantsRef.doc(id).delete();
  }

  /// Obtenir un enseignant par ID
  Future<EnseignantModele?> getEnseignant(String id) async {
    final doc = await _enseignantsRef.doc(id).get();
    if (!doc.exists) return null;
    return EnseignantModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Obtenir tous les enseignants
  Future<List<EnseignantModele>> getTousLesEnseignants() async {
    final snap = await _enseignantsRef.get();
    return snap.docs
        .map((d) => EnseignantModele.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  /// Obtenir les enseignants liés à un établissement via utilisateurId
  Future<List<EnseignantModele>> getParEtablissement(String etablissementId) async {
    final utilisateursSnap = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .where('etablissementId', isEqualTo: etablissementId)
        .get();

    final uIds = utilisateursSnap.docs.map((u) => u.id).toList();
    if (uIds.isEmpty) return [];

    // Charger en lots de 10 max
    List<EnseignantModele> enseignants = [];
    for (int i = 0; i < uIds.length; i += 10) {
      final batch = uIds.sublist(i, (i + 10 > uIds.length) ? uIds.length : i + 10);
      final snap = await _enseignantsRef.where('utilisateurId', whereIn: batch).get();
      enseignants.addAll(snap.docs.map((d) =>
          EnseignantModele.fromMap(d.data() as Map<String, dynamic>, d.id)));
    }

    return enseignants;
  }
}
