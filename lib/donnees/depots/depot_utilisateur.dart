import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class DepotUtilisateur {
  final _db = FirebaseFirestore.instance;

  // ✅ Ajouter un utilisateur
  Future<void> ajouterUtilisateur(UtilisateurModele utilisateur) async {
    await _db.collection('utilisateurs').doc(utilisateur.id).set(utilisateur.toMap());
  }

  // 🔁 Modifier un utilisateur
  Future<void> modifierUtilisateur(String id, UtilisateurModele utilisateur) async {
    await _db.collection('utilisateurs').doc(id).update(utilisateur.toMap());
  }

  // ❌ Supprimer un utilisateur
  Future<void> supprimerUtilisateur(String id) async {
    await _db.collection('utilisateurs').doc(id).delete();
  }

  // 📋 Obtenir tous les utilisateurs
  Future<List<UtilisateurModele>> getTousLesUtilisateurs() async {
    final snapshot = await _db.collection('utilisateurs').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UtilisateurModele.fromMap(data, doc.id);
    }).toList();
  }

  // 🔎 Obtenir un utilisateur par ID
  Future<UtilisateurModele?> getUtilisateurParId(String id) async {
    final doc = await _db.collection('utilisateurs').doc(id).get();

    if (doc.exists && doc.data() != null) {
      return UtilisateurModele.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // 🔎 Obtenir les utilisateurs d’un établissement
  Future<List<UtilisateurModele>> getUtilisateursParEtablissement(String etabId) async {
    final snapshot = await _db
        .collection('utilisateurs')
        .where('etablissementId', isEqualTo: etabId)
        .get();

    return snapshot.docs.map((doc) => UtilisateurModele.fromMap(doc.data(), doc.id)).toList();
  }
}
